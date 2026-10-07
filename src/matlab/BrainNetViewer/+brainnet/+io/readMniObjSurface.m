function [surface, info] = readMniObjSurface(reference, rootPath, options)
%READMNIOBJSURFACE Independent MNI/BIC polygon geometry (not Wavefront OBJ).
% Single uncompressed triangle object; source appearance is not applied.
arguments
    reference (1,1) brainnet.core.InputReference
    rootPath (1,1) string
    options.MaxVertices (1,1) double {mustBeInteger,mustBePositive,mustBeFinite} = 10000000
    options.MaxFaces (1,1) double {mustBeInteger,mustBePositive,mustBeFinite} = 20000000
    options.ByteOrder (1,1) string {mustBeMember(options.ByteOrder,["auto","little","big"])} = "auto"
end
path = brainnet.io.internal.resolveAndVerify(reference,rootPath,"surface");
file = fopen(path,'rb');
if file<0, error('BNV:IO:InputOpenFailed','Cannot open MNI/BIC object file.'); end
cleanup = onCleanup(@() fclose(file));
fseek(file,0,'eof'); total=ftell(file); fseek(file,0,'bof');
marker=fread(file,1,'*char');
if isempty(marker) || ~ismember(marker,['P','p'])
    error('BNV:IO:MniObjType','Expected a single MNI/BIC P/p polygon object, not Wavefront OBJ or another object type.');
end
binary=marker=='p';
if binary && options.ByteOrder=="auto"
    valid=0; lastError=[];
    for order=["little","big"]
        try
            [candidate,metadata]=parse(order);
        catch failure
            if ~startsWith(string(failure.identifier),"BNV:IO:"), rethrow(failure); end
            lastError=failure;
            continue;
        end
        valid=valid+1;
        if valid==1, surface=candidate; info=metadata; end
    end
    if valid==0
        error('BNV:IO:MniObjByteOrder','Neither byte order yields a valid supported MNI/BIC triangle object. Last check: %s',lastError.message);
    elseif valid>1
        error('BNV:IO:MniObjByteOrder','Ambiguous MNI/BIC byte order. Specify ByteOrder="little" or "big" explicitly.');
    end
else
    [surface,info]=parse(options.ByteOrder);
end

    function [mesh,meta]=parse(order)
        fseek(file,1,'bof');
        machine='ieee-le';
        if order=="big", machine='ieee-be'; end
        material=numbers(5,'single',machine);
        if any(~isfinite(material))
            error('BNV:IO:MniObjAppearance','MNI/BIC material values must be finite.');
        end
        nv=numbers(1,'int32',machine);
        if nv<0
            error('BNV:IO:MniObjCompressed','Compressed MNI/BIC topology is not supported.');
        end
        checkCount(nv,options.MaxVertices);
        requireBytes(6*nv,4);
        coordinates=reshape(numbers(3*nv,'single',machine),3,[]);
        normals=reshape(numbers(3*nv,'single',machine),3,[]);
        if any(~isfinite(coordinates),'all') || any(~isfinite(normals),'all')
            error('BNV:IO:NonFiniteValue','MNI/BIC coordinates and normals must be finite.');
        end
        nf=numbers(1,'int32',machine); checkCount(nf,options.MaxFaces);
        flag=numbers(1,'int32',machine);
        if ~ismember(flag,[0 1 2])
            error('BNV:IO:MniObjAppearance','MNI/BIC color flag must be 0, 1 or 2.');
        end
        counts=[1 nf nv]; colorCount=counts(flag+1);
        requireBytes(4*colorCount+4*nf,1);
        if binary
            colors=reshape(numbers(4*colorCount,'uint8',machine),4,[]);
            colors=flipud(colors)/255; % Disk ABGR bytes, independent of integer byte order.
        else
            colors=reshape(numbers(4*colorCount,'single',machine),4,[]);
        end
        if any(~isfinite(colors) | colors<0 | colors>1,'all')
            error('BNV:IO:MniObjAppearance','MNI/BIC RGBA values must lie in [0,1].');
        end
        requireBytes(4*nf,4);
        ends=numbers(nf,'int32',machine);
        if isequal(ends,3*(1:nf).')
            topology='cumulative-end-indices';
        elseif all(ends==3)
            topology='per-polygon-sizes';
        else
            error('BNV:IO:MniObjPolygons','Only triangles are supported; expected cumulative ends 3,6,... or individual sizes 3.');
        end
        faces=reshape(numbers(3*nf,'int32',machine),3,[]).';
        if any(~isfinite(faces) | faces~=fix(faces) | faces<0 | faces>=nv,'all')
            error('BNV:IO:InvalidFaceIndex','MNI/BIC indices must be zero-based integers within the vertex range.');
        end
        while ~feof(file)
            tail=fread(file,4096,'*char');
            if (binary && ~isempty(tail)) || any(~isspace(tail))
                error('BNV:IO:MniObjTrailingData','Multiple objects and trailing data are not supported.');
            end
        end
        modes=["overall","per-face","per-vertex"];
        encoding='ascii'; byteOrder='not-applicable';
        if binary, encoding='binary'; byteOrder=char(order); end
        meta=struct('format','mni-bic-obj','encoding',encoding,'byte_order',byteOrder, ...
            'vertex_count',nv,'face_count',nf,'polygon_dimension',3, ...
            'topology_encoding',topology,'index_base_on_disk',0,'index_base_in_memory',1, ...
            'color_mode',char(modes(flag+1)),'color_count',colorCount, ...
            'colors_rgba_sha256',char(brainnet.io.internal.numericSha256(colors)), ...
            'normals_sha256',char(brainnet.io.internal.numericSha256(normals)), ...
            'source_material',material.', ...
            'appearance_policy','Source material, RGBA and normals validated but not applied; use Visualization Settings', ...
            'coordinate_policy','As stored; no registration or units inferred; ASCII double and binary float32 coordinates');
        if flag==0, meta.source_overall_rgba=colors.'; end
        mesh=brainnet.io.SurfaceData(coordinates,faces+1,reference,Metadata=meta);
    end
    function value=numbers(count,precision,machine)
        if binary
            [value,actual]=fread(file,count,precision,0,machine);
        else
            [value,actual]=fscanf(file,' %f',count);
        end
        if actual~=count
            error('BNV:IO:MniObjTruncated','Incomplete or malformed MNI/BIC numeric array.');
        end
    end
    function checkCount(value,limit)
        if ~isfinite(value) || value<1 || value~=fix(value) || value>2147483647 || value>limit
            error('BNV:IO:MniObjCounts','Invalid or excessive MNI/BIC vertex or polygon count.');
        end
    end
    function requireBytes(count,width)
        if ~binary, width=1; end
        if count*width>total-ftell(file)
            error('BNV:IO:MniObjTruncated','Declared MNI/BIC arrays exceed the remaining file length.');
        end
    end
end

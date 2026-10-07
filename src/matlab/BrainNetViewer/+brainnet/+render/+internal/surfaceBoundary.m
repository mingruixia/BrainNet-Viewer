function result=surfaceBoundary(values,faces,mode,options)
%SURFACEBOUNDARY Full-input classification with original-order vertex masks.
arguments
    values double
    faces double
    mode (1,1) string {mustBeMember(mode,["none","automatic","legacy-automatic","threshold","custom"])}="automatic"
    options.VertexIndices double=[]
    options.Threshold (1,1) double {mustBeFinite}=0
    options.Mask double=[]
end
values=values(:); n=numel(values); indices=options.VertexIndices(:);
if isempty(indices), indices=(1:n).'; end
if ~isreal(values) || ~isreal(faces) || size(faces,2)~=3 || ...
        any(~isfinite(faces),'all') || any(faces~=fix(faces),'all') || ...
        any(faces<1 | faces>numel(indices),'all') || any(~isfinite(indices)) || ...
        any(indices~=fix(indices) | indices<1 | indices>n) || numel(unique(indices))~=numel(indices)
    error('BNV:Boundary:InvalidGeometry','Boundary inputs require real values and valid triangular vertex indices.');
end
finite=isfinite(values); samples=values(finite); classes=sign(values); classification='sign';
if any(mode==["legacy-automatic","threshold","custom"])
    mask=false(n,1);
    if mode=="custom"
        custom=brainnet.core.BoundaryMask.validate(options.Mask);
        if numel(custom)~=n || isempty(custom), error('BNV:Boundary:MaskSize','Custom mask length must match the surface.'); end
        mask=logical(custom(:)); classification='custom-binary-mask';
    else
        if any(~finite), error('BNV:Boundary:LegacyNonFinite','Legacy boundary modes require finite mapped values.'); end
        classes=values;
        if mode=="threshold"
            classes=double(values>options.Threshold); classification='legacy-strict-greater-than';
        else
            % Deliberately preserve the legacy signed-sum test, including cancellation.
            if sum(values-fix(values))~=0, classes(values~=0)=1; end
            classification='legacy-signed-sum-automatic';
        end
        faceValues=reshape(classes(indices(faces)),size(faces));
        mixed=~all(diff(faceValues,1,2)==0,2);
        mask(indices(unique(faces(mixed,:))))=true; mask(values==0)=false;
    end
    result=struct('mask',mask,'edges',zeros(0,2),'classification',classification, ...
        'algorithm','legacy-vertex-boundary-1.0','missing_vertices',nnz(~finite));
    return;
end
if mode~="threshold" && ~isempty(samples) && ...
        max(abs(samples-round(samples)))<1e-8 && numel(unique(samples))<=256
    classes=round(values); classification='integer-labels';
end
classes=classes(indices); valid=finite(indices);
edges=[faces(:,[1 2]);faces(:,[2 3]);faces(:,[3 1])];
different=valid(edges(:,1)) & valid(edges(:,2)) & classes(edges(:,1))~=classes(edges(:,2));
if mode=="none", different(:)=false; end
edges=unique(sort(edges(different,:),2),'rows'); mask=false(n,1);
mask(indices(unique(edges(:))))=true;
result=struct('mask',mask,'edges',edges,'classification',classification, ...
    'algorithm','modern-transition-vertices-1.0','missing_vertices',nnz(~finite));
end

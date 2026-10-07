classdef MovieExporter < handle
    %MOVIEEXPORTER Isolated orbit rendering, cancellation and no-replace bundles.
    properties (Access=private)
        Stage string=""
        Writer=[]
        Renderer=[]
    end
    methods (Static)
        function formats=availableFormats()
            profiles=VideoWriter.getProfiles(); names=string({profiles.Name});
            formats="png";
            if any(names=="Motion JPEG AVI"), formats=["avi" formats]; end
            if any(names=="MPEG-4"), formats=["mp4" formats]; end
        end
        function record=export(renderer,scene,prepared,destination,options)
            arguments
                renderer (1,1) brainnet.render.MatlabBatchRenderer
                scene (1,1) brainnet.core.Scene
                prepared (1,1) brainnet.render.PreparedScene
                destination (1,1) string
                options.Format (1,1) string="mp4"
                options.Width (1,1) double=960
                options.Height (1,1) double=720
                options.Duration (1,1) double=5
                options.FrameRate (1,1) double=24
                options.Axis (1,1) string="z"
                options.StartAngle (1,1) double=0
                options.EndAngle (1,1) double=360
                options.SafeFit (1,1) logical=true
                options.Cancel (1,1) function_handle=@() false
                options.Progress (1,1) function_handle=@(done,total) []
            end
            plan=brainnet.export.MoviePlan.create(Format=options.Format,Width=options.Width,Height=options.Height, ...
                Duration=options.Duration,FrameRate=options.FrameRate,Axis=options.Axis, ...
                StartAngle=options.StartAngle,EndAngle=options.EndAngle,SafeFit=options.SafeFit);
            original=renderer.captureCamera();
            if isempty(original)||isempty(renderer.ActiveTarget)||~isgraphics(renderer.ActiveTarget)
                error('BNV:Movie:RenderRequired','Render with Modern Batch Renderer before exporting an animation.');
            end
            planner=brainnet.render.RenderPlanner(AlgorithmVersion=prepared.AlgorithmVersion);
            keys=strings(1,3); backends=["auto","cpu","gpu"];
            for k=1:3, keys(k)=planner.keyFor(scene,ComputeBackend=backends(k)); end
            if ~any(keys==prepared.CacheKey) || original.layout~=scene.Options.Layout
                error('BNV:Movie:StalePrepared','The rendered data or layout do not match this Scene. Render again.');
            end
            if ~any(options.Format==brainnet.export.MovieExporter.availableFormats())
                error('BNV:Movie:UnavailableFormat','This MATLAB installation does not provide the selected video profile. Use PNG frames or AVI.');
            end
            destination=string(char(java.io.File(char(destination)).getCanonicalPath()));
            parent=string(fileparts(destination));
            if isfile(destination)||isfolder(destination)
                error('BNV:Movie:OutputExists','Choose a NEW output folder. Existing files and folders are never overwritten.');
            end
            if ~isfolder(parent), error('BNV:Movie:OutputParent','The parent output folder must already exist.'); end
            checkCancel(options.Cancel);
            stage=string(tempname(parent)); mkdir(stage);
            resources=brainnet.export.MovieExporter(); resources.Stage=stage;
            cleanup=onCleanup(@() resources.release());
            clone=brainnet.render.MatlabBatchRenderer(); resources.Renderer=clone;
            timer=tic;
            clone.render(prepared,scene.Options,Visible=false,Position=[20 20 plan.width plan.height], ...
                PerformanceMode="quality",ComputeBackend="cpu");
            clone.restoreCamera(original);
            if plan.safe_fit, safeOrbitFit(clone); end
            base=clone.captureCamera();
            % Anatomical static labels would misidentify views during rotation.
            delete(findall(clone.ActiveTarget,'Tag','brainnet-orientation-label'));
            writer=[]; video="";
            if options.Format~="png"
                profile='Motion JPEG AVI'; if options.Format=="mp4", profile='MPEG-4'; end
                video="movie."+options.Format;
                writer=VideoWriter(char(fullfile(stage,video)),profile);
                resources.Writer=writer;
                writer.FrameRate=plan.frame_rate; writer.Quality=95; open(writer);
            end
            entries=repmat(struct('index',0,'angle',0,'file','','sha256',''),plan.frame_count,1);
            lightSettings=scene.Options.section('global');
            for k=1:plan.frame_count
                checkCancel(options.Cancel);
                camera=brainnet.export.MoviePlan.orbit(base,string(plan.axis),plan.angles(k));
                clone.restoreCamera(camera);
                for a=reshape(clone.ActiveAxes,1,[])
                    for light=reshape(findall(a,'Type','light'),1,[]), camlight(light,char(lightSettings.light_direction)); end
                end
                drawnow;
                filename=sprintf('frame-%06d.png',k);
                if options.Format~="png", filename='capture.png'; end
                frameFile=fullfile(stage,filename);
                pixels=captureFrame(clone.ActiveTarget,frameFile,plan.width,plan.height);
                if k==1, imwrite(pixels,fullfile(stage,'preview.png')); end
                if ~isempty(writer), writeVideo(writer,pixels); end
                entries(k)=struct('index',k,'angle',plan.angles(k),'file',filename, ...
                    'sha256',char(brainnet.io.internal.sha256File(frameFile)));
                if options.Format~="png", entries(k).file=''; end
                options.Progress(k,plan.frame_count); drawnow; checkCancel(options.Cancel);
            end
            if ~isempty(writer)
                close(writer);
                delete(fullfile(stage,'capture.png'));
                count=verifyVideo(fullfile(stage,video),plan,options.Cancel);
                videoHash=brainnet.io.internal.sha256File(fullfile(stage,video));
            else
                count=plan.frame_count; videoHash="";
            end
            record=struct('kind','brainnet-camera-movie','schema_version','1.0','plan',plan, ...
                'scene',scene.toStruct(),'prepared',prepared.summary(),'source_camera',original,'orbit_base_camera',base, ...
                'camera_rule','World-axis rotation about each view target; position and up rotated from base, never accumulated.', ...
                'lighting_rule','Camera-relative lights updated each frame; static orientation labels omitted.', ...
                'prepared_key',char(prepared.CacheKey),'surface_sha256',char(brainnet.io.internal.numericSha256(prepared.SurfaceCoordinates)), ...
                'values_sha256',char(brainnet.io.internal.numericSha256(prepared.SurfaceValues)), ...
                'renderer_metrics',clone.LastMetrics,'matlab_version',version,'frames',entries, ...
                'video_file',char(video),'video_sha256',char(videoHash),'verified_frames',count, ...
                'frame_hash_semantics','SHA-256 of pre-encoding PNG bytes; lossy video pixels need not match.', ...
                'source_camera_untouched',true,'elapsed_seconds',toc(timer));
            brainnet.io.internal.writeJsonFile(fullfile(stage,'provenance.json'),record);
            checkCancel(options.Cancel);
            java.nio.file.Files.move(java.io.File(char(stage)).toPath(),java.io.File(char(destination)).toPath(),javaArray('java.nio.file.CopyOption',0));
            record.output_folder=char(destination);
        end
    end
    methods (Access=private)
        function release(obj)
            % Release the encoder BEFORE removing its temporary directory.
            closeWriter(obj.Writer);
            if ~isempty(obj.Renderer)&&isvalid(obj.Renderer), delete(obj.Renderer); end
            if strlength(obj.Stage)>0, removeStage(obj.Stage); end
        end
    end
end

function safeOrbitFit(renderer)
renderer.fitCamera(); state=renderer.captureCamera(); radius=zeros(numel(state.views),1); aspect=radius;
for k=1:numel(state.views)
    a=renderer.ActiveAxes(k); target=state.views(k).target;
    for p=reshape(findall(a,'Type','patch'),1,[])
        if ~isempty(p.Vertices), radius(k)=max(radius(k),max(vecnorm(double(p.Vertices)-target,2,2))); end
    end
    position=getpixelposition(a); aspect(k)=max(position(3),1)/max(position(4),1);
end
heights=arrayfun(@(a) a.Position(4),renderer.ActiveAxes);
distance=max(1,5*max(radius));
extent=1.10*max(radius.*max(1,1./aspect)./heights(:));
for k=1:numel(state.views)
    v=state.views(k); direction=v.position-v.target;
    state.views(k).position=v.target+direction/norm(direction)*distance;
    state.views(k).view_angle=2*atand(max(extent,eps)*heights(k)/distance);
    if numel(state.views)==1
        state.views(k).view_angle=2*atand(max(extent,eps)* ...
            brainnet.render.CameraState.viewportFactor(renderer.ActiveAxes(k))/distance);
    end
    state.views(k).projection='orthographic';
end
renderer.restoreCamera(state);
end

function pixels=captureFrame(target,path,width,height)
expected=[width height]; factor=1;
legacyOptions=verLessThan('matlab','25.1');
resolution=100;
for attempt=1:4
    if legacyOptions
        % Local MATLAB before R2025a has no Padding/Width/Height controls.
        % Adjust rendering resolution, then center-pad rather than stretch.
        exportgraphics(target,path,'ContentType','image','Resolution',resolution, ...
            'BackgroundColor',target.Color);
    else
        exportgraphics(target,path,'ContentType','image','Resolution',100,'BackgroundColor',target.Color, ...
            'Padding','figure','Width',width*factor,'Height',height*factor, ...
            'Units','pixels','PreserveAspectRatio','on');
    end
    info=imfinfo(path);
    actual=[info.Width info.Height];
    if all(actual<=expected) && (~legacyOptions || max(actual./expected)>.95)
        break;
    end
    ratio=min(max(1,expected-2)./actual);
    if legacyOptions
        updated=max(1,floor(resolution*ratio));
        if updated==resolution, break; end
        resolution=updated;
    else
        factor=factor*ratio;
    end
end
if any([info.Width info.Height]>expected), error('BNV:Movie:FrameSize','Cannot export the exact frame size without distortion.'); end
pixels=imread(path);
if size(pixels,3)==1, pixels=repmat(pixels,1,1,3); end
if ~isequal([info.Width info.Height],expected)
    background=uint8(round(255*reshape(target.Color,1,1,3)));
    padded=repmat(background,height,width,1); offset=floor((expected-[info.Width info.Height])/2);
    padded(offset(2)+(1:info.Height),offset(1)+(1:info.Width),:)=pixels;
    pixels=padded; imwrite(pixels,path);
end
end

function checkCancel(callback)
if callback(), error('BNV:Movie:Cancelled','Animation export cancelled. No output bundle was published.'); end
end
function count=verifyVideo(path,plan,cancel)
% The decoder leaves scope before bundle publication / staging cleanup.
reader=VideoReader(char(path)); count=0;
while hasFrame(reader)
    frame=readFrame(reader); count=count+1;
    assert(size(frame,1)==plan.height && size(frame,2)==plan.width,'BNV:Movie:VideoSize','Encoded frame size differs.');
    drawnow limitrate;
    checkCancel(cancel);
end
assert(count==plan.frame_count,'BNV:Movie:FrameCount','Encoded frame count differs.');
end
function closeWriter(writer)
if ~isempty(writer)
    try
        close(writer);
    catch
        % Cleanup must not replace the original export/cancellation error.
    end
end
end
function removeStage(path)
% Only the unique directory created by this call; never the destination.
if isfolder(path), rmdir(path,'s'); end
end

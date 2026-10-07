classdef SceneInspector
    %SCENEINSPECTOR Source-coordinate inspection without inferred registration.
    methods (Static)
        function result=queryDirectMni(scene,data,prepared,role,point,index)
            arguments
                scene (1,1) brainnet.core.Scene
                data (1,1) struct
                prepared
                role (1,1) string {mustBeMember(role,["surface","node"])}
                point (1,3) double {mustBeFinite,mustBeReal}
                index (1,1) double {mustBeInteger,mustBeNonnegative}=0
            end
            aal=brainnet.query.InspectionSettings.directMni(scene,"aal");
            brodmann=brainnet.query.InspectionSettings.directMni(scene,"brodmann");
            result=brainnet.query.SceneInspector.query(scene,data,prepared,role,point,index,aal);
            other=brainnet.query.SceneInspector.query(scene,data,prepared,role,point,index,brodmann);
            result.aal_region=brainnet.query.SceneInspector.regionName(result.atlas);
            result.brodmann_area=brainnet.query.SceneInspector.regionName(other.atlas);
        end
        function lines=canvasLabel(result)
            lines=[string(sprintf('%s vertex %d',upper(result.role),result.source_index)); ...
                string(sprintf('MNI XYZ (assumed): %.4g, %.4g, %.4g',result.coordinate))];
            if strcmp(result.role,'node')
                lines=[lines;"Node: "+string(result.node_label); ...
                    string(sprintf('Module: %.4g | Value: %.4g',result.node_module,result.node_value))];
            elseif ~isempty(result.surface_value)
                lines(end+1)="Surface value: "+string(result.surface_value);
            end
            lines=[lines;"Brodmann Area: "+string(result.brodmann_area); ...
                "AAL region: "+string(result.aal_region)];
        end
        function result=query(scene,data,prepared,role,point,index,settings)
            arguments
                scene (1,1) brainnet.core.Scene
                data (1,1) struct
                prepared
                role (1,1) string {mustBeMember(role,["surface","node"])}
                point (1,3) double {mustBeFinite,mustBeReal}
                index (1,1) double {mustBeInteger,mustBeNonnegative} = 0
                settings (1,1) struct = brainnet.query.InspectionSettings.defaults()
            end
            settings=brainnet.query.InspectionSettings.validate(settings);
            if ~isfield(data,role), error('BNV:Query:MissingData','Load the selected source before querying.'); end
            source=data.(role);
            if role=="surface", coordinates=source.Coordinates.'; else, coordinates=source.Coordinates; end
            if index==0
                [distance2,index]=min(sum((coordinates-point).^2,2)); distance=sqrt(distance2);
                method='nearest source coordinate (not barycentric interpolation)';
            else
                if index>size(coordinates,1), error('BNV:Query:InvalidIndex','Source index is outside the loaded data.'); end
                distance=norm(coordinates(index,:)-point); method='source index from displayed glyph';
            end
            xyz=coordinates(index,:);
            result=struct('role',char(role),'source_index',index,'coordinate',xyz, ...
                'hit_coordinate',point,'distance_from_hit',distance,'method',method, ...
                'coordinate_space',char(source.Source.CoordinateSpace), ...
                'source',char(source.Source.RelativePath),'sha256',char(source.Source.Sha256), ...
                'node_label','','node_module',[],'node_value',[],'surface_value',[], ...
                'atlas',struct('status','disabled'));
            if role=="node"
                result.node_label=char(source.Labels(index)); result.node_module=source.Module(index);
                result.node_value=source.Size(index);
            elseif ~isempty(prepared) && numel(prepared.SurfaceValues)==size(coordinates,1)
                result.surface_value=prepared.SurfaceValues(index);
            elseif isfield(data,'surface_map')
                result.surface_value=data.surface_map(index);
            end
            if strcmp(settings.atlas,'none'), return; end
            result.atlas=struct('status','registration-unconfirmed');
            if ~settings.confirmed, return; end
            if string(settings.input_signature)~=brainnet.query.InspectionSettings.inputSignature(scene)
                result.atlas.status='stale-registration'; return;
            end
            if strcmp(settings.atlas,'volume')
                if ~isfield(data,'volume'), result.atlas.status='volume-not-loaded'; return; end
                volume=data.volume;
                atlas=struct('data',volume.Data,'affine',volume.Affine, ...
                    'labels',settings.labels,'name','Loaded label volume', ...
                    'source',char(volume.Source.RelativePath),'sha256',char(volume.Source.Sha256));
                if isfield(volume.Header,'DataSha256'), atlas.sha256=char(volume.Header.DataSha256); end
            else
                atlas=brainnet.query.AtlasLookup.builtin(settings.atlas);
            end
            result.atlas=brainnet.query.AtlasLookup.sample(atlas,xyz,settings.scene_to_atlas);
            result.atlas.source_space=settings.source_space;
            result.atlas.atlas_space=settings.atlas_space;
            result.atlas.transform_note=settings.transform_note;
        end
        function lines=describe(r)
            lines=[sprintf('%s | Source index: %d',upper(r.role),r.source_index); ...
                string(sprintf('XYZ: %.6g, %.6g, %.6g (source units)',r.coordinate)); ...
                "Source space: "+string(r.coordinate_space); ...
                "File: "+string(r.source); "Method: "+string(r.method); ...
                string(sprintf('Distance from hit: %.6g',r.distance_from_hit))];
            if strcmp(r.role,'node')
                lines=[lines;"Node: "+string(r.node_label); ...
                    string(sprintf('Color / module column: %.6g | Value / size column: %.6g',r.node_module,r.node_value))];
            elseif ~isempty(r.surface_value)
                lines(end+1)="Prepared surface value: "+string(r.surface_value);
            end
            lines(end+1)="Atlas status: "+string(r.atlas.status);
            if isfield(r.atlas,'voxel_1based')
                lines=[lines;"Atlas: "+string(r.atlas.name)];
                if contains(string(r.atlas.transform_note),"Direct MNI lookup")
                    lines(end+1)="Coordinate assumption: MNI (not verified); no transform applied";
                else
                    lines(end+1)="Declared mapping: "+string(r.atlas.source_space)+" -> "+string(r.atlas.atlas_space);
                end
                lines=[lines;"Atlas XYZ: "+join(string(r.atlas.atlas_coordinate),', '); ...
                    "Voxel (1-based): "+join(string(r.atlas.voxel_1based),', '); ...
                    "Label ID: "+join(string(r.atlas.label_id),', '); ...
                    "Region: "+string(r.atlas.label); "Lookup: "+string(r.atlas.method)];
                if ~contains(string(r.atlas.transform_note),"Direct MNI lookup")
                    lines(end+1)="Transform evidence: "+string(r.atlas.transform_note);
                end
            end
        end
    end
    methods (Static, Access=private)
        function name=regionName(atlas)
            if isfield(atlas,'label') && strlength(strtrim(string(atlas.label)))>0
                name=string(atlas.label);
            elseif strcmp(atlas.status,'background')
                name="Unlabeled";
            elseif strcmp(atlas.status,'outside')
                name="Outside atlas";
            else
                name="Unavailable ("+string(atlas.status)+")";
            end
        end
    end
end

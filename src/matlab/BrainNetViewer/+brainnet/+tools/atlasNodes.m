function [values,labels,report]=atlasNodes(volume,options)
%ATLASNODES Unweighted voxel-centre means in the NIfTI affine coordinate frame.
arguments
    volume (1,1) brainnet.io.VolumeData
    options.Regions double = []
    options.Module (1,1) double {mustBeFinite,mustBeReal} = 0
    options.Size (1,1) double {mustBeFinite,mustBeReal,mustBeNonnegative} = 0
end
d=volume.Data; dims=double(volume.Dimensions(:)');
if numel(dims)>3 && any(dims(4:end)~=1)
    error('BNV:AtlasNodes:Dimensions','Use one 3-D discrete label atlas, not a 4-D atlas or time series.');
end
dims=[dims ones(1,max(0,3-numel(dims)))]; dims=dims(1:3);
if ~isreal(d) || prod(dims)~=numel(d)
    error('BNV:AtlasNodes:Dimensions','Atlas array and spatial dimensions must agree.');
end
ids=unique(double(d(:))); ids(ids==0)=[];
if isempty(ids) || numel(ids)>100000 || any(~isfinite(ids) | ids~=fix(ids) | abs(ids)>flintmax)
    error('BNV:AtlasNodes:Labels','Atlas must contain 1 to 100000 finite, exactly representable nonzero integer labels. Background is zero; probability/statistical maps are not label atlases.');
end
if ~isempty(options.Regions)
    requested=options.Regions(:);
    if ~isreal(requested) || ~isvector(options.Regions) || any(~isfinite(requested) | requested==0 | requested~=fix(requested)) || ...
            numel(unique(requested))~=numel(requested) || ~all(ismember(requested,ids))
        error('BNV:AtlasNodes:Regions','Requested labels must be unique, nonzero integer IDs present in the atlas.');
    end
    ids=requested;
end
a=volume.Affine;
if any(abs(a(4,:)-[0 0 0 1])>1e-12) || rcond(a(1:3,1:3))<=eps
    error('BNV:AtlasNodes:Affine','Atlas must have a nonsingular spatial affine with last row [0 0 0 1].');
end
counts=zeros(numel(ids),1); sums=zeros(numel(ids),3);
% Group labels per bounded chunk, avoiding one complete atlas scan per ROI.
for first=1:1000000:numel(d)
    last=min(numel(d),first+999999);
    [selected,group]=ismember(double(d(first:last)),ids);
    indices=find(selected(:))+first-1; group=group(selected); group=group(:);
    if isempty(group), continue; end
    [x,y,z]=ind2sub(dims,indices);
    counts=counts+accumarray(group,1,[numel(ids),1]);
    sums=sums+[accumarray(group,x,[numel(ids),1]),accumarray(group,y,[numel(ids),1]),accumarray(group,z,[numel(ids),1])];
end
centres=sums./counts;
world=[centres ones(numel(ids),1)]*a';
if any(~isfinite(world),'all')
    error('BNV:AtlasNodes:Affine','Affine transformation produced nonfinite node coordinates.');
end
values=[world(:,1:3),repmat(options.Module,numel(ids),1),repmat(options.Size,numel(ids),1)];
labels=compose("%.0f",ids);
method='provided VolumeData affine';
if isfield(volume.Header,'AffineMethod'), method=char(volume.Header.AffineMethod); end
report=struct('kind','brainnet-atlas-nodes','schema_version','1.0', ...
    'method','unweighted mean of 1-based voxel centres, then VolumeData.Affine; no registration or snapping', ...
    'region_ids',ids,'voxel_counts',counts,'voxel_centres_one_based',centres, ...
    'affine_one_based',a,'affine_method',method,'dimensions',dims, ...
    'module_value',options.Module,'size_value',options.Size,'node_count',numel(ids), ...
    'background_id',0,'label_rule','original numeric region ID', ...
    'centroid_inside_region_guaranteed',false);
end

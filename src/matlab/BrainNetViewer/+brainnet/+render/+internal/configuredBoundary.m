function result=configuredBoundary(prepared,settings)
%CONFIGUREDBOUNDARY Shared mask semantics and geometry binding for rendering/export.
mode=string(settings.boundary_mode); values=prepared.SurfaceValues;
if mode=="custom"
    hash=brainnet.core.BoundaryMask.signature(prepared.SurfaceCoordinates,prepared.SurfaceFaces);
    if string(settings.boundary_mesh_sha256)~=hash
        error('BNV:Boundary:MaskBinding','Custom mask is unbound or belongs to different ordered geometry. Verify and bind it to this surface first.');
    end
    if isempty(values), values=zeros(1,prepared.VertexCount); end
elseif mode~="none" && isempty(values)
    error('BNV:Boundary:MissingMap','This boundary mode requires a surface map or mapped volume.');
end
result=brainnet.render.internal.surfaceBoundary(values,prepared.SurfaceFaces,mode, ...
    Threshold=settings.boundary_threshold,Mask=settings.boundary_mask);
end

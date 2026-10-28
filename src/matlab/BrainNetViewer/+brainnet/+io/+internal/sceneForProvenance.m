function value=sceneForProvenance(scene)
%SCENEFORPROVENANCE Keep private local file locations out of exported records.
value=scene.toStruct();
for role=reshape(string(fieldnames(value.inputs)),1,[])
    input=value.inputs.(role);
    if isfield(input,'local_path'),input=rmfield(input,'local_path');end
    value.inputs.(role)=input;
end
end

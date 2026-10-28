function files=inputCompanions(path)
%INPUTCOMPANIONS Required local paired/ExternalFileBinary data for packaging.
files=struct('source',{},'relative',{});folder=string(fileparts(path));lowerPath=lower(path);
if any(endsWith(lowerPath,[".hdr",".img",".hdr.gz",".img.gz"]))
    if endsWith(lowerPath,".gz"),stem=extractBefore(path,strlength(path)-6);suffix=".gz";
    else,stem=extractBefore(path,strlength(path)-3);suffix="";end
    if contains(lowerPath,".hdr"),other=stem+".img"+suffix;else,other=stem+".hdr"+suffix;end
    if ~isfile(other),error('BNV:IO:PackageCompanionMissing','Paired input is missing: %s',other);end
    [~,name,ext]=fileparts(other);files=struct('source',other,'relative',string(name)+string(ext));
elseif endsWith(lowerPath,".gii") || endsWith(lowerPath,".gii.gz")
    local=path;temporary="";
    if endsWith(lowerPath,".gz")
        temporary=string(tempname);mkdir(temporary);cleanup=onCleanup(@() rmdir(temporary,'s'));
        names=gunzip(path,temporary);local=string(names{1});
    end
    % Match the reader's XML boundary; companion discovery must not fetch DTDs.
    if contains(upper(fileread(local)),'<!ENTITY')
        error('BNV:IO:UnsafeGiftiXml','GIfTI files containing entity declarations are rejected.');
    end
    factory=javax.xml.parsers.DocumentBuilderFactory.newInstance();
    factory.setNamespaceAware(false);factory.setExpandEntityReferences(false);factory.setXIncludeAware(false);
    factory.setFeature('http://xml.org/sax/features/external-general-entities',false);
    factory.setFeature('http://xml.org/sax/features/external-parameter-entities',false);
    factory.setFeature('http://apache.org/xml/features/nonvalidating/load-external-dtd',false);
    builder=factory.newDocumentBuilder();document=builder.parse(java.io.File(char(local)));
    arrays=document.getElementsByTagName('DataArray');
    seen=strings(1,0);
    for index=0:arrays.getLength()-1
        item=arrays.item(index);
        if ~strcmpi(char(item.getAttribute('Encoding')),'ExternalFileBinary'),continue;end
        if temporary~="",error('BNV:IO:CompressedExternalGifti','Uncompress ExternalFileBinary GIfTI before packaging.');end
        name=string(char(item.getAttribute('ExternalFileName')));
        if any(seen==name),continue;end
        source=brainnet.io.internal.sceneRelativeFile(folder,name);
        if ~isfile(source),error('BNV:IO:PackageCompanionMissing','GIfTI data missing: %s',name);end
        files(end+1)=struct('source',source,'relative',name);seen(end+1)=name;
    end
end
end

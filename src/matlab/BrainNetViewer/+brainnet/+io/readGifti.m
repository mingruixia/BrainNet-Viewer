function surface = readGifti(reference, rootPath)
%READGIFTI Read a GIfTI surface, including external binary arrays.

arguments
    reference (1, 1) brainnet.core.InputReference
    rootPath (1, 1) string
end

sourcePath = brainnet.io.internal.resolveAndVerify(reference, rootPath, "surface");
[pathValue, temporaryFolder] = prepareInput(sourcePath);
inputCleanup = onCleanup(@() removeTemporaryFolder(temporaryFolder));
xmlText = fileread(pathValue);
if contains(upper(xmlText), '<!ENTITY')
    error('BNV:IO:UnsafeGiftiXml', 'GIfTI files containing entity declarations are rejected.');
end
try
    factory = javax.xml.parsers.DocumentBuilderFactory.newInstance();
    factory.setNamespaceAware(false);
    factory.setExpandEntityReferences(false);
    factory.setXIncludeAware(false);
    factory.setFeature('http://xml.org/sax/features/external-general-entities', false);
    factory.setFeature('http://xml.org/sax/features/external-parameter-entities', false);
    factory.setFeature('http://apache.org/xml/features/nonvalidating/load-external-dtd', false);
    builder = factory.newDocumentBuilder();
    document = builder.parse(java.io.File(char(pathValue)));
catch exception
    error('BNV:IO:InvalidGiftiXml', 'Unable to parse GIfTI XML: %s', exception.message);
end
root = document.getDocumentElement();
if ~strcmpi(string(char(root.getTagName())), "GIFTI")
    error('BNV:IO:InvalidGiftiRoot', 'GIfTI XML root element must be GIFTI.');
end
nodes = document.getElementsByTagName('DataArray');
if nodes.getLength() == 0
    error('BNV:IO:MissingGiftiDataArray', 'GIfTI file contains no DataArray elements.');
end

arrays = cell(nodes.getLength(), 1);
coordinates = [];
facesZeroBased = [];
coordinateSystems = {};
for index = 1:nodes.getLength()
    array = brainnet.io.internal.decodeGiftiDataArray(nodes.item(index - 1), string(fileparts(sourcePath)));
    arrays{index} = array;
    if isIntent(array.Intent, "NIFTI_INTENT_POINTSET", 1008)
        if ~isempty(coordinates)
            error('BNV:IO:DuplicateGiftiPointSet', 'GIfTI contains more than one point-set DataArray.');
        end
        coordinates = array.Value;
        coordinateSystems = array.CoordinateSystems;
    elseif isIntent(array.Intent, "NIFTI_INTENT_TRIANGLE", 1009)
        if ~isempty(facesZeroBased)
            error('BNV:IO:DuplicateGiftiTriangles', 'GIfTI contains more than one triangle DataArray.');
        end
        facesZeroBased = array.Value;
    end
end
if isempty(coordinates)
    error('BNV:IO:MissingGiftiPointSet', 'GIfTI surface has no point-set DataArray.');
end
if isempty(facesZeroBased)
    error('BNV:IO:MissingGiftiTriangles', 'GIfTI surface has no triangle DataArray.');
end
if any(facesZeroBased < 0, 'all')
    error('BNV:IO:InvalidGiftiTriangles', 'GIfTI triangle indices must be zero-based nonnegative integers.');
end
surface = brainnet.io.GiftiData( ...
    double(coordinates), double(facesZeroBased) + 1, arrays, coordinateSystems, reference);
end


function tf = isIntent(value, symbolicName, numericCode)
tf = strcmpi(value, symbolicName) || str2double(value) == numericCode;
end


function [pathValue, folder] = prepareInput(sourcePath)
folder = "";
pathValue = sourcePath;
if ~endsWith(lower(sourcePath), ".gz")
    return;
end
folder = string(tempname);
mkdir(folder);
try
    outputs = gunzip(sourcePath, folder);
catch exception
    removeTemporaryFolder(folder);
    error('BNV:IO:GiftiDecompressionFailed', 'Unable to decompress GIfTI input: %s', exception.message);
end
if isempty(outputs) || ~isfile(outputs{1})
    removeTemporaryFolder(folder);
    error('BNV:IO:GiftiDecompressionFailed', 'GIfTI decompression produced no file.');
end
pathValue = string(outputs{1});
end


function removeTemporaryFolder(folder)
if strlength(folder) > 0 && isfolder(folder)
    rmdir(folder, 's');
end
end

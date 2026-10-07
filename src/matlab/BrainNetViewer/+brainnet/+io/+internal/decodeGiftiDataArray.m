function result = decodeGiftiDataArray(node, baseFolder)
%DECODEGIFTIDATAARRAY Decode one embedded or external GIfTI DataArray.

arguments
    node
    baseFolder (1, 1) string
end

result = struct;
result.Intent = string(char(node.getAttribute('Intent')));
result.DataType = string(char(node.getAttribute('DataType')));
result.ArrayIndexingOrder = string(char(node.getAttribute('ArrayIndexingOrder')));
result.Encoding = string(char(node.getAttribute('Encoding')));
result.Endian = string(char(node.getAttribute('Endian')));
result.ExternalFileName = string(char(node.getAttribute('ExternalFileName')));
result.ExternalFileOffset = 0;
result.ExternalFileSha256 = "";
result.CoordinateSystems = readCoordinateSystems(node);
dimensionality = str2double(string(char(node.getAttribute('Dimensionality'))));
if ~isfinite(dimensionality) || dimensionality < 1 || dimensionality ~= fix(dimensionality)
    error('BNV:IO:InvalidGiftiDimensions', 'GIfTI Dimensionality must be a positive integer.');
end
dimensions = zeros(1, dimensionality);
for index = 1:dimensionality
    dimensions(index) = str2double(string(char(node.getAttribute(sprintf('Dim%d', index - 1)))));
end
if any(~isfinite(dimensions)) || any(dimensions < 1) || any(dimensions ~= fix(dimensions))
    error('BNV:IO:InvalidGiftiDimensions', 'GIfTI dimensions must be positive integers.');
end
result.Dimensions = dimensions;
[matlabClass, bytesPerValue] = brainnet.io.internal.giftiDatatype(result.DataType);
dataNodes = node.getElementsByTagName('Data');
if dataNodes.getLength() ~= 1
    error('BNV:IO:InvalidGiftiDataArray', 'Every GIfTI DataArray must contain exactly one Data element.');
end
text = string(char(dataNodes.item(0).getTextContent()));
expectedCount = prod(dimensions);
switch upper(result.Encoding)
    case "ASCII"
        values = sscanf(char(text), '%f');
        if numel(values) ~= expectedCount
            error('BNV:IO:GiftiValueCountMismatch', ...
                'GIfTI array contains %d values; expected %d.', numel(values), expectedCount);
        end
    case {"BASE64BINARY", "GZIPBASE64BINARY"}
        try
            bytes = uint8(matlab.net.base64decode(text));
        catch exception
            error('BNV:IO:InvalidGiftiBase64', 'Unable to decode GIfTI Base64 data: %s', exception.message);
        end
        if strcmpi(result.Encoding, 'GZipBase64Binary')
            bytes = inflateBytes(bytes);
        end
    case "EXTERNALFILEBINARY"
        [bytes, result.ExternalFileOffset, result.ExternalFileSha256] = ...
            readExternalBytes(node, baseFolder, result.ExternalFileName, expectedCount * bytesPerValue);
    otherwise
        error('BNV:IO:UnsupportedGiftiEncoding', 'Unsupported GIfTI encoding: %s', result.Encoding);
end

if ~strcmpi(result.Encoding, 'ASCII')
    expectedBytes = expectedCount * bytesPerValue;
    if numel(bytes) ~= expectedBytes
        error('BNV:IO:GiftiValueCountMismatch', ...
            'GIfTI binary array contains %d bytes; expected %d.', numel(bytes), expectedBytes);
    end
    values = typecast(bytes(:), matlabClass);
    [~, ~, hostEndian] = computer;
    hostIsLittle = hostEndian == 'L';
    if strcmpi(result.Endian, 'BigEndian')
        shouldSwap = hostIsLittle;
    elseif strcmpi(result.Endian, 'LittleEndian')
        shouldSwap = ~hostIsLittle;
    elseif bytesPerValue > 1
        error('BNV:IO:UnsupportedGiftiEndian', 'Unsupported GIfTI endian value: %s', result.Endian);
    else
        shouldSwap = false;
    end
    if shouldSwap && bytesPerValue > 1
        values = swapbytes(values);
    end
    values = double(values(:));
end

if strcmpi(result.ArrayIndexingOrder, 'RowMajorOrder')
    if isscalar(dimensions)
        value = reshape(values, dimensions(1), 1);
    else
        value = permute(reshape(values, fliplr(dimensions)), numel(dimensions):-1:1);
    end
elseif strcmpi(result.ArrayIndexingOrder, 'ColumnMajorOrder')
    shape = dimensions;
    if isscalar(shape)
        shape(2) = 1;
    end
    value = reshape(values, shape);
else
    error('BNV:IO:UnsupportedGiftiIndexOrder', ...
        'Unsupported GIfTI ArrayIndexingOrder: %s', result.ArrayIndexingOrder);
end
result.Value = value;
end


function [bytes, offset, hash] = readExternalBytes(node, baseFolder, relativeName, expectedBytes)
if strlength(relativeName) == 0
    error('BNV:IO:MissingGiftiExternalFile', ...
        'ExternalFileBinary requires a nonempty ExternalFileName.');
end
try
    portable = brainnet.core.InputReference("surface", replace(relativeName, "\", "/"));
catch exception
    error('BNV:IO:UnsafeGiftiExternalPath', ...
        'Unsafe GIfTI ExternalFileName %s: %s', relativeName, exception.message);
end
externalPath = string(fullfile(baseFolder, replace(portable.RelativePath, "/", filesep)));
canonicalBase = string(char(java.io.File(char(baseFolder)).getCanonicalPath()));
canonicalExternal = string(char(java.io.File(char(externalPath)).getCanonicalPath()));
basePrefix = canonicalBase + string(filesep);
if ~startsWith(lower(canonicalExternal), lower(basePrefix))
    error('BNV:IO:UnsafeGiftiExternalPath', ...
        'GIfTI external arrays must remain within the GIfTI file folder.');
end
if ~isfile(canonicalExternal)
    error('BNV:IO:InputNotFound', 'GIfTI external data file does not exist: %s', relativeName);
end
offsetText = string(char(node.getAttribute('ExternalFileOffset')));
if strlength(offsetText) == 0
    offset = 0;
else
    offset = str2double(offsetText);
end
if ~isfinite(offset) || offset < 0 || offset ~= fix(offset)
    error('BNV:IO:InvalidGiftiExternalOffset', ...
        'GIfTI ExternalFileOffset must be a nonnegative integer.');
end
fileId = fopen(canonicalExternal, 'r');
if fileId < 0
    error('BNV:IO:InputOpenFailed', 'Unable to open GIfTI external data file.');
end
cleanup = onCleanup(@() fclose(fileId));
if fseek(fileId, offset, 'bof') ~= 0
    error('BNV:IO:InvalidGiftiExternalOffset', 'Unable to seek to GIfTI external data offset.');
end
bytes = fread(fileId, expectedBytes, '*uint8');
if numel(bytes) ~= expectedBytes
    error('BNV:IO:GiftiValueCountMismatch', ...
        'GIfTI external array contains fewer than the required %d bytes at offset %d.', expectedBytes, offset);
end
hash = brainnet.io.internal.sha256File(canonicalExternal);
end


function systems = readCoordinateSystems(node)
nodes = node.getElementsByTagName('CoordinateSystemTransformMatrix');
systems = cell(nodes.getLength(), 1);
for index = 1:nodes.getLength()
    current = nodes.item(index - 1);
    sourceNodes = current.getElementsByTagName('DataSpace');
    targetNodes = current.getElementsByTagName('TransformedSpace');
    matrixNodes = current.getElementsByTagName('MatrixData');
    if sourceNodes.getLength() ~= 1 || targetNodes.getLength() ~= 1 || matrixNodes.getLength() ~= 1
        error('BNV:IO:InvalidGiftiCoordinateSystem', ...
            'GIfTI coordinate systems require DataSpace, TransformedSpace, and MatrixData.');
    end
    matrixValues = sscanf(char(matrixNodes.item(0).getTextContent()), '%f');
    if numel(matrixValues) ~= 16 || any(~isfinite(matrixValues))
        error('BNV:IO:InvalidGiftiCoordinateSystem', ...
            'GIfTI MatrixData must contain 16 finite values.');
    end
    value = struct;
    value.DataSpace = string(char(sourceNodes.item(0).getTextContent()));
    value.TransformedSpace = string(char(targetNodes.item(0).getTextContent()));
    value.Matrix = reshape(matrixValues, 4, 4).';
    systems{index} = value;
end
end


function bytes = inflateBytes(compressed)
temporaryPath = string(tempname);
stream = [];
fileId = -1;
try
    input = java.io.ByteArrayInputStream(typecast(uint8(compressed(:)), 'int8'));
    stream = java.util.zip.InflaterInputStream(input);
    target = java.io.File(char(temporaryPath)).toPath();
    options = javaArray('java.nio.file.CopyOption', 0);
    javaMethod('copy', 'java.nio.file.Files', stream, target, options);
    stream.close();
    stream = [];
    fileId = fopen(temporaryPath, 'r');
    if fileId < 0
        error('BNV:IO:GiftiDecompressionFailed', 'Unable to open temporary decompressed GIfTI data.');
    end
    bytes = fread(fileId, Inf, '*uint8');
    fclose(fileId);
    fileId = -1;
    delete(temporaryPath);
catch exception
    if fileId >= 0
        fclose(fileId);
    end
    if ~isempty(stream)
        stream.close();
    end
    if isfile(temporaryPath)
        delete(temporaryPath);
    end
    error('BNV:IO:GiftiDecompressionFailed', ...
        'Unable to decompress GIfTI GZipBase64Binary data: %s', exception.message);
end
end

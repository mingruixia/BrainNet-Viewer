function volume = readNifti(reference, rootPath)
%READNIFTI Read NIfTI-1/2 single-file or paired data without SPM.

arguments
    reference (1, 1) brainnet.core.InputReference
    rootPath (1, 1) string
end

selectedPath = brainnet.io.internal.resolveAndVerify(reference, rootPath, "volume");
[headerSource, dataSource, isPair, headerRelative, dataRelative] = ...
    resolveSources(reference, rootPath, selectedPath);

headerTemporary = "";
dataTemporary = "";
headerId = -1;
dataId = -1;
try
    [headerPath, headerTemporary] = prepareInput(headerSource);
    if isPair
        [dataPath, dataTemporary] = prepareInput(dataSource);
    else
        dataPath = headerPath;
    end
    [headerId, version, endianness, machineFormat] = openHeader(headerPath);
    if isPair
        dataId = fopen(dataPath, 'r', machineFormat);
        if dataId < 0
            error('BNV:IO:InputOpenFailed', 'Unable to open paired NIfTI image data.');
        end
    else
        dataId = headerId;
    end
catch exception
    closeInputs(headerId, dataId, headerTemporary, dataTemporary);
    rethrow(exception);
end
inputCleanup = onCleanup(@() closeInputs(headerId, dataId, headerTemporary, dataTemporary));

header = parseHeader(headerId, version);
validateHeader(header, version, isPair);
[precision, expectedBitpix] = brainnet.io.internal.niftiDatatype(header.DatatypeCode);
if header.Bitpix ~= expectedBitpix
    error('BNV:IO:NiftiBitpixMismatch', ...
        'NIfTI bitpix %d does not match datatype code %d.', header.Bitpix, header.DatatypeCode);
end

elementCount = prod(header.Dimensions);
if ~isfinite(elementCount) || elementCount > flintmax
    error('BNV:IO:InvalidNiftiDimensions', 'NIfTI dimensions exceed the supported element count.');
end
if fseek(dataId, header.VoxOffset, 'bof') ~= 0
    error('BNV:IO:InvalidNiftiOffset', 'Unable to seek to the NIfTI image data.');
end
raw = fread(dataId, elementCount, ['*' precision]);
if numel(raw) ~= elementCount
    error('BNV:IO:TruncatedNiftiData', ...
        'NIfTI image contains %d values; expected %d.', numel(raw), elementCount);
end
data = double(raw);
if header.ScaleSlope ~= 0
    data = data * header.ScaleSlope + header.ScaleIntercept;
end
reshapeDimensions = header.Dimensions;
if isscalar(reshapeDimensions)
    reshapeDimensions(2) = 1;
end
data = reshape(data, reshapeDimensions);

header.Endianness = endianness;
header.MachineFormat = machineFormat;
header.DatatypeClass = precision;
header.IsPair = isPair;
header.HeaderRelativePath = headerRelative;
header.DataRelativePath = dataRelative;
if isPair
    header.HeaderSha256 = brainnet.io.internal.sha256File(headerSource);
    header.DataSha256 = brainnet.io.internal.sha256File(dataSource);
else
    header.HeaderSha256 = brainnet.io.internal.sha256File(selectedPath);
    header.DataSha256 = header.HeaderSha256;
end
[affine, affineZeroBased, method] = brainnet.io.internal.niftiAffine(header);
header.AffineMethod = method;
volume = brainnet.io.VolumeData(data, header, affine, affineZeroBased, reference);
end


function [headerSource, dataSource, isPair, headerRelative, dataRelative] = ...
        resolveSources(reference, rootPath, selectedPath)
relative = reference.RelativePath;
lowerRelative = lower(relative);
isHeader = endsWith(lowerRelative, ".hdr") || endsWith(lowerRelative, ".hdr.gz");
isImage = endsWith(lowerRelative, ".img") || endsWith(lowerRelative, ".img.gz");
isPair = isHeader || isImage;
if ~isPair
    headerSource = selectedPath;
    dataSource = selectedPath;
    headerRelative = relative;
    dataRelative = relative;
    return;
end

if isfield(reference.Metadata, 'PairRelativePath')
    companionRelative = string(reference.Metadata.PairRelativePath);
else
    companionRelative = pairedRelativePath(relative, isHeader);
end
pairSha256 = "";
if isfield(reference.Metadata, 'PairSha256')
    pairSha256 = string(reference.Metadata.PairSha256);
end
companion = brainnet.core.InputReference("volume", companionRelative, Sha256=pairSha256);
companionPath = brainnet.io.internal.resolveAndVerify(companion, rootPath, "volume");
if isHeader
    headerSource = selectedPath;
    dataSource = companionPath;
    headerRelative = relative;
    dataRelative = companionRelative;
else
    headerSource = companionPath;
    dataSource = selectedPath;
    headerRelative = companionRelative;
    dataRelative = relative;
end
end


function companion = pairedRelativePath(relative, sourceIsHeader)
text = char(relative);
compressed = endsWith(lower(relative), ".gz");
if compressed
    stem = text(1:end - 7);
    suffix = ".gz";
else
    stem = text(1:end - 4);
    suffix = "";
end
if sourceIsHeader
    companion = string(stem) + ".img" + suffix;
else
    companion = string(stem) + ".hdr" + suffix;
end
end


function header = parseHeader(fileId, version)
if version == 1
    dimensionsRaw = readAt(fileId, 40, 8, 'int16=>double', version);
    intentParameters = readAt(fileId, 56, 3, 'single=>double', version).';
    intentCode = readAt(fileId, 68, 1, 'int16=>double', version);
    description = readAt(fileId, 148, 80, '*char', version).';
    datatypeCode = readAt(fileId, 70, 1, 'int16=>double', version);
    bitpix = readAt(fileId, 72, 1, 'int16=>double', version);
    pixdim = readAt(fileId, 76, 8, 'single=>double', version).';
    voxOffset = readAt(fileId, 108, 1, 'single=>double', version);
    scaleSlope = readAt(fileId, 112, 1, 'single=>double', version);
    scaleIntercept = readAt(fileId, 116, 1, 'single=>double', version);
    qformCode = readAt(fileId, 252, 1, 'int16=>double', version);
    sformCode = readAt(fileId, 254, 1, 'int16=>double', version);
    quaternion = readAt(fileId, 256, 3, 'single=>double', version).';
    qoffset = readAt(fileId, 268, 3, 'single=>double', version).';
    sformRows = [readAt(fileId, 280, 4, 'single=>double', version).'; ...
                 readAt(fileId, 296, 4, 'single=>double', version).'; ...
                 readAt(fileId, 312, 4, 'single=>double', version).'];
    magic = readAt(fileId, 344, 4, '*char', version).';
else
    dimensionsRaw = readAt(fileId, 16, 8, 'int64=>double', version);
    intentParameters = readAt(fileId, 80, 3, 'double=>double', version).';
    intentCode = readAt(fileId, 504, 1, 'int32=>double', version);
    description = readAt(fileId, 240, 80, '*char', version).';
    datatypeCode = readAt(fileId, 12, 1, 'int16=>double', version);
    bitpix = readAt(fileId, 14, 1, 'int16=>double', version);
    pixdim = readAt(fileId, 104, 8, 'double=>double', version).';
    voxOffset = readAt(fileId, 168, 1, 'int64=>double', version);
    scaleSlope = readAt(fileId, 176, 1, 'double=>double', version);
    scaleIntercept = readAt(fileId, 184, 1, 'double=>double', version);
    qformCode = readAt(fileId, 344, 1, 'int32=>double', version);
    sformCode = readAt(fileId, 348, 1, 'int32=>double', version);
    quaternion = readAt(fileId, 352, 3, 'double=>double', version).';
    qoffset = readAt(fileId, 376, 3, 'double=>double', version).';
    sformRows = [readAt(fileId, 400, 4, 'double=>double', version).'; ...
                 readAt(fileId, 432, 4, 'double=>double', version).'; ...
                 readAt(fileId, 464, 4, 'double=>double', version).'];
    magic = readAt(fileId, 4, 8, '*char', version).';
end

dimensionCount = dimensionsRaw(1);
if dimensionCount < 1 || dimensionCount > 7 || dimensionCount ~= fix(dimensionCount)
    error('BNV:IO:InvalidNiftiDimensions', 'NIfTI dimension count must be an integer from 1 through 7.');
end
dimensions = dimensionsRaw(2:dimensionCount + 1).';
if any(dimensions < 1) || any(dimensions ~= fix(dimensions))
    error('BNV:IO:InvalidNiftiDimensions', 'NIfTI dimensions must be positive integers.');
end

header = struct;
header.Version = version;
header.Description = string(strtrim(description(description ~= char(0))));
header.IntentCode = intentCode;
header.IntentParameters = intentParameters;
header.Dimensions = dimensions;
header.PixelDimensions = abs(pixdim(2:dimensionCount + 1));
header.DatatypeCode = datatypeCode;
header.Bitpix = bitpix;
header.VoxOffset = voxOffset;
header.ScaleSlope = scaleSlope;
header.ScaleIntercept = scaleIntercept;
header.QFormCode = qformCode;
header.SFormCode = sformCode;
header.Quaternion = quaternion;
header.QOffset = qoffset;
header.QFac = pixdim(1);
header.SFormRows = sformRows;
header.Magic = string(magic(1:3));
header.RawPixelDimensions = pixdim;
end


function validateHeader(header, version, isPair)
singleMagic = "n+" + string(version);
pairMagic = "ni" + string(version);
if isPair && header.Magic ~= pairMagic
    error('BNV:IO:InvalidNiftiMagic', 'Paired NIfTI-%d input requires magic %s.', version, pairMagic);
elseif ~isPair && header.Magic ~= singleMagic
    error('BNV:IO:InvalidNiftiMagic', 'Single-file NIfTI-%d input requires magic %s.', version, singleMagic);
end
minimumOffset = 0;
if ~isPair
    if version == 1
        minimumOffset = 352;
    else
        minimumOffset = 544;
    end
end
if ~isfinite(header.VoxOffset) || header.VoxOffset < minimumOffset || header.VoxOffset ~= fix(header.VoxOffset)
    error('BNV:IO:InvalidNiftiOffset', ...
        'NIfTI-%d vox_offset must be an integer of at least %d for this storage mode.', version, minimumOffset);
end
relevantPixelDimensions = header.RawPixelDimensions(2:min(4, numel(header.Dimensions) + 1));
if any(~isfinite(header.RawPixelDimensions)) || any(relevantPixelDimensions == 0)
    error('BNV:IO:InvalidNiftiPixelDimensions', 'NIfTI pixel dimensions must be finite and nonzero.');
end
if ~isfinite(header.ScaleSlope) || ~isfinite(header.ScaleIntercept)
    error('BNV:IO:InvalidNiftiScaling', 'NIfTI scaling fields must be finite.');
end
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
    error('BNV:IO:NiftiDecompressionFailed', 'Unable to decompress NIfTI input: %s', exception.message);
end
if isempty(outputs) || ~isfile(outputs{1})
    removeTemporaryFolder(folder);
    error('BNV:IO:NiftiDecompressionFailed', 'NIfTI decompression produced no file.');
end
pathValue = string(outputs{1});
end


function [fileId, version, endianness, machineFormat] = openHeader(pathValue)
fileId = fopen(pathValue, 'r', 'ieee-le');
if fileId < 0
    error('BNV:IO:InputOpenFailed', 'Unable to open NIfTI header.');
end
headerSize = fread(fileId, 1, 'int32=>double');
if headerSize == 348 || headerSize == 540
    version = 1 + (headerSize == 540);
    endianness = "little";
    machineFormat = "ieee-le";
    return;
end
fclose(fileId);
fileId = fopen(pathValue, 'r', 'ieee-be');
if fileId < 0
    error('BNV:IO:InputOpenFailed', 'Unable to reopen NIfTI header.');
end
headerSize = fread(fileId, 1, 'int32=>double');
if headerSize ~= 348 && headerSize ~= 540
    fclose(fileId);
    error('BNV:IO:InvalidNiftiHeader', 'NIfTI sizeof_hdr must equal 348 or 540.');
end
version = 1 + (headerSize == 540);
endianness = "big";
machineFormat = "ieee-be";
end


function value = readAt(fileId, offset, count, precision, version)
if fseek(fileId, offset, 'bof') ~= 0
    error('BNV:IO:TruncatedNiftiHeader', 'Unable to seek within the NIfTI-%d header.', version);
end
value = fread(fileId, count, precision);
if numel(value) ~= count
    expectedSize = 348 + 192 * (version == 2);
    error('BNV:IO:TruncatedNiftiHeader', 'NIfTI-%d header ended before byte %d.', version, expectedSize);
end
end


function closeInputs(headerId, dataId, headerFolder, dataFolder)
if dataId >= 0 && dataId ~= headerId
    fclose(dataId);
end
if headerId >= 0
    fclose(headerId);
end
removeTemporaryFolder(dataFolder);
if headerFolder ~= dataFolder
    removeTemporaryFolder(headerFolder);
end
end


function removeTemporaryFolder(folder)
if strlength(folder) > 0 && isfolder(folder)
    rmdir(folder, 's');
end
end

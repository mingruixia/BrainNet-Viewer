function [precision, expectedBitpix] = niftiDatatype(code)
%NIFTIDATATYPE Map supported NIfTI-1 datatype codes to MATLAB fread types.

switch code
    case 2
        precision = 'uint8'; expectedBitpix = 8;
    case 4
        precision = 'int16'; expectedBitpix = 16;
    case 8
        precision = 'int32'; expectedBitpix = 32;
    case 16
        precision = 'single'; expectedBitpix = 32;
    case 64
        precision = 'double'; expectedBitpix = 64;
    case 256
        precision = 'int8'; expectedBitpix = 8;
    case 512
        precision = 'uint16'; expectedBitpix = 16;
    case 768
        precision = 'uint32'; expectedBitpix = 32;
    case 1024
        precision = 'int64'; expectedBitpix = 64;
    case 1280
        precision = 'uint64'; expectedBitpix = 64;
    otherwise
        error('BNV:IO:UnsupportedNiftiDatatype', ...
            'NIfTI-1 datatype code %d is not supported by this reader.', code);
end
end

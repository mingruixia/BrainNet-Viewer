function [matlabClass, bytesPerValue] = giftiDatatype(value)
%GIFTIDATATYPE Map GIfTI/NIfTI datatype names or codes to MATLAB classes.

name = upper(string(value));
switch name
    case {"NIFTI_TYPE_UINT8", "2"}
        matlabClass = 'uint8'; bytesPerValue = 1;
    case {"NIFTI_TYPE_INT16", "4"}
        matlabClass = 'int16'; bytesPerValue = 2;
    case {"NIFTI_TYPE_INT32", "8"}
        matlabClass = 'int32'; bytesPerValue = 4;
    case {"NIFTI_TYPE_FLOAT32", "16"}
        matlabClass = 'single'; bytesPerValue = 4;
    case {"NIFTI_TYPE_FLOAT64", "64"}
        matlabClass = 'double'; bytesPerValue = 8;
    case {"NIFTI_TYPE_INT8", "256"}
        matlabClass = 'int8'; bytesPerValue = 1;
    case {"NIFTI_TYPE_UINT16", "512"}
        matlabClass = 'uint16'; bytesPerValue = 2;
    case {"NIFTI_TYPE_UINT32", "768"}
        matlabClass = 'uint32'; bytesPerValue = 4;
    case {"NIFTI_TYPE_INT64", "1024"}
        matlabClass = 'int64'; bytesPerValue = 8;
    case {"NIFTI_TYPE_UINT64", "1280"}
        matlabClass = 'uint64'; bytesPerValue = 8;
    otherwise
        error('BNV:IO:UnsupportedGiftiDatatype', 'Unsupported GIfTI datatype: %s', value);
end
end

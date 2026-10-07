function [affineOneBased, affineZeroBased, method] = niftiAffine(header)
%NIFTIAFFINE Decode NIfTI-1 sform/qform with explicit index conventions.

if header.SFormCode > 0
    affineZeroBased = [header.SFormRows; 0 0 0 1];
    method = "sform";
elseif header.QFormCode > 0
    b = header.Quaternion(1);
    c = header.Quaternion(2);
    d = header.Quaternion(3);
    a2 = 1 - (b * b + c * c + d * d);
    if a2 < 1e-7
        scale = 1 / sqrt(b * b + c * c + d * d);
        b = b * scale;
        c = c * scale;
        d = d * scale;
        a = 0;
    else
        a = sqrt(a2);
    end
    rotation = [ ...
        a*a+b*b-c*c-d*d, 2*b*c-2*a*d,       2*b*d+2*a*c; ...
        2*b*c+2*a*d,       a*a+c*c-b*b-d*d, 2*c*d-2*a*b; ...
        2*b*d-2*a*c,       2*c*d+2*a*b,       a*a+d*d-c*c-b*b];
    spacing = ones(1, 3);
    available = min(3, numel(header.PixelDimensions));
    spacing(1:available) = abs(header.PixelDimensions(1:available));
    qfac = header.QFac;
    if qfac == 0
        qfac = 1;
    end
    affineZeroBased = eye(4);
    affineZeroBased(1:3, 1:3) = rotation * diag([spacing(1), spacing(2), spacing(3) * qfac]);
    affineZeroBased(1:3, 4) = header.QOffset(:);
    method = "qform";
else
    spacing = ones(1, 3);
    available = min(3, numel(header.PixelDimensions));
    spacing(1:available) = abs(header.PixelDimensions(1:available));
    affineZeroBased = diag([spacing, 1]);
    method = "fallback-pixdim";
end

if any(~isfinite(affineZeroBased), 'all')
    error('BNV:IO:InvalidAffine', 'NIfTI spatial transform contains non-finite values.');
end
affineOneBased = affineZeroBased;
affineOneBased(1:3, 4) = affineZeroBased(1:3, 4) - affineZeroBased(1:3, 1:3) * ones(3, 1);
end

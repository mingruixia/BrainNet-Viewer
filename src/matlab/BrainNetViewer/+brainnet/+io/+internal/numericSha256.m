function hex = numericSha256(value)
%NUMERICSHA256 Match the G0 numeric-array fingerprint definition.

digest = java.security.MessageDigest.getInstance('SHA-256');
metadata = [class(value) ':' sprintf('%dx', size(value))];
digest.update(typecast(uint8(unicode2native(metadata, 'UTF-8')), 'int8'));
if ~isempty(value)
    if islogical(value)
        bytes = uint8(value(:));
    elseif ischar(value)
        bytes = typecast(uint16(value(:)), 'uint8');
    else
        bytes = typecast(value(:), 'uint8');
    end
    digest.update(typecast(bytes, 'int8'));
end
raw = typecast(int8(digest.digest()), 'uint8');
hex = string(lower(reshape(dec2hex(raw, 2).', 1, [])));
end

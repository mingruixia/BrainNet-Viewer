function hex = sha256File(pathValue)
%SHA256FILE Compute a lowercase SHA-256 digest with bounded memory.

fid = fopen(char(pathValue), 'rb');
if fid < 0
    error('BNV:IO:InputOpenFailed', 'Cannot open input file: %s', pathValue);
end
cleanup = onCleanup(@() fclose(fid));
digest = java.security.MessageDigest.getInstance('SHA-256');
while true
    bytes = fread(fid, 1024 * 1024, '*uint8');
    if isempty(bytes)
        break;
    end
    digest.update(typecast(bytes, 'int8'));
end
raw = typecast(int8(digest.digest()), 'uint8');
hex = string(lower(reshape(dec2hex(raw, 2).', 1, [])));
end

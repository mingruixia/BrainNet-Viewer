function hex = sha256Text(value)
%SHA256TEXT Return a lowercase SHA-256 digest for UTF-8 text.

arguments
    value (1, 1) string
end
digest = java.security.MessageDigest.getInstance('SHA-256');
bytes = unicode2native(char(value), 'UTF-8');
digest.update(typecast(uint8(bytes), 'int8'));
raw = typecast(int8(digest.digest()), 'uint8');
hex = string(lower(reshape(dec2hex(raw, 2).', 1, [])));
end

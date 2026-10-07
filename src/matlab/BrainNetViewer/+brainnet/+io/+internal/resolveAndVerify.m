function pathValue = resolveAndVerify(reference, rootPath, expectedRole)
%RESOLVEANDVERIFY Resolve a portable input and enforce role and checksum.

arguments
    reference (1, 1) brainnet.core.InputReference
    rootPath (1, 1) string
    expectedRole (1, 1) string
end
if reference.Role ~= expectedRole
    error('BNV:IO:InputRoleMismatch', 'Expected %s input, received %s.', expectedRole, reference.Role);
end
pathValue = reference.resolve(rootPath);
if ~isfile(pathValue)
    error('BNV:IO:InputNotFound', 'Input file does not exist: %s', reference.RelativePath);
end
if strlength(reference.Sha256) > 0
    actual = brainnet.io.internal.sha256File(pathValue);
    if actual ~= reference.Sha256
        error('BNV:IO:ChecksumMismatch', 'SHA-256 mismatch for input: %s', reference.RelativePath);
    end
end
end

function writeJsonFile(destination, value, options)
%WRITEJSONFILE Publish UTF-8 JSON through a temporary file in the same folder.
arguments
    destination (1, 1) string
    value
    options.Overwrite (1, 1) logical = false
end
[folder, ~, extension] = fileparts(destination);
if lower(extension) ~= ".json"
    error('BNV:IO:JsonExtension', 'The destination must have a .json extension.');
end
if folder == "", folder = string(pwd); end
if ~isfolder(folder)
    error('BNV:IO:OutputFolderMissing', 'Output folder does not exist: %s', folder);
end
if isfolder(destination)
    error('BNV:IO:DestinationIsFolder', 'The JSON destination is a folder: %s', destination);
end
if isfile(destination) && ~options.Overwrite
    error('BNV:IO:OutputExists', 'Output exists; use Overwrite=true: %s', destination);
end
temporary = string(tempname(folder)) + ".json";
cleanup = onCleanup(@() removeTemporary(temporary));
file = fopen(temporary, 'w', 'n', 'UTF-8');
if file < 0
    error('BNV:IO:WriteFailed', 'Cannot write JSON in: %s', folder);
end
try
    count = fprintf(file, '%s', jsonencode(value, PrettyPrint=true));
    status = fclose(file);
catch exception
    fclose(file);
    rethrow(exception);
end
if count <= 0 || status ~= 0
    error('BNV:IO:WriteFailed', 'Could not finish writing JSON.');
end
if ~options.Overwrite && isfile(destination)
    error('BNV:IO:OutputExists', 'Output was created by another writer: %s', destination);
end
if options.Overwrite
    [ok, message] = movefile(temporary, destination, 'f');
else
    [ok, message] = movefile(temporary, destination);
end
if ~ok, error('BNV:IO:WriteFailed', '%s', message); end
end

function removeTemporary(path)
if isfile(path), delete(path); end
end

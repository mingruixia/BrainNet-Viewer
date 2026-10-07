classdef BoundaryMask
    %BOUNDARYMASK Strict binary masks bound to ordered surface geometry.
    methods (Static)
        function mask=validate(mask)
            if ~(isnumeric(mask)||islogical(mask)) || ~isreal(mask) || ...
                    (~isempty(mask)&&~isvector(mask)) || numel(mask)>5000000 || any(~isfinite(mask),'all') || ...
                    any(mask~=0 & mask~=1,'all')
                error('BNV:Boundary:InvalidMask','A mask must contain at most 5 million binary vertex values.');
            end
            mask=reshape(double(mask),1,[]);
        end
        function hash=signature(coordinates,faces)
            % Keep the core contract independent of I/O and graphics packages.
            text=arrayDigest(double(coordinates))+":"+arrayDigest(double(faces));
            digest=java.security.MessageDigest.getInstance('SHA-256');
            digest.update(typecast(uint8(unicode2native(char(text),'UTF-8')),'int8'));
            hash=digestHex(digest);
        end
        function patch=bind(mask,coordinates,faces,source)
            arguments
                mask
                coordinates double
                faces double
                source (1,1) string="user-confirmed vertex order"
            end
            mask=brainnet.core.BoundaryMask.validate(mask);
            if isempty(mask)||numel(mask)~=size(coordinates,2)
                error('BNV:Boundary:MaskSize','Mask length must match the original surface vertex count.');
            end
            patch=struct('boundary_mode','custom','boundary_mask',mask, ...
                'boundary_mesh_sha256',char(brainnet.core.BoundaryMask.signature(coordinates,faces)), ...
                'boundary_mask_source',char(source));
        end
    end
end

function hash=arrayDigest(value)
% Same class/shape/native-byte fingerprint as the frozen numeric-array contract.
digest=java.security.MessageDigest.getInstance('SHA-256');
metadata=[class(value) ':' sprintf('%dx',size(value))];
digest.update(typecast(uint8(unicode2native(metadata,'UTF-8')),'int8'));
if ~isempty(value), digest.update(typecast(value(:),'int8')); end
hash=digestHex(digest);
end

function hash=digestHex(digest)
raw=typecast(int8(digest.digest()),'uint8');
hash=string(lower(reshape(dec2hex(raw,2).',1,[])));
end

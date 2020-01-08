function c = BrainNet_GenColormap(Nmax,Nmin,Pmin,Pmax,original_color_map)

if isempty(original_color_map)
    original_color_map = jet;
end

color_length = length(original_color_map);

if color_length < 64
    original_color_map = interp1(linspace(1,64,10),original_color_map,1:64,'nearest');
    color_length = 64;
end

k = (color_length - 1) / (Pmax - Nmax);
b = color_length - k * Pmax;

n_point = floor(k * Nmin + b);
p_point = ceil(k * Pmin + b);

color_n_point = original_color_map(floor(color_length/2),:);
color_p_point = original_color_map(floor(color_length/2+1),:);

c = ones(size(original_color_map));
c(1:n_point,:) = [linspace(original_color_map(1,1),color_n_point(1),n_point);linspace(original_color_map(1,2),color_n_point(2),n_point);linspace(original_color_map(1,3),color_n_point(3),n_point)]';
c(p_point:end,:) = [linspace(color_p_point(1),original_color_map(color_length,1),color_length - p_point + 1);linspace(color_p_point(2),original_color_map(color_length,2),color_length - p_point + 1);linspace(color_p_point(3),original_color_map(color_length,3),color_length - p_point + 1)]';

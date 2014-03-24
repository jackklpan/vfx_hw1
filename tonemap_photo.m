function [TMpic_global, TMpic_local] = tonemap_photo( HDRpic )
%% color pre-process  (try to find a way that wont have weird single color)

%% parameters
a_global = 0.7;
L_white = 200;
epsilon = 0.001;
a_local = 1.6;
phi = 10;
s_max = 1000;
gauss_min = 0.00001;

L = 0.2999 * HDRpic(:, :, 1) + 0.587 * HDRpic(:, :, 2) + 0.114 * HDRpic(:, :, 3);
sizeL = size (L);

%% Global Operator
L_w = exp (sum (sum (log (0.001 + L))) / (sizeL(1) * sizeL(2)));
L_m = (a_global / L_w) * L;
L_d = L_m .* (1 + L_m / (L_white^2)) ./ (1 + L_m);

ratio = L_d ./ L;
TMpic_global(:, :, 1) = ratio .* HDRpic(:, :, 1);
TMpic_global(:, :, 2) = ratio .* HDRpic(:, :, 2);
TMpic_global(:, :, 3) = ratio .* HDRpic(:, :, 3);

%% Local Operator (L_d as input)

win = 1;

L_d2 = zeros (sizeL(1), sizeL(2));
not_done = zeros (sizeL(1), sizeL(2)) + 1;

G = fspecial ('gaussian',  [win win], 1);
while G(1, 1) > gauss_min
    win = win + 2;
    G = fspecial ('gaussian',  [win win], 1);
end
L_blur_s = imfilter(L_d, G);

for s = 2:s_max
    if isempty(not_done)
        break;
    end
    
    G = fspecial ('gaussian',  [win win], s);
    while G(1, 1) > gauss_min
        win = win + 2;
        G = fspecial ('gaussian',  [win win], s);
    end
    L_blur_s1 = imfilter(L_d, G);
    
    delta = abs ((L_blur_s - L_blur_s1) ./ (((2^phi) * a_local) / (s^2) + L_blur_s));
    delta = (delta > epsilon) & not_done;
    
    if ~isempty (delta)
        L_d2 = L_d2 + (L_d .* delta) ./ (1 + L_blur_s);
    end
    
    not_done = ~L_d2;
    L_blur_s = L_blur_s1;    

    s
end

if ~isempty(not_done)
    L_d2 = L_d2 + (L_d .* not_done) ./ (1 + L_blur_s1);
end
%% output

ratio = L_d2 ./ L;
TMpic_local(:, :, 1) = ratio .* HDRpic(:, :, 1);
TMpic_local(:, :, 2) = ratio .* HDRpic(:, :, 2);
TMpic_local(:, :, 3) = ratio .* HDRpic(:, :, 3);


end

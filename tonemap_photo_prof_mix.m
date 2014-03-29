function TMpic = tonemap_photo_prof_mix (HDRpic)
%%  Structure
%  

%% parameters
a = 0.5;
%L_white =1000;
epsilon = 0.001;
phi = 25;
i = 0;
init = 1;
s = (1.6 ^ i ) * init;
win = 1;
gauss_min = 0.000000001;
sig = 0.35;

L = 0.27 * HDRpic(:, :, 1) + 0.67 * HDRpic(:, :, 2) + 0.6 * HDRpic(:, :, 3);
sizeL = size (L);

%%  main
% Global Operator (calculate L_m, adjust intensity of whole image)

L_w = exp (sum (sum (log10 (0.00000001 + L))) / (sizeL(1) * sizeL(2)));
L_m = (a / L_w) * L;

% Local Operator (L_m as input, enhance local contrast)

L_d2 = zeros (sizeL(1), sizeL(2));
not_done = zeros (sizeL(1), sizeL(2)) + 1;

G = makeG (win, s, sig);
while (G(1, 1) > gauss_min) && win < min(sizeL)
    win = win + 2;
    G = makeG (win, s, sig);
end
L_blur_s1 = imfilter(L_m, G);

while (s < min(sizeL)) && ((sum (sum (not_done)) > sizeL(1) * sizeL(2) * 0.01)) %&& i < 8
    
    i = i + 1;
    s = (1.6 ^ i ) * init;
    
    G = makeG (win, s, sig);
    while (G(1, 1) > gauss_min) && win < min(sizeL)
        win = win + 2;
        G = makeG (win, s, sig);
    end
    L_blur_s2 = imfilter(L_m, G);
    
    delta = abs ((L_blur_s1 - L_blur_s2) ./ (((2^phi) * a) / (s^2) + L_blur_s1));
    delta = (delta > epsilon) & not_done;
    
    if ~isempty (delta)
        L_d2 = L_d2 + (L_m .* delta) ./ (1 + L_blur_s1);
    end
    
    not_done = ~L_d2;  

    s
    sum(sum(not_done))
    
end

if ~isempty(not_done)
    L_d2 = L_d2 + (L_m .* not_done) ./ (1 + L_blur_s1);
end

% Global Operator (adjust intensity distribution)

L_white = max (max (L_d2));
L_d = L_d2 .* (1 + L_d2 / (L_white^2)) ./ (1 + L_d2);

%%  output

ratio = L_d ./ L;
TMpic(:, :, 1) = ratio .* HDRpic(:, :, 1);
TMpic(:, :, 2) = ratio .* HDRpic(:, :, 2);
TMpic(:, :, 3) = ratio .* HDRpic(:, :, 3);
TMpic = (TMpic >= 1) .* 1 + (TMpic < 1) .* TMpic;

end

function G = makeG (win, s, sigma)

mid = (win + 1) / 2;
sigma_s_2 = ((s * sigma)^2);

for i = 1: win
    for j = 1: win
        x = i - mid;
        y = j - mid;
        G(i, j) = exp (-(x*x + y*y) / sigma_s_2) / (pi * sigma_s_2);
    end
end

end
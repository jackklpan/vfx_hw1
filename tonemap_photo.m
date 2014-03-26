function [TMpic_global, TMpic_local] = tonemap_photo( HDRpic )
%% color pre-process  (try to find a way that wont have weird single color)

%% parameters
a = 0.5;
L_white = 3;
epsilon = 0.01;
phi = 15;
gauss_min = 0.000000001;
cent_sur_ratio = 1.4;

L = 0.27 * HDRpic(:, :, 1) + 0.67 * HDRpic(:, :, 2) + 0.6 * HDRpic(:, :, 3);
sizeL = size (L);


%% Global Operator


L_w = exp (sum (sum (log (0.001 + L))) / (sizeL(1) * sizeL(2)));
L_m = (a / L_w) * L;
%L_white = max (max (L_m));
L_d = L_m .* (1 + L_m / (L_white^2)) ./ (1 + L_m);

ratio = L_d ./ L;
TMpic_global(:, :, 1) = ratio .* HDRpic(:, :, 1);
TMpic_global(:, :, 2) = ratio .* HDRpic(:, :, 2);
TMpic_global(:, :, 3) = ratio .* HDRpic(:, :, 3);

%% Local Operator (L_d as input)

win1 = 1;
win2 = 1;
i = 1;

L_d2 = zeros (sizeL(1), sizeL(2));
not_done = zeros (sizeL(1), sizeL(2)) + 1;

while sum (sum (not_done)) > sizeL(1) * sizeL(2) * 0.01
    
    s = 1.6 ^ (i - 1);
    i = i + 1;
    
    %G = fspecial ('gaussian',  [win1 win1], 0.25 * s);
    G = makeG (win1, s, 0.35);
    while G(1, 1) > gauss_min
        win1 = win1 + 2;
        %G = fspecial ('gaussian',  [win1 win1], 0.25 * s);
        G = makeG (win1, s, 0.35);
    end
    L_blur_s1 = imfilter(L_d, G);
    
    %G = fspecial ('gaussian',  [win2 win2], 1.6 * 1.6 * 0.25 * s);
    G = makeG (win2, s, cent_sur_ratio * 0.35);
    while G(1, 1) > gauss_min
        win2 = win2 + 2;
        %G = fspecial ('gaussian',  [win2 win2], 1.6 * 1.6 * 0.25 * s);
        G = makeG (win2, s, cent_sur_ratio * 0.35);
    end
    L_blur_s2 = imfilter(L_d, G);
    
    delta = abs ((L_blur_s1 - L_blur_s2) ./ (((2^phi) * a) / (s^2) + L_blur_s1));
    delta = (delta > epsilon) & not_done;
    
    if ~isempty (delta)
        L_d2 = L_d2 + (L_d .* delta) ./ (1 + L_blur_s1);
    end
    
    not_done = ~L_d2;  

    s
    sum(sum(not_done))
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

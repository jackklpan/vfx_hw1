function [TMpic_global, TMpic_local] = tonemap_photo( HDRpic )
%% parameters
a_global = 0.5;
L_white = 10;
epsilon = 1;
a_local = 1.6;
phi = 10;

%{
H = rgb2ycbcr (HDRpic);
L = H (:, :, 1);
%}

L = 0.2999 * HDRpic(:, :, 1) + 0.587 * HDRpic(:, :, 2) + 0.114 * HDRpic(:, :, 3);

sizeL = size (L);

%% Global Operator
L_w = exp (sum (sum (log (0.001 + L))) / (sizeL(1) * sizeL(2)));
L_m = (a_global / L_w) * L;
L_d = L_m .* (1 + L_m / (L_white^2)) ./ (1 + L_m);

%{
H (:, :, 1) = L_d;
TMpic_global = ycbcr2rgb (H);
%}
% every pixel have a v_max
%{
        v_max = max ([reshape(HDRpic(:, :, 1), 1, (sizeL(1) * sizeL(2))); reshape(HDRpic(:, :, 2), 1, (sizeL(1) * sizeL(2))); reshape(HDRpic(:, :, 3), 1, (sizeL(1) * sizeL(2)))]);
        v_max = reshape(v_max, sizeL(2), sizeL(1));
        v_max = v_max';
        t = HDRpic(:, :, 1) ./ v_max;
        u = HDRpic(:, :, 2) ./ v_max;
        v = HDRpic(:, :, 3) ./ v_max;
        w_max = L_d ./ (0.2999 * t + 0.587 * u + 0.114 * v);
        w_red = t .* w_max;
        w_green = u .* w_max;
        w_blue = v .* w_max;
%}


ratio = L_d ./ L;
TMpic_global(:, :, 1) = ratio .* HDRpic(:, :, 1);
TMpic_global(:, :, 2) = ratio .* HDRpic(:, :, 2);
TMpic_global(:, :, 3) = ratio .* HDRpic(:, :, 3);

%% Local Operator (L_d as input)

L_d2 = zeros (sizeL(1), sizeL(2));

for x = 1: sizeL(1)
    for y = 1: sizeL(2)
       s = 1;
       L_blur_s = blur (L_d, x, y, s);
       L_blur_s1 = blur (L_d, x, y, s + 1);
       while abs((L_blur_s - L_blur_s1) / (((2^phi) * a_local) / (s^2) + L_blur_s)) < epsilon
           L_blur_s = L_blur_s1;
           s = s + 1;
           L_blur_s1 = blur (L_d, x, y, s + 1);          
       end
       L_d2(x, y) = L_d(x, y) / (1 + L_blur_s);
    end
end
%% output
%{
H (:, :, 1) = L_d2;
TMpic_local = ycbcr2rgb (H);
%}

ratio = L_d2 ./ L;
TMpic_local(:, :, 1) = ratio .* HDRpic(:, :, 1);
TMpic_local(:, :, 2) = ratio .* HDRpic(:, :, 2);
TMpic_local(:, :, 3) = ratio .* HDRpic(:, :, 3);


end

function L_out = blur (L_in, x, y, scale)

sizeL = size (L_in);
if mod (sizeL(1), 2) == 0
    sizeL(1) = sizeL(1) + 1;
    L_in = [L_in; zeros(1, sizeL(2))];
end
if mod (sizeL(2), 2) == 0
    sizeL(2) = sizeL(2) + 1;
    L_in = [L_in zeros(sizeL(1), 1)];
end

G = fspecial ('gaussian',  [sizeL(1) sizeL(2)], scale);
mid = (sizeL + 1) / 2;
T = maketform ('affine', [1 0 0;  0 1 0; (y - mid(1)) (x - mid(2)) 1]);
G = imtransform (G, T, 'XData', [1 size(G, 2)], 'YData', [1 size(G, 1)]);
L_out = sum (sum (L_in .* G));

end
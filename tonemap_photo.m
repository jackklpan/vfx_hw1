function TMpic = tonemap_photo( HDRpic )

a = 0.5;
L_white = 2;

H = rgb2ycbcr (HDRpic);
L = H (:, :, 1);
sizeL = size (L);

%% Global Operator
L_w = exp (sum (sum (log (0.001 + L))) / (sizeL(1) * sizeL(2)));
L_m = (a / L_w) * L;
L_d = L_m .* (1 + L_m / (L_white^2)) ./ (1 + L_m);



%% output
H (:, :, 1) = L_d;
TMpic = ycbcr2rgb (H);


end
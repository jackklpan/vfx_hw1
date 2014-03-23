function [TMpic_global, TMpic_local] = tonemap_photo( HDRpic )
%% parameters
a_global = 0.5;
L_white = 10;
epsilon = 1;
a_local = 1.6;
phi = 10;
s_max = 20;

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

L_d2 = zeros (sizeL(1), sizeL(2));
L_blur_s = zeros (sizeL(1), sizeL(2));
win = 1;

for x = 1: sizeL(1)
    for y = 1:sizeL(2)
        G_temp = fspecial ('gaussian',  [win win], 1);
        while G_temp(1, 1) > 0.01
            win = win + 2;
            G_temp = fspecial ('gaussian',  [win win], 1);
        end
        win_half = (win + 1) / 2;
        patch_cen(1) = x - win_half + 1;
        patch_cen(2) = y - win_half + 1;
        
        if x < win_half
            Tx = maketform ('affine', [1 0 0; 0 1 0; (x - win_half) 0 1]);
            G_temp = imtransform (G_temp, Tx, 'XData', [1 win], 'YData', [1 win]);
            G_temp = G_temp / sum ( sum (G_temp));
            
            patch_cen(1) = 1;
        elseif (sizeL(1) - x) < win_half
            Tx = maketform ('affine', [1 0 0; 0 1 0; (-(sizeL(1) - x) + win_half) 0 1]);
            G_temp = imtransform (G_temp, Tx, 'XData', [1 win], 'YData', [1 win]);
            G_temp = G_temp / sum ( sum (G_temp));
            
            patch_cen(1) = sizeL(1) - (win_half - 1) * 2 ;
        end
        if y < win_half
            Ty = maketform ('affine', [1 0 0; 0 1 0; 0 (y - win_half) 1]);
            G_temp = imtransform (G_temp, Ty, 'XData', [1 win], 'YData', [1 win]);
            G_temp = G_temp / sum ( sum (G_temp));
            
            patch_cen(2) = 1;
        elseif (sizeL(2) - y) < win_half
            Ty = maketform ('affine', [1 0 0; 0 1 0; 0 (-(sizeL(2) - y) + win_half) 1]);
            G_temp = imtransform (G_temp, Ty, 'XData', [1 win], 'YData', [1 win]);
            G_temp = G_temp / sum ( sum (G_temp));
            
            patch_cen(2) = sizeL(2) - (win_half - 1) * 2;
        end
        
        patch(:, :) = L_d(patch_cen(1): (patch_cen(1) + (win_half - 1) * 2), patch_cen(2): (patch_cen(2) + (win_half - 1) * 2));
        L_blur_s(x, y) = sum (sum (patch .* G_temp));
    end
end

for s = 2: s_max
    G = fspecial ('gaussian',  [win win], s);
    while G(1, 1) > 0.01
        win = win + 2;
        G = fspecial ('gaussian',  [win win], s);
    end
    win_half = (win + 1) / 2;
    
    for x = 1: sizeL(1)
        for y = 1: sizeL(2)
            if L_d2 ~= 0
                continue;
            end
            
            G_temp = G;
            patch_cen(1) = x - win_half + 1;
            patch_cen(2) = y - win_half + 1;
            
            if x < win_half
                Tx = maketform ('affine', [1 0 0; 0 1 0; (x - win_half) 0 1]);
                G_temp = imtransform (G_temp, Tx, 'XData', [1 win], 'YData', [1 win]);
                G_temp = G_temp / sum ( sum (G_temp));
                
                patch_cen(1) = 1;
            elseif (sizeL(1) - x) < win_half
                Tx = maketform ('affine', [1 0 0; 0 1 0; (-(sizeL(1) - x) + win_half) 0 1]);
                G_temp = imtransform (G_temp, Tx, 'XData', [1 win], 'YData', [1 win]);
                G_temp = G_temp / sum ( sum (G_temp));
                
                patch_cen(1) = sizeL(1) - (win_half - 1) * 2 ;
            end
            if y < win_half
                Ty = maketform ('affine', [1 0 0; 0 1 0; 0 (y - win_half) 1]);
                G_temp = imtransform (G_temp, Ty, 'XData', [1 win], 'YData', [1 win]);
                G_temp = G_temp / sum ( sum (G_temp));
                
                patch_cen(2) = 1;
            elseif (sizeL(2) - y) < win_half
                Ty = maketform ('affine', [1 0 0; 0 1 0; 0 (-(sizeL(2) - y) + win_half) 1]);
                G_temp = imtransform (G_temp, Ty, 'XData', [1 win], 'YData', [1 win]);
                G_temp = G_temp / sum ( sum (G_temp));
                
                patch_cen(2) = sizeL(2) - (win_half - 1) * 2;
            end
            
            patch(:, :) = L_d(patch_cen(1): (patch_cen(1) + (win_half - 1) * 2), patch_cen(2): (patch_cen(2) + (win_half - 1) * 2));
            L_blur_s1 = patch .* G_temp;
            
            if abs((L_blur_s(x, y) - L_blur_s1) / (((2^phi) * a_local) / (s^2) + L_blur_s(x, y))) < epsilon
                L_blur_s(x, y) = L_blur_s1;
            else
                L_d2(x, y) = L_d(x, y) / (1 + L_blur_s);
            end
        end
    end
end
%% output

ratio = L_d2 ./ L;
TMpic_local(:, :, 1) = ratio .* HDRpic(:, :, 1);
TMpic_local(:, :, 2) = ratio .* HDRpic(:, :, 2);
TMpic_local(:, :, 3) = ratio .* HDRpic(:, :, 3);

end
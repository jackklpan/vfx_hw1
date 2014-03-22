%img1, img2 = grayscale image
%shift_bits = times
%shift_ref = x,y shift in vector
function [shift_ref_output] = alignment( img1, img2, shift_bits, tolerance )
  if shift_bits > 0
    img1_shrink = imresize(img1, 0.5);
    img2_shrink = imresize(img2, 0.5);
    shift_ref_output = alignment(img1_shrink, img2_shrink, shift_bits-1, tolerance);
    cur_shift(1) = shift_ref_output(1)*2;
    cur_shift(2) = shift_ref_output(2)*2;
  else
    cur_shift = zeros(1,2);
  end
  
  img_size = size(img1);
  img1_median = median(reshape(img1, 1, img_size(1)*img_size(2)));
  img2_median = median(reshape(img2, 1, img_size(1)*img_size(2)));
  img1_thresholding = im2bw(img1, double(img1_median)/255);
  img2_thresholding = im2bw(img2, double(img2_median)/255);
 
  upper_bound = img1_median+tolerance;
  lower_bound = img1_median-tolerance;
  img1_exclusion = (img1>=upper_bound) | (img1<=lower_bound);
  upper_bound = img2_median+tolerance;
  lower_bound = img2_median-tolerance;
  img2_exclusion = (img2>=upper_bound) | (img2<=lower_bound);
  
  min_err = img_size(1)*img_size(2);
  for i=-1:1
      for j=-1:1
          xs = cur_shift(1)+i;
          ys = cur_shift(2)+j;
          T = maketform('affine', [1 0 0; 0 1 0; i j 1]);
          img2_shift_thresholding = imtransform(img2_thresholding, T, 'XData',[1 size(img2_thresholding,2)], 'YData',[1 size(img2_thresholding,1)]);
          img2_shift_exclusion = imtransform(img2_exclusion, T, 'XData',[1 size(img2_exclusion,2)], 'YData',[1 size(img2_exclusion,1)]);
          diff_b = xor(img1_thresholding, img2_shift_thresholding);
          diff_b = diff_b & img1_exclusion;
          diff_b = diff_b & img2_shift_exclusion;
          error = sum(sum(diff_b));
          if error<min_err
              shift_ref_output(1) = xs;
              shift_ref_output(2) = ys;
              min_err = error;
          end
      end
  end
end

% files = dir('./images/*.png');
%   for i=1:length(files)
%     pic = imread(['./images/',files(i).name]);
%     picSize = size (pic);
%     pic = imresize(pic, 0.5);
%   end
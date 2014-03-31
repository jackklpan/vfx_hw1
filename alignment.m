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
  
  [upper_bound1, lower_bound1, img1_median, upper_bound2, lower_bound2, img2_median] = getGoodThreshloding(img1, img2, tolerance);
  img1_exclusion = (img1>=upper_bound1) | (img1<=lower_bound1);
  img1_thresholding = im2bw(img1, double(img1_median)/255);
  img2_exclusion = (img2>=upper_bound2) | (img2<=lower_bound2);
  img2_thresholding = im2bw(img2, double(img2_median)/255);
  
  min_err = img_size(1)*img_size(2);
  for i=-1:1
      for j=-1:1
          xs = cur_shift(1)+i;
          ys = cur_shift(2)+j;
          T = maketform('affine', [1 0 0; 0 1 0; xs ys 1]);
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

function [upper_bound1, lower_bound1, thresholding1, upper_bound2, lower_bound2, thresholding2] = getGoodThreshloding(img1, img2, tolerance)
  thresholding1 = prctile(img1(:),50.5);
  thresholding2 = prctile(img2(:),50.5);

  percent = 50.5;
  upper_bound1 = prctile(img1(:),percent)+tolerance;
  upper_bound2 = prctile(img2(:),percent)+tolerance;
  while(upper_bound2 >= 255 && percent > 1)
     percent = percent/2;
     upper_bound1 = prctile(img1(:),percent)+tolerance;
     upper_bound2 = prctile(img2(:),percent)+tolerance;
  end
  if(percent ~= 50)
      thresholding1 = prctile(img1(:),percent);
      thresholding2 = prctile(img2(:),percent);
      lower_bound1 = prctile(img1(:),percent)-tolerance;
      lower_bound2 = prctile(img2(:),percent)-tolerance;
      return;
  end
  
  percent = 50.5;
  lower_bound1 = prctile(img1(:),percent)-tolerance;
  lower_bound2 = prctile(img2(:),percent)-tolerance;
  while(lower_bound2 <= 0 && percent < 99)
     percent = percent+percent/2;
     lower_bound1 = prctile(img1(:),percent)-tolerance;
     lower_bound2 = prctile(img2(:),percent)-tolerance;
  end
  if(percent ~= 50)
      thresholding1 = prctile(img1(:),percent);
      thresholding2 = prctile(img2(:),percent);
      upper_bound1 = prctile(img1(:),percent)+tolerance;
      upper_bound2 = prctile(img2(:),percent)+tolerance;
      return;
  end
  
end

% files = dir('./images/*.png');
%   for i=1:length(files)
%     pic = imread(['./images/',files(i).name]);
%     picSize = size (pic);
%     pic = imresize(pic, 0.5);
%   end
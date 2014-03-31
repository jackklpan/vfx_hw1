clear all;
%%
%params
do_alignment = true;
use_exposure_file = false;

file_path = './test_case3/';
image_name = '*.jpg';
output_file_path = './output_clip/';
exposure_file_name = 'exposures1.txt';

tolerance = 1; %for alignemnt

%%
%init
files = dir([file_path, image_name]);

%%
%alignment images
if do_alignment
  img1_for_alignment = rgb2gray(imread([file_path, files(1).name]));
  img2_for_alignment = rgb2gray(imread([file_path, files(2).name]));
    
  fprintf('alignment for image 2\n');
  multi_scale = int32(log2( max( size(img1_for_alignment) ) )) - 5;
  shift = [0 0; alignment(img1_for_alignment, img2_for_alignment, multi_scale, tolerance)];
    
  for i=3:length(files)
      fprintf('alignment for image %d\n', i);
        
      img1_for_alignment = img2_for_alignment;
      img2_for_alignment = rgb2gray(imread([file_path, files(i).name]));
        
      %local shift is the shift between last images and this images, shift is
      %the shift between first images and this images
      shift_local = alignment(img1_for_alignment, img2_for_alignment, multi_scale, tolerance);
      last_shift = shift(i-1,:);
      shift = [ shift; [last_shift(1)+shift_local(1) last_shift(2)+shift_local(2)] ];
  end
  
  max_x = (max(shift(:,1))>0).*max(shift(:,1)); % >0 is max, otherwise is 0
  min_x = (min(shift(:,1))<0).*min(shift(:,1));
  max_y = (max(shift(:,2))>0).*max(shift(:,2));
  min_y = (min(shift(:,2))<0).*min(shift(:,2));
  for i=1:length(files)
      origin_pic = imread([file_path, files(i).name]);
      now_shift = shift(i,:);
      T = maketform('affine', [1 0 0; 0 1 0; now_shift(1) now_shift(2) 1]);
      pic_alignment_tmp = imtransform(origin_pic, T, 'XData',[1 size(origin_pic,2)], 'YData',[1 size(origin_pic,1)]);
      picSize = size(pic_alignment_tmp);
      pic_alignment(:,:,:,i) = imcrop(pic_alignment_tmp, [max_x+1, max_y+1, picSize(2)+min_x-1, picSize(1)+min_y-1]);
  end
  %write clip image to disk
  if ~exist(output_file_path, 'dir')
      mkdir(output_file_path);
  else
      rmdir(output_file_path, 's');
      mkdir(output_file_path);
  end
  for i=1:length(files)
      imwrite(pic_alignment(:,:,:,i) ,[output_file_path, files(i).name], 'jpg', 'Quality', 100);
  end
  
else
  output_file_path = file_path;
end

files = dir([output_file_path, image_name]);

clear pic_alignment;
clear pic_alignment_tmp;
clear img1_for_alignment;
clear img2_for_alignment;
clear origin_pic;
%%
%get intensity value from image samples
Z1 = []; %intensity for R
Z2 = []; %intensity for G
Z3 = []; %intensity for B
denseX = 37; % vertical
denseY = 41; % horizontal

for i=1:length(files)
  pic = imread([output_file_path, files(i).name]);
  picSize = size (pic);
  
  xOffset = int16(picSize(1) / 8);
  yOffset = int16(picSize(2) / 8);  
  row = int16((picSize(1) - 2 * xOffset) / (denseX + 1));
  col = int16((picSize(2) - 2 * yOffset) / (denseY + 1));
  
  R = [];
  G = [];
  B = [];
  for x = 1: denseX
      for y = 1: denseY
          R = [R; pic(xOffset + x * row, yOffset + y * col, 1)];
          G = [G; pic(xOffset + x * row, yOffset +y * col, 2)];
          B = [B; pic(xOffset + x * row, yOffset +y * col, 3)];
      end
  end
  Z1 = [Z1 R];
  Z2 = [Z2 G];
  Z3 = [Z3 B];
end

%%
%get shutterSpeed from file
if use_exposure_file
    fileID = fopen ([file_path, exposure_file_name]);
    expo = textscan (fileID, '%f');
    expo = expo{1,1};
    shutterSpeed = reshape (log (1 ./ expo), 1, length(expo));
    for i = 2: denseX * denseY
        shutterSpeed(i, :) = shutterSpeed(1, :);
    end
    fclose(fileID);
else
    shutterSpeed = [];
    for i=1:length(files)
        pic_info = imfinfo([file_path, files(i).name]);
        exposure_time = pic_info.DigitalCamera.ExposureTime;
        shutterSpeed = [shutterSpeed log(exposure_time)];
    end
    for i = 2: denseX * denseY
        shutterSpeed(i, :) = shutterSpeed(1, :);
    end
end

%%
%solve least-square function
[g1, lnE] = gsolve (Z1, shutterSpeed, 47, @pptFunc);
[g2, lnE] = gsolve (Z2, shutterSpeed, 47, @pptFunc);
[g3, lnE] = gsolve (Z3, shutterSpeed, 47, @pptFunc);

%%
%weight average the hdr image from all images and g functions
tmpR = zeros(picSize(1), picSize(2));
tmpG = zeros(picSize(1), picSize(2));
tmpB = zeros(picSize(1), picSize(2));

weightR = zeros(picSize(1), picSize(2));
weightG = zeros(picSize(1), picSize(2));
weightB = zeros(picSize(1), picSize(2));

for i=1:length(files)
    pic = imread([output_file_path, files(i).name]);
    picSize = size (pic);
    
    tmpR = tmpR + pptFunc( pic(:,:,1)+1) .* ( g1(pic(:,:,1)+1)-shutterSpeed(1, i) );
    weightR = weightR + pptFunc( pic(:,:,1)+1 );
    
    tmpG = tmpG + pptFunc( pic(:,:,2)+1) .* ( g2(pic(:,:,2)+1)-shutterSpeed(1, i) );
    weightG = weightG + pptFunc( pic(:,:,2)+1);
    
    tmpB = tmpB + pptFunc( pic(:,:,3)+1) .* ( g3(pic(:,:,3)+1)-shutterSpeed(1, i) );
    weightB = weightB + pptFunc( pic(:,:,3)+1);
    
end

tmpR = tmpR./weightR;
tmpG = tmpG./weightG;
tmpB = tmpB./weightB;

HDRpic(:,:,1) = tmpR;
HDRpic(:,:,2) = tmpG;
HDRpic(:,:,3) = tmpB;
HDRpic = exp(HDRpic);

clearvars  -except HDRpic g1 g2 g3;

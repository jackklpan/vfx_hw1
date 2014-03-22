%%

files = dir('./exposures/*.jpg');

Z1 = [];
Z2 = [];
Z3 = [];
denseX = 37; % vertical
denseY = 31; % horizontal

for i=1:length(files)
  pic = imread(['./exposures/',files(i).name]);
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

fileID = fopen ('./exposures/exposures1.txt');
expo = textscan (fileID, '%f');
expo = expo{1,1};
shutterSpeed = reshape (log (1 ./ expo), 1, length(expo));
for i = 2: denseX * denseY
    shutterSpeed(i, :) = shutterSpeed(1, :);
end
fclose(fileID);

%%

[g1, lnE] = gsolve (Z1, shutterSpeed, 47, @pptFunc);
[g2, lnE] = gsolve (Z2, shutterSpeed, 47, @pptFunc);
[g3, lnE] = gsolve (Z3, shutterSpeed, 47, @pptFunc);
  
tmpR = zeros(picSize(1), picSize(2));
tmpG = zeros(picSize(1), picSize(2));
tmpB = zeros(picSize(1), picSize(2));

weightR = zeros(picSize(1), picSize(2));
weightG = zeros(picSize(1), picSize(2));
weightB = zeros(picSize(1), picSize(2));

for i=1:length(files)
    pic = imread(['./exposures/',files(i).name]);
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

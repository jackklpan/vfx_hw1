%%

files = dir('./images/*.png');

Z1 = [];
Z2 = [];
Z3 = [];
denseX = 37; % vertical
denseY = 31; % horizontal

for i=1:length(files)
  pic = imread(['./images/',files(i).name]);
  picSize = size (pic);
  
  row = int16(picSize (1) / (denseX + 1));
  col = int16(picSize (2) / (denseY + 1));
  
  R = [];
  G = [];
  B = [];
  for x = 1: denseX
      for y = 1: denseY
          R = [R; pic(x * row, y * col, 1)];
          G = [G; pic(x * row, y * col, 2)];
          B = [B; pic(x * row, y * col, 3)];
      end
  end
  Z1 = [Z1 R];
  Z2 = [Z2 G];
  Z3 = [Z3 B];
end

%%

fileID = fopen ('./images/exposures1.txt');
expo = textscan (fileID, '%f');
expo = expo{1,1};
shutterSpeed = reshape (log (1 ./ expo), 1, length(expo));
for i = 2: denseX * denseY
    shutterSpeed(i, :) = shutterSpeed(1, :);
end
fclose(fileID);

%%

[g1, lnE] = gsolve (Z1, shutterSpeed, 47, @logFunc);
[g2, lnE] = gsolve (Z2, shutterSpeed, 47, @logFunc);
[g3, lnE] = gsolve (Z3, shutterSpeed, 47, @logFunc);
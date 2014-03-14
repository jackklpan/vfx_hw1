%%

files = dir('./images/*.png');
Z = [];
denseX = 17; % vertical
denseY = 13; % horizontal

for i=1:length(files)
  pic = imread(['./images/',files(i).name]);
  picSize = size (pic);
  
  row = int16(picSize (1) / (denseX + 1));
  col = int16(picSize (2) / (denseY + 1));
  
  R = [];
  for x = 1: denseX
      for y = 1: denseY
          R = [R; pic(x * row, y * col, 1)];
      end
  end
  Z = [Z R];
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

[g, lnE] = gsolve (Z, shutterSpeed, 37, @weightFunc);
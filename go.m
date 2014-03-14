%%

files = dir('./images/*.png');
Z = [];
for i=1:length(files)
  pic = imread(['./images/',files(i).name]);
  picSize = size (pic);
  R = reshape (pic(:,:,1), picSize(1) * picSize(2), 1);
  Z = [Z R];
end

%%

fileID = fopen ('./images/exposures1.txt');
expo = textscan (fileID, '%f');
expo = expo{1,1};
shutterSpeed = log (1 ./ expo);
fclose(fileID);

%%

[g, lnE] = gsolve (Z, shutterSpeed, 37, @weightFunc);
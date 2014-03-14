files = dir('./images/*.png');
Z = [];
for i=1:length(files)
  pic = imread(['./images/',files(i).name]);
  R = pic(:,:,1);
  Z = [Z R];
end
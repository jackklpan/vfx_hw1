function [ weight ] = pptFunc( input )
  zmin = 1;
  zmax = 256;
  if input<=(1/2)*(zmin+zmax)
      weight = double(input - zmin);
  else
      weight = double(zmax - input);
  end
end
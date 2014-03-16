function [ weight ] = pptFunc( input )
  zmin = 1;
  zmax = 256;
  if input<=(1/2)*(zmin+zmax)
      weight = double(input - zmin+1).^2;
  else
      weight = double(zmax - input+1).^2;
  end
end


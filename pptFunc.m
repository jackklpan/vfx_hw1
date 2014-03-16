function [ weight ] = pptFunc( input )
  zmin = 1;
  zmax = 256;
  if input<=(1/2)*(zmin+zmax)
      weight = input - zmin+1;
  else
      weight = zmax - input+1;
  end
end


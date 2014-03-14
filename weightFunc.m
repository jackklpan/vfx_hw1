function [ weight ] = weightFunc( input )
  zmin = 1;
  zmax = 256;
  if input<=(1/2)*(zmin+zmax)
      weight = input-zmin;
  else
      weight = zmax-input;
  end
end


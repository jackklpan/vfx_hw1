function [ weight ] = weightFunc( input )
  zmin = 0;
  zmax = 255;
  if input<=(1/2)*(zmin+zmax)
      weight = input-zmin;
  else
      weight = zmax-input;
  end
end


function [ weight ] = weightFunc( input, zmin, zmax )
  if input<=(1/2)*(zmin+zmax)
      weight = input-zmin;
  else
      weight = zmax-input;
  end
end


function [ weight ] = logFunc( input )
  zmin = 1;
  zmax = 256;
  if input<=(1/2)*(zmin+zmax)
      weight = log (double(input - zmin + exp(1)));
  else
      weight = log (double(zmax - input + exp(1)));
  end
end


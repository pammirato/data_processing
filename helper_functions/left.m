function [isleft] = left(a,b,c)
%returns 1 if point c is left of the line through a and b

  slope = (a(2) - b(2)) / (a(1) - b(1));

  intercept = a(2) - (a(1) * slope);

  c_liney = c(1)*slope + intercept;


  isleft = 1;
  if(c_liney > c(2))
    isleft = 0;
  end 

end

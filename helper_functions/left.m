function [isleft] = left(a,b,c)
%returns 1 if point c is left of the line through a and b

  isleft = 0;
  if(area2(a,b,c) > 0)
    isleft = 1;
  end

end

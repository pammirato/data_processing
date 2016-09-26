function [isleft] = left(a,b,c)
%returns 1 if point c is left of the directed line through a to b

  isleft = 0;
  if(area2(a,b,c) > 0)
    isleft = 1;
  end

end

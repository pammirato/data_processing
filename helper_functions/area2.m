function [twice_area] = area2(a, b, c)
%returns twice the signed area of the triangle defined by 2D points a,b,c.
%sign is positive if a, b, and c are in counter clockwise order

  first = (b(1) - a(1)) * (c(2) - a(2));
  second = (c(1) - a(1)) * (b(2) - a(2));
  twice_area = first - second;
end

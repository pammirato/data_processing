function [twice_area] = area2(a, b, c)

  first = (b(1) - a(1)) * (c(2) - a(2));
  second = (c(1) - a(1)) * (b(2) - a(2));

  twice_area = first - second;

end

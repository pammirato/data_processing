function [isin] = is_point_in_box(box, point)
%returns true if the 2d point, point, is inside the 2d rectangle, box.
%box should be [xmin, ymin, xmax, ymax]



  xin = point(1) > box(1) && point(1) < box(3);

  yin = point(2) > box(2) && point(2) < box(4);

  isin = xin && yin;


end

function [angle] = angle_between_directions_2D(img_struct1, img_struct2)
%return the angle between the direction vectors of the two structs

  %convert the direction verctors to 2 dimensions
  dir1 = get_normalized_2D_vector(img_struct1.direction);
  dir2 = get_normalized_2D_vector(img_struct2.direction);

  %compute the angle between them using dot product
  angle = acosd(dot(dir1,dir2)); 
end% angle 2d



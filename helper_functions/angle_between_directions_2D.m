function [angle] = angle_between_directions_2D(cam_struct1, cam_struct2)

  dir1 = get_2d_normed_vector(cam_struct1.direction);
  dir2 = get_2d_normed_vector(cam_struct2.direction);

  angle = acosd(dot(dir1,dir2)); 
end% angle 2d





function [vec] = get_2d_normed_vector(vec_3d)
  vec = vec_3d([1 3]);
  vec = vec / norm(vec);
end

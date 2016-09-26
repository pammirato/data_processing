function [vec] = get_normalized_2D_vector(vec_3d)
%takes 3D vector and returms 2D normalized vector of 1st and 3rd dimensions
  vec = vec_3d([1 3]);
  vec = vec / norm(vec);
end

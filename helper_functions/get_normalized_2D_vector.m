function [vec] = get_normalized_2D_vector(vec_3d)
  vec = vec_3d([1 3]);
  vec = vec / norm(vec);
end

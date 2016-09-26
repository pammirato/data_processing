function [struct_distance] = distance_between_structs(struct1, struct2, dimensions)
% returns the scaled distance between the cameras stored in two image structs  
%
% optional argument 'dimensions' - vector to select which of the 3 position dimensions to use

  %get the positions
  pos1 = struct1.scaled_world_pos; 
  pos2 = struct2.scaled_world_pos; 

  %reduce the dimensions if the caller asked for it  
  if(exist('dimensions','var'))
    pos1 = pos1(dimensions);
    pos2 = pos2(dimensions);
  end

  struct_distance = sqrt( sum( (pos1-pos2).^2));
end%function

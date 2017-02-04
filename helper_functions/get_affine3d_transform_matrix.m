function [tform] = get_affine3d_transfor_matrix(axis_name,rotation_angle)



  mat = [];
  ra = rotation_angle * pi/180;

  if(strcmp(axis_name,'x'))
    mat = [1        0        0        0; ...
           0        cos(ra)  sin(ra)  0; ...
           0        -sin(ra) cos(ra)  0; ...
           0        0        0        1];

  elseif(strcmp(axis_name,'y'))
    mat = [cos(ra)  0        -sin(ra) 0; ...
           0        1        0        0; ...
           sin(ra)  0        cos(ra)  0; ...
           0        0        0        1];
  elseif(strcmp(axis_name,'z'))
    mat = [cos(ra)  sin(ra)  0        0; ...
           -sin(ra) cos(ra)  0        0; ...
           0        0        1        0; ...
           0        0        0        1];

  end

  tform = affine3d(mat);

end%function


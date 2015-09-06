function pt = camera_to_3d(camera_pt, depth, focal_length)

  pt = -ones(1,3);


  pt(1,1) = camera_pt(1,1) * depth / focal_length;
  pt(1,2) = camera_pt(1,2) * depth / focal_length;
  pt(1,3) = depth;



end%function

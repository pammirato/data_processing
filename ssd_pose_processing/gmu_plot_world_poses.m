
world_poses = zeros(3,length(image_structs));
for il=1:length(image_structs)
  R = image_structs(il).Rw2c;
  t = image_structs(il).Tw2c';
  
  
  world_poses(:,il) = -R'*t;
end


plot3(world_poses(1,:), world_poses(2,:), world_poses(3,:), 'r.');

world_poses = [useful_structs.world_pos];
dirs = [useful_structs.direction];


hold off;
plot(world_poses(1,:),world_poses(3,:),'r.');
hold on;
quiver(world_poses(1,:),world_poses(3,:), ... 
             dirs(1,:),dirs(3,:), ... 
             'ShowArrowHead','on','Color' ,'b');

plot(cur_pos(1), cur_pos(2), 'k.', 'MarkerSize', 30);

cdir = cur_image_struct.direction;
quiver(cur_pos(1,:),cur_pos(2,:), ... 
             cdir(1,:),cdir(3,:), ... 
             'ShowArrowHead','on','Color' ,'m');


plot(centroid(1), centroid(2), 'rd', 'MarkerSize', 30);

axis equal

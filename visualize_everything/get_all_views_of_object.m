function views = get_all_views_of_object(image_name, x, y)
  init;
  userData = get(gcf,'UserData');

  occlusion_threshold = 200;

  % get the depth image
  scene_path = userData.scene_path;
  depth_name = [image_name(1:9) '3.png'];
  depth_image = imread(fullfile(userData.scene_path, ['raw_depth/' depth_name]));
  depth = double(depth_image(floor(y),floor(x)));

  % if there is no depth information for this pixel, don't highlight any views
  if (depth < 1)
    views = [];
    return;
  end

  %size of rgb image in pixels
  kImageWidth = 1920;
  kImageHeight = 1080;

  %distance from kinects in mm
  kDistanceK1K2 = 291;
  kDistanceK2K3 = 272;

  %set intrinsic matrices for each kinect
  intrinsic1 = [ 1.0700016292741097e+03, 0., 9.2726881773877119e+02; 0.,1.0691225545678490e+03, 5.4576099988165549e+02; 0., 0., 1. ];
  intrinsic2 = [  1.0582854982177009e+03, 0., 9.5857576622458146e+0; 0., 1.0593799583771420e+03, 5.3110874137837084e+02; 0., 0., 1. ];
  intrinsic3 = [ 1.0630462958838500e+03, 0., 9.6260473585485727e+02; 0., 1.0636103172708376e+03, 5.3489949221354482e+02; 0., 0., 1.];

  names = userData.names;
  camera_struct_map = userData.name_to_camera_struct;
  scale = userData.scale;

  %for the given pixel, find all views that can see the corresponding point
  pixel = floor([x y])';

  %%%%%%%%%%% CONVERT POINT FROM PIXELS TO WORLD COORDINATES %%%%%%%%%%%%%%%

  %get the data for the labeled image
  camera_struct = camera_struct_map(image_name);

  K = intrinsic1;
  t = camera_struct.(TRANSLATION_VECTOR);
  R = camera_struct.(ROTATION_MATRIX);
  C = camera_struct.(SCALED_WORLD_POSITION);
  t = t*scale;
  world_coords = R' * depth * pinv(K) *  [pixel;1] - R'*t;

  %%%%%%%%%%%%% FIND IMAGES THAT SEE THAT 3D Point   %%%%%%%%%%%%%%%%

  found_indices = cell(0);
  found_image_names = cell(0);
  found_points = cell(0);

  %for each possible image, see if it contains the labeled point
  for i=1:length(names)
    cur_name = names{i};
    cur_camera_struct = camera_struct_map(cur_name);

    %get rotation matrix
    R = cur_camera_struct.(ROTATION_MATRIX);

    %translation vector
    t = cur_camera_struct.(TRANSLATION_VECTOR);
    t = t * scale;

    %re-orient the point to see if it is viewable by this camera
    P = [R t];
    oriented_point = P * [world_coords;1];
    %make sure z is positive
    if(oriented_point(3) < 0)
      continue;
    end

    %project the world point onto this image
    M = K * [R t];
    cur_image_point = M * [world_coords;1];

    %acccount for homogenous coords
    cur_image_point = cur_image_point / cur_image_point(3);
    cur_image_point = cur_image_point(1:2);

    %make sure the point is in the image
    if(cur_image_point(1) < 1 ||  cur_image_point(2) < 1 || ...
      cur_image_point(1) > kImageWidth || cur_image_point(2) > kImageHeight)
      continue;
    end

    %%%%%% OCCLUSION  %%%%%%
    %make sure distance from camera to world_coords is similar to depth of
    %projected point in the depth image

    %get the depth image
    % suffix_index = strfind(cur_name,'b') + 1;
    % depth_image = imread(fullfile(scene_path, ['raw_depth/raw_depth' cur_name(suffix_index:end)] ));
    %
    % cur_depth = depth_image(floor(cur_image_point(2)), floor(cur_image_point(1)));
    % camera_pos = cur_camera_struct.(SCALED_WORLD_POSITION);
    % world_dist = pdist2(camera_pos', world_coords');
    %
    % %if the depth == 0, then keep this image as we can't tell
    % if(abs(world_dist - cur_depth) > occlusion_threshold  && cur_depth >0)
    %   continue;
    % end

    found_indices{length(found_indices)+1} = i;
    found_image_names{length(found_image_names)+1} = cur_name;
    % found_points{length(found_points)+1} = [cur_image_point' cur_depth];
  end

  views = cell2mat(found_indices);
end

% This version of get_all_views takes forever but I'll leave it here just in
% case it needs to come back
% function views = get_all_views_of_object(points)
%   userData = get(gcf, 'UserData');
%   subplot(2,2,1);
%
%   % get 3D bounding box containing all points in the cluster
%   Xmin = min(points(:,1));
%   Xmax = max(points(:,1));
%   Ymin = min(points(:,2));
%   Ymax = max(points(:,2));
%   Zmin = min(points(:,3));
%   Zmax = max(points(:,3));
%
%   views = [];
%
%   % find indicies of all views that can see a point in the 3D bounding box
%   names = userData.names;
%   for i=1:length(names)
%     point_id_data = userData.name_to_point_ids(names{i});
%     for j=3:3:length(point_id_data)
%       if point_id_data(j) > 0
%         pt = userData.id_to_point(point_id_data(j));
%           if (pt(1) >= Xmin && pt(1) <= Xmax && pt(2) >= Ymin && pt(2) <= Ymax && pt(3) >= Zmin && pt(3) <= Zmax)
%             views = [views; i];
%             break;
%           end
%       end
%     end
%   end
%
% end

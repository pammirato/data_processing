%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object

%TODO -get rid of image structs map. Just use indexes. (Make it sorted?)


%clearvars;

%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


label_to_process = 'advil_liqui_gels'; %make 'all' for every label
label_names = {label_to_process};



method = 0; %0 - ideal oclusion filtering, not implemented
            %1 - no ocllusion filtering
            %2 - very strict occlusion filtering, size filter



do_occlusion_filtering = 1;
occlusion_threshold = 100;  %make > 12000 to remove occlusion thresholding
occlusion_threshold_far = -500;

use_global_pc = 0;
use_color_check = 0;


count = 0;

debug =1;

kinect_to_use = 1;

%size of rgb image in pixels
kImageWidth = 1920;
kImageHeight = 1080;



%% SET UP GLOBAL DATA STRUCTURES


%get the names of all the scenes
d = dir(ROHIT_BASE_PATH);
d = d(3:end);
all_scenes = {d.name};


%determine which scenes are to be processed 
if(use_custom_scenes && ~isempty(custom_scenes_list))
  %if we are using the custom list of scenes
  all_scenes = custom_scenes_list;
elseif(~strcmp(scene_name, 'all'))
  %if not using custom, or all scenes, use the one specified
  all_scenes = {scene_name};
end




%% MAIN LOOP

for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %get the names of all the labels
  if(strcmp(label_to_process, 'all'))
    label_names = get_names_of_X_for_scene(scene_name, 'instance_labels');
  end




  %% get camera info
  fid_camera =  fopen(fullfile(meta_path,'reconstruction_results', group_name, ...
                                'colmap_results', model_number,'cameras.txt'));

 
  %the camera follows this camera model from opencv
  % http://docs.opencv.org/master/db/d58/group__calib3d__fisheye.html#gsc.tab=0 


  %skip the file header
  line = fgetl(fid_camera);
  line = fgetl(fid_camera);
  line = fgetl(fid_camera);
  line = fgetl(fid_camera);

  %split the line with the camera parameters
  line = strsplit(line);

  K = zeros(3); %camera intrinsic matrix
  distortion = zeros(1,4);%distortion parameters

  %set the camera intrinsic paramters from the file
  K(1,1) = str2double(line{5});
  K(1,3) = str2double(line{7});
  K(2,2) = str2double(line{6});
  K(2,3) = str2double(line{8});
  K(3,3) = 1;

  %set the camera distortion paramters from the file
  distortion(1) = str2double(line{9});
  distortion(2) = str2double(line{10});
  distortion(3) = str2double(line{11});
  distortion(4) = str2double(line{12});


  fclose(fid_camera);


  %% get info about camera position for each image
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', group_name, ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;

  %remove image structs that were not reconstructed. These will be hand labeled
  no_R_inds = cellfun('isempty', {image_structs.R});
  no_R_structs = image_structs(no_R_inds);
  image_structs = image_structs(~no_R_inds);

  %get a list of all the image file names
  image_names = {image_structs.(IMAGE_NAME)};

  %make a map from image name to image_struct
  image_structs_map = containers.Map(image_names,...
                                 cell(1,length(image_names)));
  %populate the map
  for jl=1:length(image_names)
    image_structs_map(image_names{jl}) = image_structs(jl);
  end


  %% make struct for holding the labels (bounding boxes) for each label in each image

  %make a blank struct with an empty box for each label
  %the field is the label name, the value for that field is the box
  blank_struct = struct();
  blank_struct.image_name = '';
  for jl=1:length(label_names)
    blank_struct.(label_names{jl}) = []; 
  end

  %make a struct array of the empty label struct made above. One struct per image in this scene
  label_structs = repmat(blank_struct, length(image_structs), 1);



  %% occlusion filter setup
  %  ask the user if they want to preload all the depth images if occlusion filtering is on.
  %  preloading will increase speed if more than one label is being processed
 
  %whether the depths get loaded or not
  depths_loaded = 0;
  
  if(do_occlusion_filtering)

    load_depths = input('Load all depths?(y/n)' , 's');


    %load all the depths
    if((load_depths=='y'))

      %get names of all the rgb images in the scene
      %image_names = get_names_of_X_for_scene(scene_name,'rgb_images');

      %will hold all the depth images
      depth_images = cell(1,length(image_names));
      rgb_images = cell(1,length(image_names));

      %for each rgb image, load a depth image
      for jl=1:length(image_names)
          rgb_name = image_names{jl};
          
          rgb_images{jl} = imread(fullfile(scene_path, 'rgb', rgb_name));

          %depth_images{jl} = imread(fullfile(scene_path, 'filled_high_res_depth', ... 
          %         strcat(rgb_name(1:8),'04.png') ));
          %depth_images{jl} = imread(fullfile(scene_path, 'high_res_depth', ... 
          %         strcat(rgb_name(1:8),'03.png') ));
          depth_images{jl} = imread(fullfile(meta_path, 'improved_depths', ... 
                         strcat(rgb_name(1:8),'05.png') ));
      end% for i, each image name
      
      depth_img_map = containers.Map(image_names, depth_images);
      
      depths_loaded = 1;
    end%if we should load all the depths)


    %if we are told to not load the depths, see if they were already loaded
    if(load_depths == 'n')
      a = input('Are depths loaded?(y/n)' , 's');
      if(a=='y')
        depths_loaded = 1;
      end
    end
  end%if do_occlusion_filtering



  %% load the full point cloud for the entire scene
  if(use_global_pc)
    global_pc = pcread(fullfile(meta_path,'reconstruction_results', group_name, ...
                       'undistorted_images','pmvs', 'annotated_models','merged_mesh.ply'));
  end




  %% MAIN LOOP  for each label find its bounding box in each image

  %for each point cloud
  for jl=1:length(label_names)
    
    %get the name of the label
    cur_label_name = label_names{jl};
    disp(cur_label_name);

    %load the labeled point cloud for this label in this scene
    cur_pc = pcread(fullfile(meta_path,'labels', ...
                       'object_point_clouds', strcat(cur_label_name, '.ply')));
 
   
    %will hold the names of all the images that have a valid bounding box for this label
    %really just for debugging
    found_image_names = cell(1,length(image_names));

    %% for each image, determine if it 'sees' this object(point cloud) 
    for kl = 1:length(image_names) 

      %just to see how much progress is being made
      if(mod(kl,50) == 0)
        disp(cur_image_name);
      end
      
      %% get the image name, position/direction info 
      cur_image_name = image_names{kl};
      cur_image_struct = image_structs_map(cur_image_name);

      %% get the posisiton and color of the object point cloud, and the global scene point cloud
      cur_world_locs = cur_pc.Location;
      cur_color = cur_pc.Color;
    
      if(use_global_pc) 
        global_world_locs = global_pc.Location;
        global_color = global_pc.Color;
      end 

      %for debugging 
      if(strcmp(cur_image_name, '0000110101.png'))
        breakp=1;
      end
    
      %% now see what points the are in front of the camera
      % point cloud locations,  in homogenous coordinates
      cur_homog_points = [cur_world_locs ones(length(cur_world_locs), 1)]';

      if(use_global_pc) 
        global_homog_points = [global_world_locs, ones(length(global_world_locs),1)]';
      end 

      %get extrinsic parameters for this image 
      R = cur_image_struct.(ROTATION_MATRIX);
      t = cur_image_struct.(TRANSLATION_VECTOR);


      %re-orient the point clouds to see if they are viewable by this camera
      P = [R t];
      oriented_points = P * cur_homog_points;
      if(use_global_pc) 
        global_oriented_points = P * global_homog_points;
      end

      %make sure z is positive, if it is negative the point is 'behind' the image
      all_zs = oriented_points(3, :);
      bad_inds = find(all_zs < 0);  
      %remove the points with negative z values
      cur_homog_points(:, bad_inds) = []; 
      cur_world_locs(bad_inds, :) = [];
      cur_color(bad_inds, :) = [];

      %do the same for the global point cloud
      if(use_global_pc)
        global_zs = global_oriented_points(3,:);
        global_bad_inds = find(global_zs < 0);
        global_homog_points(:,global_bad_inds) = [];
        global_world_locs(global_bad_inds,:) = [];
        global_color(global_bad_inds,:) = [];
      end

      %if no points on the object are left, then the object is not in 
      %this image. Continue to the next image
      if(isempty(cur_world_locs))
        continue;
      end



  %% project the point clouds onto the image plane

  distorted_points = project_points_to_image(cur_world_locs, K, R, t, distortion);

      
%   intrinsic = K;
%   rotation = R;
%   translation = t;
%   world_points = global_world_locs;
%       
% 
%   k1 = distortion(1);
%   k2 = distortion(2);
%   k3 = distortion(3);
%   k4 = distortion(4);
% 
%   fx = intrinsic(1,1);
%   fy = intrinsic(2,2);
%   cx = intrinsic(1,3);
%   cy = intrinsic(2,3);
% 
%   R = rotation;
%   t = translation;
% 
% 
%   XC = R* world_points' + repmat(t,1,size(world_points',2));
%   a = XC(1,:) ./ XC(3,:);
%   b = XC(2,:) ./ XC(3,:);
%   
% 
%   r = sqrt( (a).^2 + (b).^2);
%   theta = atan(r);
% 
%   thetad = theta .* (1 + k1*(theta.^2) + k2*(theta.^4) + k3*(theta.^6) + k4*(theta.^8));
% 
%   xx = (thetad./r) .* a;
%   yy = (thetad./r) .* b;
% 
% 
%   u = fx*(xx + 0*yy) + cx;
%   v = fy*yy + cy;
% 
% 
%   projected_points = round([u;v]);
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      if(use_global_pc)  
        global_distorted_points = project_points_to_image(global_world_locs, K, R, t, distortion);
      end

      %get rid of points that projected outside the image bounds
      %check x values
      bad_inds =  find(distorted_points(1,:) < 1 | distorted_points(1,:) > kImageWidth);
      distorted_points(:, bad_inds) = [];
      cur_world_locs(bad_inds,:) = [];
      cur_color(bad_inds, :) = [];
      %check y values
      bad_inds =  find(distorted_points(2,:) < 1 | distorted_points(2,:) > kImageHeight);
      distorted_points(:, bad_inds) = [];
      cur_world_locs(bad_inds,:) = [];
      cur_color(bad_inds, :) = [];


      %get rid of points that projected outside the image bounds
      %check x values
      if(use_global_pc)
        bad_inds=find(global_distorted_points(1,:)<1 | global_distorted_points(1,:)>kImageWidth);
        global_distorted_points(:, bad_inds) = [];
        global_world_locs(bad_inds,:) = [];
        global_color(bad_inds,:) = [];
        
        %check y values
        bad_inds=find(global_distorted_points(2,:)<1 | global_distorted_points(2,:)>kImageHeight);
        global_distorted_points(:, bad_inds) = [];
        global_world_locs(bad_inds,:) = [];
        global_color(bad_inds,:) = [];
      end


      if(isempty(distorted_points))
        continue;
      end


      %% OCCULSION FILTERING
      %attempt to filter out images where the labeled instance is occluded
      %at the labeled point. 


      %get the position of the camera in world coordinates
      camera_pos = cur_image_struct.(WORLD_POSITION);
      cam_dir = cur_image_struct.direction;
      %make sure it is a row vector
      if(size(camera_pos,2) == 1)
        camera_pos = camera_pos';
      end



      cur_world_locs = cur_world_locs';


      %% Check for occlusion using the captures(kinect) depth image.
     
      num_points_pre_occlusion = length(distorted_points);
      minx = min(distorted_points(1,:));
      miny = min(distorted_points(2,:));
      maxx = max(distorted_points(1,:));
      maxy = max(distorted_points(2,:));
      bbox_area = (maxx - minx) * (maxy-miny);
      pre_occlusion_density = num_points_pre_occlusion / bbox_area;

 
      if(do_occlusion_filtering && method ~= 1)
        %get the depth image
        if(~depths_loaded)
          %depth_image = imread(fullfile(scene_path, 'filled_high_res_depth', ... 
           %              strcat(cur_image_name(1:8),'04.png') ));
          disp('reading depth image...');
%           depth_image = imread(fullfile(scene_path, 'high_res_depth', ... 
%                          strcat(cur_image_name(1:8),'03.png') ));
          depth_image = imread(fullfile(meta_path, 'improved_depths_2', ... 
                         strcat(cur_image_name(1:8),'05.png') ));
        else
          depth_image = depth_img_map(cur_image_name);
        end

        depths = depth_image(sub2ind(size(depth_image), ...
                               distorted_points(2,:), distorted_points(1,:)));

        zero_inds = find(depths == 0);

        %camera_pos = cur_image_struct.(SCALED_WORLD_POSITION);
       % if(size(camera_pos,2) == 1)
       %   camera_pos = camera_pos';
       % end

        scaled_world_locs = cur_world_locs.*scale;
        
        %world_dists = pdist2(camera_pos, double(scaled_world_locs)');
        %cam_to_point_vecs = cur_world_locs'*389 - repmat(camera_pos*389, size(cur_world_locs',1),1);
        cam_to_point_vecs = cur_world_locs'*scale - ...
                            repmat(camera_pos*scale, size(cur_world_locs',1),1);
        world_dists = (cam_to_point_vecs * cam_dir)';


        %only remove point if depth is less than distance, to be robust to
        %depth noise
        if(method == 0)
          dist_flags1 = double(world_dists) - double(depths) < occlusion_threshold;
          dist_flags2 = double(world_dists) - double(depths) > occlusion_threshold_far;
          dist_flags = dist_flags1 & dist_flags2;
          depth_flags = dist_flags | (depths == 0);
        elseif(method == 2)
          %strict filtering, depth must be consistent
          dist_flags = abs(double(world_dists) - double(depths)) < occlusion_threshold;
          depth_flags = dist_flags;
        end
        bad_inds = find(depth_flags == 0);
        distorted_points(:,bad_inds) = [];
        cur_color(bad_inds,:) = [];
        cur_world_locs(:,bad_inds) = [];

     end%if do occlusion

     if(length(distorted_points)<30)
        disp('too few points');
       continue;
     end

     minx = min(distorted_points(1,:));
     miny = min(distorted_points(2,:));
     maxx = max(distorted_points(1,:));
     maxy = max(distorted_points(2,:));
     bbox_area = (maxx - minx) * (maxy-miny);
     post_occlusion_density = length(distorted_points) / bbox_area;

  
      if((post_occlusion_density/pre_occlusion_density < .3))
        %disp(['too few points final: ' , num2str(length(distorted_points))]);
        disp('density too small');
        continue;
      end


      %if(length(distorted_points) < num_points_pre_occlusion*.00005)
        %disp(['too few points final: ' , num2str(length(distorted_points))]);
      %  continue;
      %end









      %% make a depth image from the global point cloud
      if(use_global_pc)
        global_world_locs = global_world_locs';
        %get distance from camera to each point
        global_dists = pdist2(camera_pos, double(global_world_locs)');

        %sort the global points based on their distsance to the camera
        global_locs_and_dists = [global_world_locs; global_dists];
        [sorted_locs_and_dists, index] = sortrows(global_locs_and_dists',4);
        
        sorted_locs_and_dists = sorted_locs_and_dists';
        sorted_global_locs = sorted_locs_and_dists(1:3, :);
        sorted_global_dists = sorted_locs_and_dists(4,:);
        sorted_global_distorted_points = global_distorted_points(:, index);
        sorted_global_color = global_color(index,:);
        
        %keep only the closest point for each pixel. If two global points projected 
        %to the same pixel, keep only the point closest to the camera
        [unique_global_distorted_points, IA, IC] = ...
                               unique(sorted_global_distorted_points', 'rows', 'stable');

        unique_global_distorted_points = unique_global_distorted_points';
        unique_global_locs = sorted_global_locs(:, IA);
        unique_global_dists = sorted_global_dists(:,IA);
        unique_global_color = sorted_global_color(IA,:);


        %now make a depth image 
        pc_depth_img = zeros(kImageHeight, kImageWidth);
        pc_inds = sub2ind(size(pc_depth_img), unique_global_distorted_points(2,:), ...
                                              unique_global_distorted_points(1,:)); 
        pc_depth_img(pc_inds)  = double(unique_global_dists);
      end



      %% now remove the points from the object that are occluded by points 
      %from the global point cloud (using the constructed depth image), or occluded from itself
      %cur_world_locs = cur_world_locs';
      if(use_global_pc) 
         %get the distance from the camera to each point
         cur_dists = pdist2(camera_pos, double(cur_world_locs)');
         cur_locs_and_dists = [cur_world_locs; cur_dists];
   
         %sort the points by distance
         [sorted_locs_and_dists, index] = sortrows(cur_locs_and_dists',4);
         sorted_locs_and_dists = sorted_locs_and_dists';
   
         sorted_cur_locs = sorted_locs_and_dists(1:3, :);
         sorted_cur_dists = sorted_locs_and_dists(4,:);
         sorted_cur_distorted_points = distorted_points(:, index);
         sorted_cur_color = cur_color(index,:); 
   
   
         %keep only the closest point to the camera for each pixel
         %i.e. remove points that are occluded by other points on the object
         [unique_cur_distorted_points, IA, IC] = ...
                                unique(sorted_cur_distorted_points', 'rows', 'stable');
   
         unique_cur_distorted_points = unique_cur_distorted_points';
         unique_cur_locs = sorted_cur_locs(:, IA);
         unique_cur_dists = sorted_cur_dists(:,IA);
   
         cur_dists = unique_cur_dists;
         distorted_points = unique_cur_distorted_points;
         cur_world_locs = unique_cur_locs;
         cur_color = sorted_cur_color(IA,:);
   
         %get the depth of each point on the object from the depth image made
         %from the the global point cloud
         depths = pc_depth_img(sub2ind(size(pc_depth_img), ...
                                distorted_points(2,:), distorted_points(1,:)));
   
         %for any non occluded point, the depth in the depth image should equal 
         %the distance from that point to the camera (since all the ojbect points
         %are also in the global point cloud)
         dist_flags = abs(double(unique_cur_dists) - double(depths)) < .00001;
        
         %keep only the non occluded points 
         good_inds = find(dist_flags == 1);
         distorted_points = distorted_points(:,good_inds);
         cur_color = cur_color(good_inds,:);
         cur_world_locs = cur_world_locs(:,good_inds);
      end

      if(isempty(distorted_points))
        continue;
      end



      %% color check.  See if the points in the rgb image where the point cloud projected to
      % are close in color to the points in the point cloud


      if(use_color_check)
        %get the rgb image
        %img = imread(fullfile(scene_path, 'rgb', cur_image_name));
        img = rgb_images{kl};

       %convert to Lab colorspace
  %      cform = makecform('srgb2lab');
  %      lab_img =  applycform(im2double(img), cform);
  % 
  %      lab_points = applycform(double(cur_color), cform);
  %      lin_inds = sub2ind(size(lab_img), ...
  %                             distorted_points(2,:), distorted_points(1,:));
  %                           
  %      img_l = lab_img(:,:,1);
  %      img_a = lab_img(:,:,2);
  %      img_b = lab_img(:,:,3);
  %      
  %      lab_img_points = zeros(length(lab_points),3);
  %      lab_img_points(:,1) = img_l(lin_inds);
  %      lab_img_points(:,2) = img_a(lin_inds);
  %      lab_img_points(:,3) = img_b(lin_inds);
  % 
  %      %lab_dists = diag(pdist2(lab_points,lab_img_points));
  %     
  %       diffs = double(lab_points(:,[2,3])) - double(lab_img_points(:,[2,3]));
  %       sq_diffs = diffs.^2;
  %       ssd = sum(sq_diffs,2);
  %       lab_dists = sqrt(ssd);
         
        %convert the project pixel cooridinates to linear indices 
        lin_inds = sub2ind(size(img), ...
                               distorted_points(2,:), distorted_points(1,:));
       

        %TODO - shouldn't need to separate the channels, then put them back together like this
        %extract the R,G,B channels from the image
        img_r = img(:,:,1);
        img_g = img(:,:,2);
        img_b = img(:,:,3);
    
        %put the rgb values of the desired pixels in the 
        rgb_img_points = zeros(size(cur_color,1),3);
        rgb_img_points(:,1) = img_r(lin_inds);
        rgb_img_points(:,2) = img_b(lin_inds);
        rgb_img_points(:,3) = img_b(lin_inds);
        
       
   
         % first check to see if the image values are too close to white or black, compared to
         % the point cloud pixles 
  %       black_thresholds  = double(cur_color) ./ 2;
  %       white_thresholds  = double(cur_color) + -.5 * (double(cur_color) - 255);
  % 
  %       too_small = find(black_thresholds < 10);
  %       black_thresholds(too_small) = 0;
  %       too_big = find(white_thresholds > (255-10));
  %       white_thresholds(too_big) = 255;
  % 
  % 
  %       black_subs = rgb_img_points - black_thresholds;
  %       white_subs = white_thresholds - rgb_img_points; 
  % 
  %       black_flags = sum((black_subs >= 0), 2);
  %       white_flags = sum((white_subs >= 0), 2); 
  %       
  %       bad_inds = unique([find(black_flags < 2); find(white_flags < 2)]);
  % 
  %       distorted_points(:,bad_inds) = [];
  %       cur_world_locs(:,bad_inds) = [];
  %       cur_color(bad_inds,:) = [];      
  %       rgb_img_points(bad_inds,:) = [];



       %now get the color distance between the rgb image pixels and the point cloud 
         diffs = double(cur_color) - double(rgb_img_points);
         
         abs_diffs = abs(diffs);
         single_flags = (abs_diffs > 50) & (rgb_img_points < 40 | rgb_img_points > (200));
         sum_sf = sum(single_flags,2);
         bad_inds = find(sum_sf > 0);
         
         sq_diffs = diffs.^2;
         ssd = sum(sq_diffs,2);
         rgb_dists = sqrt(ssd);
         %rgb_dists = diag(pdist2(double(cur_color),double(rgb_img_points)));
       
         %only keep points that are close in color 
         if(method == 1)
           good_inds = find(rgb_dists < 80);
         else
           good_inds = find(rgb_dists < 50);
         end   
         distorted_points = distorted_points(:,good_inds); 
         cur_world_locs = cur_world_locs(:,good_inds);
   
   
         if(length(distorted_points) < 1)
           disp(['too few points color' , num2str(length(distorted_points))]);
           continue;
         end
      end















      if(isempty(distorted_points))
        continue;
      end



      %get the bounding box coordinates
      minx = min(distorted_points(1,:));
      miny = min(distorted_points(2,:));
      maxx = max(distorted_points(1,:));
      maxy = max(distorted_points(2,:));
     


      if(method == 2)
      %make sure size of object is big enough
        max_dim = max(maxx-minx, maxy-miny);
        if(max_dim < 100)
          continue;
        end 
      end

      
 
      %% if we got here, then the ojbect is in the image  
      found_image_names{kl} = cur_image_name;

      %get the label struct for this image
      cur_struct = label_structs(kl); 

      %check/set the image name of the label struct, for safety
      if(~strcmp(cur_struct.image_name, ''))
        assert(strcmp(cur_struct.image_name, cur_image_name));
      else
        cur_struct.image_name = cur_image_name;
      end


      %assign the bounding box to the current label 
      cur_struct.(cur_label_name) = [minx, miny, maxx, maxy];
     
      %put the label struct back in the struct array 
      label_structs(kl) = cur_struct;




      %show some visualization of the found points if debug option is set 
      if(debug)  
        %read in the rgb image
        img = imread(fullfile(scene_path, 'rgb', cur_image_name));


        dobj_img = zeros(size(img,1), size(img,2));
        dobject_inds = sub2ind(size(dobj_img), distorted_points(2,:), distorted_points(1,:)); 
        dobj_img(dobject_inds)  = 1;

        bbox = [minx miny maxx maxy];
        
        %display the image with the object point cloud overlayed
        imshow(img);
        hold on;
        h = imagesc(dobj_img); %plot object
        set(h,'AlphaData', .5); %make object transparent
       
        %draw the bounding box 
        rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], ...
                     'LineWidth',2, 'EdgeColor','r');
        if(use_color_check)           
          title(num2str(mean(rgb_dists)));
        end
        hold off;
        drawnow;
   
        %if(do_occlusion_filtering)
         figure;
         imshow(img);
         hold on;
         h = imagesc(depth_image);
         set(h,'AlphaData',.5);
         hold off;
        %end

        %ginput(1);
        breakp= 1;
        %close all; 
      end % if debug
    end%for k, each image name

    %remove empty values from cell array
    found_image_names  =  found_image_names(~cellfun('isempty', found_image_names));

   end%f r jl, each point cloud 


   %save all the label structs
   for jl=1:length(label_structs)
     cur_struct = label_structs(jl);

     if(strcmp(cur_struct.image_name, ''))
       cur_struct.image_name = image_names{jl};
     end

     cur_image_name = cur_struct.image_name;
     cur_struct = rmfield(cur_struct,'image_name');


     if(method == 0)
       save(fullfile(meta_path, 'labels', 'raw_labels', 'bounding_boxes_by_image_instance', ...
                      strcat(cur_image_name(1:10), '.mat')), '-struct', 'cur_struct'); 
     elseif(method == 1)
       save(fullfile(meta_path, 'labels', 'loose_3D_labels', 'bounding_boxes_by_image_instance', ...
                      strcat(cur_image_name(1:10), '.mat')), '-struct', 'cur_struct'); 
     elseif(method == 2)
       save(fullfile(meta_path, 'labels', 'strict_labels', 'bounding_boxes_by_image_instance', ...
                      strcat(cur_image_name(1:10), '.mat')), '-struct', 'cur_struct'); 
     end
   end%for jl, each label struct

end%for i, each scene_name


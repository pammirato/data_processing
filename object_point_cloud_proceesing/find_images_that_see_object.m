%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object


clearvars;

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


label_to_process = 'pepto_bismol'; %make 'all' for every label
label_names = {label_to_process};



do_occlusion_filtering = 0;
occlusion_threshold = 600;  %make > 12000 to remove occlusion thresholding 



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

for i=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{i};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


  %get info about camera position for each image
  %image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', 'all', ...
                                'colmap_results', '0',IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;

  %get a list of all the image file names
  %temp = cell2mat(image_structs);
  %image_names = {temp.(IMAGE_NAME)};
  image_names = {image_structs.(IMAGE_NAME)};

  %make a map from image name to image_struct
  %image_structs_map = containers.Map(image_names, image_structs);


  image_structs_map = containers.Map(image_names,...
                                 cell(1,length(image_names)));

  for jl=1:length(image_names)
    image_structs_map(image_names{jl}) = image_structs(jl);
  end

  %get camera parameters for each kinect
  [intrinsic, distortion, rotation, projection] = get_kinect_parameters(kinect_to_use);    


  %this will store the final  result
  pclabel_to_images_that_see_it_map = containers.Map();



  if(do_occlusion_filtering)
    %prompt user to load all the depth images for this scene ahead of time
    %(a good idea if they have not been loaded and more than one instance is to be processed) 
    load_depths = input('Load all depths?(y/n)' , 's');

    %whether the depths get loaded or not
    depths_loaded = 0;

    %load all the depths
    if((load_depths=='y'))

      %get names of all the rgb images in the scene
      image_names = get_names_of_X_for_scene(scene_name,'rgb_images');

      %will hold all the depth images
      depth_images = cell(1,length(d));

      %for each rgb image, load a depth image
      for j=1:length(image_names)
          rgb_name = image_names{j};

          depth_images{j} = imread(fullfile(scene_path, HIGH_RES_DEPTH, ... 
                   strcat(rgb_name(1:8),'03.png') ));
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




  %% MAIN LOOP

  %for each point cloud
  for jl=1:length(label_names)
    

    cur_label_name = label_names{jl};

    %cur_pc = pcread(fullfile(meta_path, LABELING_DIR, OBJECT_POINT_CLOUDS, ...
    %                   ORIGINAL_POINT_CLOUDS, strcat(cur_label_name, '.ply')));
    cur_pc = pcread(fullfile(meta_path,'labeling', ...
                       'object_point_clouds', strcat(cur_label_name, '.ply')));
 
   
    cur_world_locs = cur_pc.Location;

%    cur_world_locs = cur_world_locs / scale;
%    scale = 1 ;
    %cur_world_locs = cur_world_locs * scale; 


    found_image_names = cell(1,length(image_names));

    %for each image, determine if it 'sees' this object(point cloud) 
    for kl = 1:length(image_names) 

      cur_image_name = image_names{kl};
      cur_image_struct = image_structs_map(cur_image_name);

      %all the points from the points cloud, in homogenous coordinates
      cur_homog_points = [cur_world_locs ones(length(cur_world_locs), 1)]';

     
      %get parameters for this image 
      %K = intrinsic; 
      K = [1049.52, 0, 927.269; 0, 1050.65, 545.76; 0 0 1]; 
      R = cur_image_struct.(ROTATION_MATRIX);
      t = cur_image_struct.(TRANSLATION_VECTOR);


      %re-orient the point to see if it is viewable by this camera
      P = [R t];
      oriented_points = P * cur_homog_points;


      %make sure z is positive, if it is negative the point is 'behind' the image
      all_zs = oriented_points(3, :);
      bad_inds = find(all_zs < 0);%find the z values that are negative
      cur_homog_points(:, bad_inds) = []; %remove those points

      if(isempty(cur_homog_points))
        fprintf('Empty orientation, %s\n', cur_image_name);
        continue;
      end

      %not sure about what is happening herer
      if(length(cur_homog_points) ~= length(oriented_points))
        fprintf('Not all points oriented %s\n', cur_image_name);
      end


      %project the world point onto this image
      M = K * [R t];
      cur_image_points = M * cur_homog_points;

      %acccount for homogenous coords
      cur_image_points = cur_image_points ./ repmat(cur_image_points(3,:),3,1);
      cur_image_points = cur_image_points([1,2], :);
      cur_image_points =floor(cur_image_points);





      k1 = .381593;
      k2 = .1077399;
      k3 = 0;
      p1 = .00280506;
      p2 = -0.00120267;
      %fx = 1049.04;
      fx = K(1,1);
      %fy = 1066.29;
      fy = K(2,2);
      %cx = 927.269;
      cx = K(1,3);
      %cy = 545.76;
      cy = K(2,3);


      %distort point cloud points
    
      %new disotortion model
      % http://docs.opencv.org/master/db/d58/group__calib3d__fisheye.html#gsc.tab=0 
   
     % a = cur_image_points(1,:);
     % b = cur_image_points(2,:);
      XC = R* cur_world_locs' + repmat(t,1,size(cur_world_locs',2));
      a = XC(1,:) ./ XC(3,:);
      b = XC(2,:) ./ XC(3,:);
      

      r = sqrt( (a).^2 + (b).^2);
      theta = atan(r);

      thetad = theta .* (1 + k1*(theta.^2) + k2*(theta.^4) + p1*(theta.^6) + p2*(theta.^8));

      xx = (thetad./r) .* a;
      yy = (thetad./r) .* b;


      u = fx*(xx + 0*yy) + cx;
      v = fy*yy + cy;


      distorted_points = round([u;v]);

      bad_inds =  find(distorted_points(1,:) < 1 | distorted_points(1,:) > kImageWidth);
      distorted_points(:, bad_inds) = [];
      %check y values
      bad_inds =  find(distorted_points(2,:) < 1 | distorted_points(2,:) > kImageHeight);
      distorted_points(:, bad_inds) = [];



    %original distortion model

 
%      x = (cur_image_points(1,:) - K(1,3)) ./ K(1,1);
%      y = (cur_image_points(2,:) - K(2,3)) ./ K(2,2);
% 
%      r = sqrt( (x).^2 + (y).^2);
%      %k_term =(1 + distortion(1)*(r.^2) + distortion(2)*(r.^4) + distortion(5)*(r.^6)); 
%      k_term =(1 + k1*(r.^2) + k2*(r.^4) + k3*(r.^6)); 
%
%      %p_term_x= (distortion(4)*((r.^2) + 2*x.^2) + 2*distortion(3).*x.*y);
%      %p_term_y= (distortion(3)*((r.^2) + 2*y.^2) + 2*distortion(4).*x.*y);
%      p_term_x= (p2*((r.^2) + 2*x.^2) + 2*p1.*x.*y);
%      p_term_y= (p1*((r.^2) + 2*y.^2) + 2*p2.*x.*y);
%
%      dx = x.*k_term + p_term_x;
%      dy = y.*k_term + p_term_y;
%
%
%      %ddx = floor(dx*K(1,1) + K(1,3));
%      %ddy = floor(dy*K(2,2) + K(2,3));
%      ddx = floor(dx*fx + cx);
%      ddy = floor(dy*fy + cy);
%
%
%      distorted_points = [ddx;ddy];
      %end distortion






      %undistort point cloud points
%      xyz = R*cur_world_locs' + repmat(t,1,length(cur_world_locs));
%      xx = xyz(1,:) ./ xyz(3,:);
%      yy = xyz(2,:) ./ xyz(3,:);
%
%      r = sqrt( xx.^2 + yy.^2);
%
%      %ks = 1 + distortion(1)*(r.^2) + distortion(2)*(r.^4) + distortion(5)*(r.^6);
%      ks = 1 + k1*(r.^2) + k2*(r.^4) + k3*(r.^6);
%
%      %xxx = xx.*ks + 2*distortion(3).*xx.*yy + distortion(4)*(r.^2 + 2*xx.^2);
%      %yyy = yy.*ks + distortion(3)*(r.^2 + 2*yy.^2) + 2*distortion(4).*xx.*yy;
%      xxx = xx.*ks + 2*p1.*xx.*yy + p2*(r.^2 + 2*xx.^2);
%      yyy = yy.*ks + p1*(r.^2 + 2*yy.^2) + 2*p2.*xx.*yy;
%
%      %u = K(1,1) * xxx + K(1,3);
%      %v = K(2,2) * yyy + K(2,3);
%      u = fx * xxx + cx;
%      v = fy * yyy + cy;
%
%      undistorted_points =floor([u;v]);
      %end undistort 

      %make sure each point is in the image
      
      %check x values
      bad_inds =  find(cur_image_points(1,:) < 1 | cur_image_points(1,:) > kImageWidth);
      cur_image_points(:, bad_inds) = [];
      %check y values
      bad_inds =  find(cur_image_points(2,:) < 1 | cur_image_points(2,:) > kImageHeight);
      cur_image_points(:, bad_inds) = [];

   
      if(isempty(cur_image_points))
        fprintf('All points outside image, %s\n', cur_image_name);
        continue;
      end



      %%OCCULSION FILTERING
      %attempt to filter out images where the labeled instance is occuled
      %at the labeled point. 

      %make sure distance from camera to world_coords is similar to depth of
      %projected point in the depth image

      if(do_occlusion_filtering)
        %get the depth image
        if(~depths_loaded)
          depth_image = imread(fullfile(scene_path, HIGH_RES_DEPTH, ... 
                         strcat(cur_name(1:8),'03.png') ));
        else
          depth_image = depth_img_map(cur_name);
        end
        %get the depth of the projected point
        cur_depth = depth_image(floor(cur_image_point(2)), floor(cur_image_point(1)));

        %get the distance from the camera to the labeled point in 3D
        camera_pos = cur_image_struct.(SCALED_WORLD_POSITION);
        world_dist = pdist2(camera_pos', world_coords');

        %if the depth == 0, then keep this image as we can't tell
        %otherwise see if the difference in depth vs. distance is greater than the threshold
        if(abs(world_dist - cur_depth) > occlusion_threshold  && cur_depth >0)
          continue;
        end
     end%if do occlusion


      found_image_names{kl} = cur_image_name;


      %show some visualization of the found points if debug option is set 
      if(debug)  
        %read in the rgb image
        img = imread(fullfile(scene_path, 'rgb', cur_image_name));
        %img = imread(fullfile(scene_path, 'undistorted_images', '00000187.jpg'));

        %make an image with the object points = 1, everything else =0
        obj_img = zeros(size(img,1), size(img,2));
        object_inds = sub2ind(size(obj_img), cur_image_points(2,:), cur_image_points(1,:)); 
        obj_img(object_inds)  = 1;

        %uobj_img = zeros(size(img,1), size(img,2));
        %uobject_inds=sub2ind(size(uobj_img), undistorted_points(2,:), undistorted_points(1,:)); 
        %uobj_img(uobject_inds)  = .5;

        dobj_img = zeros(size(img,1), size(img,2));
        dobject_inds = sub2ind(size(dobj_img), distorted_points(2,:), distorted_points(1,:)); 
        dobj_img(dobject_inds)  = 1;

       % uminx = min(undistorted_points(1,:));
       % uminy = min(undistorted_points(2,:));
       % umaxx = max(undistorted_points(1,:));
       % umaxy = max(undistorted_points(2,:));

       % minx = min(cur_image_points(1,:));
       % miny = min(cur_image_points(2,:));
       % maxx = max(cur_image_points(1,:));
       % maxy = max(cur_image_points(2,:));

       % bbox = [minx miny maxx maxy];
       % ubbox = [uminx uminy umaxx umaxy];

        %display the image with the object superimposed
        imshow(img);
        hold on;
        %h = imagesc(uobj_img); %plot object
        %set(h,'AlphaData', .5); %make object transparent
        h = imagesc(dobj_img); %plot object
        set(h,'AlphaData', .5); %make object transparent
        %h = imagesc(obj_img); %plot object
        %set(h,'AlphaData', .5); %make object transparent
       
        p_x = mean(cur_image_points(1,:));
        p_y = mean(cur_image_points(2,:)); 

        %plot(p_x, p_y, 'r.', 'MarkerSize', 20);

        %draw bounding box
        %rectangle('Position',[ubbox(1) ubbox(2) (ubbox(3)-ubbox(1)) (ubbox(4)-ubbox(2))], ...
        %             'LineWidth',2, 'EdgeColor','b');
        %rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], ...
        %             'LineWidth',2, 'EdgeColor','r');
        hold off;
       
        %title(num2str(max(max(abs(distorted_points - cur_image_points)))));
 
        ginput(1);
      end % if debug
    end%for k, each image name

    %remove empty values from cell array
    found_image_names  =  found_image_names(~cellfun('isempty', found_image_names));

   end%for jl, each point cloud 
end%for i, each scene_name


%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object


clear all;

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'SN208_k1'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


label_to_process = 'red_chair'; %make 'all' for every label
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
  image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;
  scale = 1;

  %get a list of all the image file names
  temp = cell2mat(image_structs);
  image_names = {temp.(IMAGE_NAME)};

  %make a map from image name to image_struct
  image_structs_map = containers.Map(image_names, image_structs);



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


  %% PARSE LABELED POINTS FILE




  %% MAIN LOOP

  %for each point cloud
  for jl=1:length(label_names)
    

    cur_label_name = label_names{jl};

    cur_pc = pcread(fullfile(meta_path, LABELING_DIR, OBJECT_POINT_CLOUDS, ...
                       ORIGINAL_POINT_CLOUDS, strcat(cur_label_name, '.ply')));
 
   
    cur_world_locs = cur_pc.Location;

%    cur_world_locs = cur_world_locs / scale;
%    scale = 1 ;
    cur_world_locs = cur_world_locs * scale; 

    %for each image, determine if it 'sees' this object(point cloud) 
    for kl = 1:length(image_names) 

      cur_image_name = image_names{kl};
      cur_image_struct = image_structs_map(cur_image_name);

      %all the points from the points cloud, in homogenous coordinates
      cur_homog_points = [cur_world_locs ones(length(cur_world_locs), 1)]';

     
      %get parameters for this image 
      K = intrinsic; 
      R = cur_image_struct.(ROTATION_MATRIX);
      t = cur_image_struct.(TRANSLATION_VECTOR);
      t = t * scale;


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


      %show some visualization of the found points if debug option is set 
      if(debug)  
        %read in the rgb image
        img = imread(fullfile(scene_path, 'jpg_rgb', cur_image_name));
        %img = imread(fullfile(scene_path, 'undistorted_images', '00000187.jpg'));

        %make an image with the object points = 1, everything else =0
        obj_img = zeros(size(img,1), size(img,2));
        object_inds = sub2ind(size(obj_img), cur_image_points(2,:), cur_image_points(1,:)); 
        obj_img(object_inds)  = 1;

        minx = min(cur_image_points(1,:));
        miny = min(cur_image_points(2,:));
        maxx = max(cur_image_points(1,:));
        maxy = max(cur_image_points(2,:));

        bbox = [minx miny maxx maxy];

        %display the image with the object superimposed
        imshow(img);
        hold on;
        %h = imagesc(obj_img); %plot object
        %set(h,'AlphaData', .5); %make object transparent
        %draw bounding box
        rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], ...
                     'LineWidth',2, 'EdgeColor','r');
        hold off;
        
        ginput(1);
      end % if debug
    end%for k, each image name

    

end%for i, each scene_name


%Projects object point clouds into each image and saves the resulting bounding
%box of the object in each image. 

%TODO  - project all objects into each image at once?
%       - remove boxes from prev labels with this single label 

%CLEANED -no  ish 
%TESTED - ish 


%initialize contants, paths and file names, etc. 

init;
%% USER OPTIONS

scene_name = 'Home_04_1'; %make this = 'all' to run all scenes
model_number = '0'; %colmap model number
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 

label_to_process = 'cholula_chipotle_hot_sauce'; %make 'all' for every label
use_custom_labels = 0;
label_names_list = {}; 

method = 0; %0 - oclusion filtering, uses improved depth maps if they exist
            %1 - no ocllusion filtering
            
occlusion_threshold = 120;  %amount in mm that point cloud can differ from depth
include_0 = 1;


debug =0;

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
  instance_name_to_id_map = get_instance_name_to_id_map();
  if(use_custom_labels && ~isempty(label_names_list))
    label_names = label_names_list;
  elseif(strcmp(label_to_process, 'all'))
    label_names = keys(instance_name_to_id_map);
  else
    label_names = {label_to_process};
  end

  %% get camera info from the colmap reconstruction
  %the camera follows this camera model from opencv
  % http://docs.opencv.org/master/db/d58/group__calib3d__fisheye.html#gsc.tab=0 
  fid_camera =  fopen(fullfile(meta_path,'reconstruction_results',  ...
                                'colmap_results', model_number,'cameras.txt'));
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
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results',  ...
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
  
  if(method~=1)
    %prompt user
    load_depths = input('Load all depths?(y/n)' , 's');

    %load all the depths
    if((load_depths=='y'))
      %will hold all the depth images
      depth_images = cell(1,length(image_names));

      %for each image image, load a depth image
      for jl=1:length(image_names)
          rgb_name = image_names{jl};
  
          %display progress
          if(mod(jl,50)==0)
            disp(jl);
          end

          %try to load improved depth maps if they exist 
          try
            %depth_images{jl} = imread(fullfile(meta_path, IMPROVED_DEPTH, ... 
            %             strcat(rgb_name(1:8),'05.png') ));
            depth_images{jl} = imread(fullfile(meta_path, 'improved_depths3', ... 
                         strcat(rgb_name(1:8),'05.png') ));
          catch
            depth_images{jl} = imread(fullfile(scene_path, HIGH_RES_DEPTH, ... 
                   strcat(rgb_name(1:8),'03.png') ));
          end
      end% for jl,  each image name
      %put all the images in a map by rgb image name 
      depth_img_map = containers.Map(image_names, depth_images);
      depths_loaded = 1;%indicate depths are loded
    end%if we should load all the depths)


    %if we are told to not load the depths, see if they were already loaded
    if(load_depths == 'n')
      a = input('Are depths loaded?(y/n)' , 's');
      if(a=='y')
        %now we assume the depth_img_map exists and is correct
        depths_loaded = 1;
      end
    end
  end%if method ~= 1



  %% MAIN LOOP  for each label find its bounding box in each image

  %for each point cloud
  for jl=1:length(label_names)
      
    %get the name of the label
    cur_label_name = label_names{jl};
    disp(cur_label_name);

    %load the labeled point cloud for this label in this scene
    try
      cur_pc = pcread(fullfile(meta_path,LABELING_DIR, ...
                      OBJECT_POINT_CLOUDS, strcat(cur_label_name, '.ply')));
    catch
      %this label has not been labeled in the scenes point cloud
      disp(sprintf('skipping: %s', cur_label_name));
      continue; 
    end 
   
    %will hold the names of all the images that have a valid bounding box for this label
    %really just for debugging
    found_image_names = cell(1,length(image_names));

    %% for each image, determine if it 'sees' this object(point cloud) 
    for kl = 1:length(image_names) 
      
      %just to see how much progress is being made
      if(mod(kl,50) == 0)
        disp(cur_image_name);
      end
      
      %% get the image name, position/direction info from reconstruction
      cur_image_name = image_names{kl};
      cur_image_struct = image_structs_map(cur_image_name);

      %% get the posisiton and color of the object point cloud
      cur_world_locs = cur_pc.Location;
    
      %% now see what points are in front of the current camera

      % point cloud locations,  in homogenous coordinates
      cur_homog_points = [cur_world_locs ones(length(cur_world_locs), 1)]';

      %get extrinsic parameters for this image 
      R = cur_image_struct.(ROTATION_MATRIX);
      t = cur_image_struct.(TRANSLATION_VECTOR);

      %re-orient the point clouds to see if they are viewable by this camera
      P = [R t];
      oriented_points = P * cur_homog_points;

      %make sure z is positive, if it is negative the point is 'behind' the image
      all_zs = oriented_points(3, :);
      bad_inds = find(all_zs < 0);  
      %remove the points with negative z values
      cur_world_locs(bad_inds, :) = [];

      %if no points on the object are left, then the object is not in 
      %this image. Continue to the next image
      if(isempty(cur_world_locs))
        continue;
      end



      %% project the point clouds onto the image plane

      distorted_points = project_points_to_image(cur_world_locs, K, R, t, distortion);

      %get rid of points that projected outside the image bounds
      %check x values
      bad_inds =  find(distorted_points(1,:) < 1 | distorted_points(1,:) > kImageWidth);
      distorted_points(:, bad_inds) = [];
      cur_world_locs(bad_inds,:) = [];
      %check y values
      bad_inds =  find(distorted_points(2,:) < 1 | distorted_points(2,:) > kImageHeight);
      distorted_points(:, bad_inds) = [];
      cur_world_locs(bad_inds,:) = [];

      %if the entire object is outside the image bounds, 
      %it is not in this image, move to the next image
      if(isempty(distorted_points))
        continue;
      end


      %% OCCULSION FILTERING
      %attempt to filter out images where the labeled instance is occluded
      %and adjust bounding boxes to account for occlusion

      %get the position of the camera in world coordinates
      cam_pos = cur_image_struct.(WORLD_POSITION);
      cam_dir = cur_image_struct.direction;
      %make sure it is a row vector
      if(size(cam_pos,2) == 1)
        cam_pos = cam_pos';
      end
      %change shape of point cloud points :(
      cur_world_locs = cur_world_locs';

      %check how many points from the labeled point cloud are
      %still relevant before occlusion. Also get the current bounding box 
      num_points_pre_occlusion = length(distorted_points);
      minx = min(distorted_points(1,:));
      miny = min(distorted_points(2,:));
      maxx = max(distorted_points(1,:));
      maxy = max(distorted_points(2,:));
      bbox_area = (maxx - minx) * (maxy-miny);
      pre_occlusion_density = num_points_pre_occlusion / bbox_area;

      if(method ~= 1)%only do occlusion filtering for the appropriate methods
        %get the depth image, if not pre-loaded read from file
        if(~depths_loaded)
          try
            depth_image = imread(fullfile(meta_path, 'improved_depths', ... 
                         strcat(cur_image_name(1:8),'05.png') ));
          catch
            depth_image = imread(fullfile(scene_path, 'high_res_depth', ... 
                          strcat(cur_image_name(1:8),'03.png') ));
          end
        else
          depth_image = depth_img_map(cur_image_name);
        end

        %pick out depth values of the pixels where the current
        %object projected to in the current image
        depths = depth_image(sub2ind(size(depth_image), ...
                               distorted_points(2,:), distorted_points(1,:)));

        %scaled the labeled point cloud
        scaled_world_locs = cur_world_locs.*scale;
       
        %get the 'depth' of each point in the point cloud 
        %the kinect depth camera gets the depth from objects to a plane at the camera
        %so here we get the distance from the points in the cloud to the plane
        %defined by the cameras reconstructed world coordinates, and the 
        %cameras direction as a normal vector to the plane
        cam_to_point_vecs = cur_world_locs'*scale - ...
                            repmat(cam_pos*scale, size(cur_world_locs',1),1);
        world_dists = (cam_to_point_vecs * cam_dir)';

        %remove point if distance is much different than depth(or depth image is 0)
        dist_flags = abs(double(world_dists) - double(depths)) >  occlusion_threshold;
        if(include_0)
          depth_flags = dist_flags;
        else
          depth_flags = dist_flags | (depths == 0);
        end
        bad_inds = find(depth_flags);
        distorted_points(:,bad_inds) = [];
      end%if do occlusion

      %if only a few of the points from the point cloud survived,
      %it is probably occluded in this image, so move to the next image
      if(length(distorted_points)<30)
         disp('too few points');
        continue;
      end

      %get the new bounding box after occlusion
      minx = min(distorted_points(1,:));
      miny = min(distorted_points(2,:));
      maxx = max(distorted_points(1,:));
      maxy = max(distorted_points(2,:));
      bbox_area = (maxx - minx) * (maxy-miny);
      post_occlusion_density = length(distorted_points) / bbox_area;

      %if the new point cloud is spread out and no dense compared to the old
      %one, then probably the object is occluded and just a few points got through
      %do to depth image noise, so move to next image
      if((post_occlusion_density/pre_occlusion_density < .1))
        disp('density too small');
        continue;
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
        %create image of the procted point cloud
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
        %ginput(1);
        breakp= 1;
      end % if debug
    end%for kl, each image name
    
    %remove empty values from cell array
    found_image_names  =  found_image_names(~cellfun('isempty', found_image_names));
  end%for jl, each point cloud 


  %% save the generated labels 

  save_path = '';
  if(method == 0)
    save_path=fullfile(meta_path, LABELING_DIR,RAW_LABELS, BBOXES_BY_IMAGE_INSTANCE );
  elseif(method == 1)
    save_path=fullfile(meta_path, LABELING_DIR,LOOSE_LABELS, BBOXES_BY_IMAGE_INSTANCE);
  end

  if(~exist(save_path,'dir'))
    mkdir(save_path);
  end

  %save all the label structs
  for jl=1:length(label_structs)

    %get the next label struct and corresponding image name
    cur_struct = label_structs(jl);
    if(strcmp(cur_struct.image_name, ''))
      cur_struct.image_name = image_names{jl};
    end
    cur_image_name = cur_struct.image_name;
    cur_struct = rmfield(cur_struct,'image_name');

    %name the file to save the data for this image in
    save_file_path=fullfile(save_path, strcat(cur_image_name(1:10), '.mat'));

    %convert the label struct to ouput format, array of vectors
    %one vector per labels, [xmin, ymin, xmax, ymax, cat_id, hardness]
    cur_fields = fieldnames(cur_struct);
    boxes = cell(0);
    %lood through all instance names in the label struct
    for kl=1:length(cur_fields)
      %get id of this instance name
      inst_id = instance_name_to_id_map(cur_fields{kl});
      temp = cur_struct.(cur_fields{kl});
      if(isempty(temp))
        continue; %there is no label for this instance
      end
      boxes{end+1} = [temp inst_id 0];
    end%for kl
    boxes = cell2mat(boxes');


    %check for pre-existing labels, only overwrite newly generated labels
    if(exist(save_file_path, 'file'))
      prev_boxes = load(save_file_path);
      prev_boxes = prev_boxes.boxes; 
      if(~isempty(prev_boxes))
        inds_to_remove = zeros(1,size(boxes,1));
        for kl=1:size(boxes,1)
          inst_id = boxes(kl,5);
          prev_box_ind = find(prev_boxes(:,5) == inst_id);
          if(isempty(prev_box_ind))
            continue;
          end
          prev_boxes(prev_box_ind,:) = boxes(kl,:);
          inds_to_remove(kl) = 1; 
        end%for kl, each new box 
        boxes(find(inds_to_remove),:) = [];
        boxes = cat(1,boxes,prev_boxes);
      end
    end%if labels already exist
    
    boxes = uint16(boxes); %save space?
    %save the boxes to file 
    save(save_file_path, 'boxes');
  end%for jl, each label struct


  %convert the labels from boxes by image instance to boxes by instance
  convert_boxes_by_image_instance_to_instance(scene_name);
end%for il, each scene_name




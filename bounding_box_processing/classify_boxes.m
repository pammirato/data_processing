% assigns a label to each bounding box indicating how difficult it may
% for a detection system to duplicate
%
% It assumed boxes follow the following format:
%
%   [xmin ymin xmax ymax cat_id hardness ...]
%


%TODO

%CLEANED - yes
%TESTED - no


clearvars;
%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'Bedroom_01_1', 'Kitchen_Living_01_1', 'Kitchen_Living_02_1', 'Kitchen_Living_03_1', 'Kitchen_Living_04_2', 'Kitchen_05_1', 'Kitchen_Living_06', 'Office_01_1'};%populate this 


%which instances to use
label_to_process = 'all'; %make 'all' for every label
label_names = {label_to_process};

label_type = 'verified_labels';  %raw_labels - automatically generated labels
                                %verified_labels - boxes looked over by human

debug =0;


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
  fid_camera =  fopen(fullfile(meta_path,'reconstruction_results', ...
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







  %% MAIN LOOP for each intsance label, get all of its boxes and classify them 

  %for each  instance label
  for jl=1:length(label_names)
    
    %get the name of the label
    cur_label_name = label_names{jl};
    disp(cur_label_name);%display progress

    %load the labeled point cloud for this label in this scene
    cur_pc = pcread(fullfile(meta_path,LABELING_DIR, ...
                    OBJECT_POINT_CLOUDS, strcat(cur_label_name, '.ply')));
 

    %load the boxes for this instance                
    try
      cur_instance_boxes = load(fullfile(meta_path, LABELING_DIR, label_type, ...
                              BBOXES_BY_INSTANCE, strcat(cur_label_name, '.mat')));
    catch
      %this instance hasn't been labeled yet, skip it
      continue;
    end

    %get all the image names and boxes for the instance 
    image_names = cur_instance_boxes.image_names; 
    cur_instance_boxes = cur_instance_boxes.boxes;

    %% for each box,image classify the box 
    for kl = 1:length(image_names) 
      %get the image name, and the coressponding image struct     
      cur_image_name = image_names{kl};
      cur_image_struct = image_structs_map(cur_image_name);
      
      %get extrinsic parameters for this image 
      R = cur_image_struct.(ROTATION_MATRIX);
      t = cur_image_struct.(TRANSLATION_VECTOR);

      %% get the posisiton of the object point cloud
      cur_world_locs = cur_pc.Location;
    
    
      %% now see what points the are in front of the camera
      
      % point cloud locations,  in homogenous coordinates
      cur_homog_points = [cur_world_locs ones(length(cur_world_locs), 1)]';

      %re-orient the point cloud to see what points are viewable by this image
      P = [R t];
      oriented_points = P * cur_homog_points;

      %make sure z is positive, if it is negative the point is 'behind' the image
      all_zs = oriented_points(3, :);
      bad_inds = find(all_zs < 0);  
      %remove the points with negative z values
      cur_homog_points(:, bad_inds) = []; 
      cur_world_locs(bad_inds, :) = [];


      %% project the point cloud onto the image plane
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


      %% classify the box

      %get dimensions of the box just found(without occlusion filtering) 
      minx = min(distorted_points(1,:));
      miny = min(distorted_points(2,:));
      maxx = max(distorted_points(1,:));
      maxy = max(distorted_points(2,:));
      box_area = (maxx - minx) * (maxy-miny);


      %get the true labeled box and its dimensions 
      labeled_box = cur_instance_boxes{kl};
      labeled_box_area = (labeled_box(3) - labeled_box(1)) * (labeled_box(4)-labeled_box(2));
      labeled_min_dim = min((labeled_box(3)-labeled_box(1)), (labeled_box(4)-labeled_box(2)));
      labeled_max_dim = max((labeled_box(3)-labeled_box(1)), (labeled_box(4)-labeled_box(2)));
    
      %three separate measures of hardness for a box. we will calculate each separately
      %and then pick whichever indicates the highest 'hardness'. 
      raw_area_hardness = 0;%is the box small?
      ratio_area_hardness = 0;%is the true box much smaller than
                              % box without occlusion filtering?
      num_points_hardness = 0;%did only a few points from the point cloud 
                              %project into this image? (object is cut off)




      %raw area hardness (too small?)
      %if one dimension is too small, it will be very hard to find
      if((labeled_max_dim > .1*kImageWidth)  && (labeled_min_dim > 40))
        raw_area_hardness = 0;
      elseif((labeled_max_dim > .05*kImageWidth)  && (labeled_min_dim > 30))
        raw_area_hardness = 1;
      elseif((labeled_max_dim > .025*kImageWidth)  && (labeled_min_dim > 20))
        raw_area_hardness = 2;
      else
        raw_area_hardness = 3;
      end 


      %ratio area hardness (kind of occlusion)
      %if the true labeled box is only 50% the area of the box without
      % occlusion filtering, very roughly 50% of the object is occluded
      area_ratio = labeled_box_area/box_area; 
      if(area_ratio > .8)
        ration_area_hardness = 0; 
      elseif(area_ratio > .6)
        ration_area_hardness = 1; 
      elseif(area_ratio > .4)
        ration_area_hardness = 2; 
      else
        ration_area_hardness = 3; 
      end


      %num points hardness (cut off?)
      %if only 50% of the point cloud projects into the image, 
      %then very roughly %50 of the object is not in the image,
      % maybe cut off on the boundary
      num_points_ratio = length(distorted_points)/ length(cur_pc.Location);
      if(num_points_ratio > .8)
        ration_area_hardness = 0; 
      elseif(num_points_ratio > .6)
        ration_area_hardness = 1; 
      elseif(num_points_ratio > .4)
        ration_area_hardness = 2; 
      else
        ration_area_hardness = 3; 
      end 

      %the final hardness is the max hardness of any of the three measures
      hardness = max([raw_area_hardness, ratio_area_hardness, num_points_hardness]);

      %add the hardness meseaure to the box 
      cur_instance_boxes{kl} = [labeled_box(1:5) hardness];
    end%for kl, each image name

    %% save the newly classified boxes for this instance label

    %create the struct for the boxes
    boxes = cur_instance_boxes;
    cur_instance_boxes = struct('image_names', cell(1), ...
                                'boxes', cell(1));
    cur_instance_boxes.image_names = image_names;
    cur_instance_boxes.boxes = boxes;
    %save 
    save(fullfile(meta_path,LABELING_DIR, label_type ...
                            BBOXES_BY_INSTANCE,...
                             strcat(cur_label_name, '.mat')),...
                               '-struct', 'cur_instance_boxes');
  end%for jl, each instance label name 
end%for il, each scene_name


%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object


clearvars;

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Kitchen_Living_04_2'; %make this = 'all' to run all scenes
group_name = 'all_minus_boring';
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


label_to_process = 'all'; %make 'all' for every label
label_names = {label_to_process};






debug =0;

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




  pose_image_names = dir(fullfile(meta_path, 'labels', 'pose_images', '*.png'));
  pose_image_names = {pose_image_names.name};




  %get info about camera position for each image
  %image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', group_name, ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;



  blank_struct = struct();
  blank_struct.image_name = '';
  for jl=1:length(pose_image_names)
    pi_name = pose_image_names{jl};
    split_name = strsplit(pi_name, '_');
    
    blank_struct.(split_name{2}) = []; 
  end


  label_structs = repmat(blank_struct, length(image_structs), 1);


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

  %% MAIN LOOP

  %for each point cloud
  for jl=1:length(pose_image_names)
    

    cur_pose_image_name = pose_image_names{jl};







    split_name = strsplit(cur_pose_image_name, '_');
    labeled_instance_name  = split_name{2};
    pa = split_name{3};
    labeled_pose_angle = str2double(pa(1:end-4));

    labeled_image_name = strcat(split_name{1}, '.png');
    labeled_image_struct = image_structs_map(labeled_image_name);

    labeled_loc = labeled_image_struct.world_pos;
    labeled_loc2d =double(labeled_loc([1 3]));


    instance_point_cloud = pcread(fullfile(meta_path, 'labels', 'object_point_clouds', ...
                                    strcat(labeled_instance_name, '.ply')));

    instance_locs = instance_point_cloud.Location;

    instance_loc = mean(instance_locs);
    instance_loc2d = double(instance_loc([1 3]));

    if(strcmp(labeled_instance_name, 'couch3'))
      breakp=1;
    end

    %for each image, determine if it 'sees' this object(point cloud) 
    for kl = 1:length(image_names) 

      cur_image_name = image_names{kl};
      cur_image_struct = image_structs_map(cur_image_name);

      cur_loc = cur_image_struct.world_pos;
      cur_loc2d =double(cur_loc([1 3])); 


      %get lengths of sides of triangle
      sidea = pdist2(labeled_loc2d', cur_loc2d');
      sideb = pdist2(labeled_loc2d', instance_loc2d);
      sidec = pdist2(instance_loc2d, cur_loc2d');

      [label_to_cur_angle,~,~] = get_triangle_angles_from_sides(sidea, sideb, sidec);


      if(~isreal(label_to_cur_angle))
        label_to_cur_angle = 0;
      end

      cur_is_left = left(instance_loc2d, labeled_loc2d, cur_loc2d);


      cur_pose_angle = label_to_cur_angle;
      if(cur_is_left)
        cur_pose_angle = mod(labeled_pose_angle + cur_pose_angle, 360); 
      else
        cur_pose_angle = mod(labeled_pose_angle - cur_pose_angle, 360); 
      end 



      cur_struct = label_structs(kl); 

      if(~strcmp(cur_struct.image_name, ''))
        assert(strcmp(cur_struct.image_name, cur_image_name));
      else
        cur_struct.image_name = cur_image_name;
      end

      cur_struct.(labeled_instance_name) = [cur_pose_angle];
      
      label_structs(kl) = cur_struct;

      %show some visualization of the found points if debug option is set 
      if(debug && mod(kl,100) ==1 )  
        %read in the rgb image

        img = imread(fullfile(scene_path, 'rgb', cur_image_name));
        imshow(img);
        title(strcat(labeled_instance_name, '.....', num2str(cur_pose_angle)));

        breakp = 1; 
        ginput(1);
      end % if debug
    end%for k, each image name


   end%for jl, each label 



   for jl=1:length(label_structs)
     cur_struct = label_structs(jl);

     if(strcmp(cur_struct.image_name, ''))
       cur_struct.image_name = image_names{jl};
     end

     cur_image_name = cur_struct.image_name;
     cur_struct = rmfield(cur_struct,'image_name');

     save(fullfile(meta_path, 'labels', 'pose_label_structs', ...
                    strcat(cur_image_name(1:10), '.mat')), '-struct', 'cur_struct'); 

   end%for jl, each label struct

end%for i, each scene_name


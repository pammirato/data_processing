%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object

%TODO -get rid of image structs map. Just use indexes. (Make it sorted?)


%clearvars;

%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

scene_name = 'Kitchen_Living_08_1'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 1;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'Bedroom_01_1', 'Kitchen_Living_01_1', 'Kitchen_Living_02_1', 'Kitchen_Living_03_1', 'Kitchen_Living_04_2', 'Kitchen_05_1', 'Kitchen_Living_06', 'Office_01_1', 'Kitchen_Living_08_1', 'Kitchen_Living_03_2'};%populate this 


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
scenes_count_struct = struct('total', [0 0]);
for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %get the names of all the labels
  if(strcmp(label_to_process, 'all'))
    label_names = get_names_of_X_for_scene(scene_name, 'instance_labels');
  end


  image_names = get_names_of_X_for_scene(scene_name, 'rgb_images');





  %% MAIN LOOP  for each label find its bounding box in each image

  images_with_a_box = 0;
  %for each point cloud
  for jl=1:length(image_names)
    
    %get the name of the label
    cur_image_name = image_names{jl};
    disp(cur_image_name);


                     
    try
      cur_instance_boxes = load(fullfile(meta_path, 'labels', 'verified_labels', ...
                         'bounding_boxes_by_image_instance', strcat(cur_image_name(1:10),'.mat')));
    catch
      continue;
    end

    instance_names = fieldnames(cur_instance_boxes);

    has_box = 0;
    for kl=1:length(instance_names)
      if(~isempty(cur_instance_boxes.(instance_names{kl})))
        has_box = 1;
        break;
      end
    end
    
    if(has_box)
      images_with_a_box = images_with_a_box + 1;
    end

  end%for jl, each label struct
  scenes_count_struct.(scene_name) = [images_with_a_box, length(image_names)];
  scenes_count_struct.total = scenes_count_struct.total + ...
                                       [images_with_a_box, length(image_names)];

end%for i, each scene_name


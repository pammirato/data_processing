%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object

%TODO -get rid of image structs map. Just use indexes. (Make it sorted?)


%clearvars;

%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

scene_name = 'Kitchen_Living_03_1'; %make this = 'all' to run all scenes
group_name = 'all_minus_boring';
model_number = '0';
use_custom_scenes = 1;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'Bedroom_01_1', 'Kitchen_Living_01_1', 'Kitchen_Living_02_1', 'Kitchen_Living_03_1'};%populate this 


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
scenes_count_struct = struct();
for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %get the names of all the labels
  if(strcmp(label_to_process, 'all'))
    label_names = get_names_of_X_for_scene(scene_name, 'instance_labels');
  end








  count_struct = struct();
  hard0_sum = 0;
  hard1_sum = 0;
  hard2_sum = 0;
  hard3_sum = 0;
  total_sum = 0;
  %% MAIN LOOP  for each label find its bounding box in each image

  %for each point cloud
  for jl=1:length(label_names)
    
    %get the name of the label
    cur_label_name = label_names{jl};
    disp(cur_label_name);


                     
    try
    cur_instance_boxes = load(fullfile(meta_path, 'labels', 'verified_labels', ...
                              'bounding_boxes_by_instance', strcat(cur_label_name, '.mat')));
    catch
      continue;
    end

    image_names = cur_instance_boxes.image_names; 
    cur_instance_boxes =cell2mat( (cur_instance_boxes.boxes)');;

    hard0 = length(find(cur_instance_boxes(:,5) == 0)); 
    hard1 = length(find(cur_instance_boxes(:,5) == 1)); 
    hard2 = length(find(cur_instance_boxes(:,5) == 2)); 
    hard3 = length(find(cur_instance_boxes(:,5) == 3)); 
    total = size(cur_instance_boxes,1);
    
    count_struct.(cur_label_name) = [hard0 hard1 hard2 hard3 total];


    hard0_sum = hard0_sum + hard0;
    hard1_sum = hard1_sum + hard1;
    hard2_sum = hard2_sum + hard2;
    hard3_sum = hard3_sum + hard3;
    total_sum = total_sum + total;
  end%for jl, each label struct
  scenes_count_struct.(scene_name) = [hard0_sum hard1_sum hard2_sum hard3_sum total_sum];

end%for i, each scene_name


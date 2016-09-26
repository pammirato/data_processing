% count the number of bounding boxes in each scene. Takes into acccount the hardness measure
% outputs inidcating counts of each hardness level and total for each scene and all scenes 
% For the last scene a struct with counts for each instance in that scene is made
%
% Does not save anything, just produces new variables in the MATLAB workspace 
% and prints the total over all scenes

%TODO - generalize for different harndess measures

%CLEANED - yes 
%TESTED - no

clearvars;

%initialize contants, paths and file names, etc. 
init;


%% USER OPTIONS

scene_name = 'Kitchen_Living_08_1'; %make this = 'all' to run all scenes
model_number = '0';%colmap model number
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'Bedroom_01_1', 'Kitchen_Living_01_1', 'Kitchen_Living_02_1', 'Kitchen_Living_03_1', 'Kitchen_Living_04_2', 'Kitchen_05_1', 'Kitchen_Living_06', 'Office_01_1', 'Kitchen_Living_08_1', 'Kitchen_Living_03_2'};%populate this 


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


%make a struct to hold counts for each scene, and a total across all scenes
scenes_count_struct = struct('total', 0);

%% MAIN LOOP
for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  instance_name_to_id_map = get_instance_name_to_id_map();
  %get the names of all the labels
  if(strcmp(label_to_process, 'all'))
    label_names = keys(instance_name_to_id_map;
  end

  %make a struct to hold counts for each instance in this scene
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
    disp(cur_label_name);%display progress

    %load boxes for this instance in this scene
    try
      cur_instance_boxes = load(fullfile(meta_path, LABELING_DIR, label_type, ...
                                        BBOXES_BY_INSTANCE, strcat(cur_label_name, '.mat')));
    catch
      %if this instance is not in this scene, skip it
      continue;
    end

    %get all the boxes for this instance in a matrix
    cur_instance_boxes =cell2mat( (cur_instance_boxes.boxes)');;

    %count the boxes for each hardness level and a total
    hard0 = length(find(cur_instance_boxes(:,6) == 0)); 
    hard1 = length(find(cur_instance_boxes(:,6) == 1)); 
    hard2 = length(find(cur_instance_boxes(:,6) == 2)); 
    hard3 = length(find(cur_instance_boxes(:,6) == 3)); 
    total = size(cur_instance_boxes,1);
   
    %put in the counts for this instance in this scene 
    count_struct.(cur_label_name) = [hard0 hard1 hard2 hard3 total];

    %update the running sums for this scene
    hard0_sum = hard0_sum + hard0;
    hard1_sum = hard1_sum + hard1;
    hard2_sum = hard2_sum + hard2;
    hard3_sum = hard3_sum + hard3;
    total_sum = total_sum + total;
  end%for jl, each label struct

  %update the global struct with counts for this scene across all instances
  scenes_count_struct.(scene_name) = [hard0_sum hard1_sum hard2_sum hard3_sum total_sum];
  scenes_count_struct.total = scenes_count_struct.total + total_sum;
end%for il, each scene_name

fprintf('Total boxes in %d scenes: %d', length(all_scenes),...
                                        scenes_count_struct.total);




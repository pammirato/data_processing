function [scenes_count_struct, count_struct] = count_boxes(scene_name, label_type)
% count the number of bounding boxes in each scene. Takes into acccount the hardness measure
%INPUTS:
%       scene_name: char array of single scene name, 'all' for all scenes, 
%                     or a cell array of char arrays, one for each desired scene
%       label_type: OPTIONAL 'verified_labels'(default) or 'raw_labels'
%
%OUTPUTS
%       scenes_count_struct: One field for each scene name -> length 5 vector
%                            [# boxes with hardness 1, # w/ hardness 2, 3, 4, total # boxes] 
%       count_struct: One field for each label name -> length 5 vector (Same as above)
%                     One 'total' field, -> length 5 vector with sums across all instances
%
%       *does not save anything to file

%TODO - generalize for different hardness measures

%CLEANED - no 
%TESTED - no

%clearvars;

%initialize contants, paths and file names, etc. 
init;


%% USER OPTIONS

%scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
model_number = '0';%colmap model number
%use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
%custom_scenes_list = {'Bedroom_01_1', 'Kitchen_Living_01_1', 'Kitchen_Living_02_1', 'Kitchen_Living_03_1', 'Kitchen_Living_04_2', 'Kitchen_05_1', 'Kitchen_Living_06', 'Office_01_1', 'Kitchen_Living_08_1', 'Kitchen_Living_03_2'};%populate this 


label_to_process = 'all'; %make 'all' for every label
label_names = {label_to_process};

if(~exist('label_type', 'var'))
  label_type = 'verified_labels';  %raw_labels - automatically generated labels
end                            %verified_labels - boxes looked over by human

debug =0;


%% SET UP GLOBAL DATA STRUCTURES

%get the names of all the scenes
d = dir(ROHIT_BASE_PATH);
d = d(3:end);
all_scenes = {d.name};

%determine which scenes are to be processed 
if(iscell(scene_name))
  %if we are using the custom list of scenes
  all_scenes = scene_name;
elseif(~strcmp(scene_name, 'all'))
  %if not using custom, or all scenes, use the one specified
  all_scenes = {scene_name};
end


%make a struct to hold counts for each scene, and a total across all scenes
scenes_count_struct = struct('total', zeros(1,5));

%% MAIN LOOP
for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  instance_name_to_id_map = get_instance_name_to_id_map();
  %get the names of all the labels
  if(strcmp(label_to_process, 'all'))
    label_names = keys(instance_name_to_id_map);
  end

  %make a struct to hold counts for each instance in this scene
  count_struct = struct();
  hard1_sum = 0;
  hard2_sum = 0;
  hard3_sum = 0;
  hard4_sum = 0;
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
    %cur_instance_boxes =cell2mat( (cur_instance_boxes.boxes));
    cur_instance_boxes =cur_instance_boxes.boxes;
    assert(size(cur_instance_boxes,2) > 4);
    
    %count the boxes for each hardness level and a total
     hard1 = length(find(cur_instance_boxes(:,6) == 1)); 
     hard2 = length(find(cur_instance_boxes(:,6) == 2)); 
     hard3 = length(find(cur_instance_boxes(:,6) == 3)); 
     hard4 = length(find(cur_instance_boxes(:,6) == 4)); 
    total = size(cur_instance_boxes,1);
   
    %put in the counts for this instance in this scene 
    %count_struct.(cur_label_name) = [total];
    count_struct.(cur_label_name) = [hard1 hard2 hard3 hard4 total];

    %update the running sums for this scene
     hard1_sum = hard1_sum + hard1;
     hard2_sum = hard2_sum + hard2;
     hard3_sum = hard3_sum + hard3;
     hard4_sum = hard4_sum + hard4;
    total_sum = total_sum + total;
  end%for jl, each label struct

  %update the global struct with counts for this scene across all instances
  scenes_count_struct.(scene_name) = [hard1_sum hard2_sum hard3_sum hard4_sum total_sum];
  %scenes_count_struct.total = scenes_count_struct.total + total_sum;
  scenes_count_struct.total = scenes_count_struct.total + scenes_count_struct.(scene_name);
end%for il, each scene_name

fprintf('Total boxes in %d scenes: %d\n', length(all_scenes),...
                                        scenes_count_struct.total);

end



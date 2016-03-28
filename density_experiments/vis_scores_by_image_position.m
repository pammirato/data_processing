%displays an image representing the scores for each image in the scene


%TODO  - what to add next

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'all'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


custom_categories_list = {'chair','bottle'}; %which categories to use
group_by_category = 0;%whether to group instances by category or not



label_name = 'all';%make this 'all' to do it for all labels, 'bigBIRD' to do bigBIRD stuff
use_custom_labels = 1;
custom_labels_list = {'chair5','chair6'};




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


  %get names of all labels           
  all_labels = get_names_of_X_for_scene('instance_labels');
  
  %decide which labels to process    
  if(use_custom_labels && ~isempty(custom_labels_list))
    all_labels = custom_labels_list;
  elseif(strcmp(label_name,'bigBIRD'))
    temp = dir(fullfile(BIGBIRD_BASE_PATH));
    temp = temp(3:end);
    all_labels = {temp.name};
  elseif(strcmp(label_name, 'all'))
    all_labels = all_labels;
  else
    all_labels = {label_name};
  end



  %% 
  
  for j=1:length(all_labels)
   
    cur_label_name = all_labels{j};

     
  
  end%for j, each label








end%for each scene



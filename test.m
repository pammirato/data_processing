%description of file 
 return;

%TODO  - what to add next

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'all'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


label_name = 'bottle4';%make this 'all' to do it for all labels, 'bigBIRD' to do bigBIRD stuff
use_custom_labels = 0;
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


  
  movefile(fullfile(scene_path, LABELING_DIR, 'bounding_boxes_by_image_instance_level'), ... 
           fullfile(scene_path, LABELING_DIR, BBOXES_BY_IMAGE_INSTANCE_DIR));


  movefile(fullfile(scene_path, LABELING_DIR, 'bounding_boxes_by_image_class_level'), ... 
           fullfile(scene_path, LABELING_DIR, BBOXES_BY_IMAGE_CLASS_DIR));


  movefile(fullfile(scene_path, LABELING_DIR, 'bounding_boxes_by_category'), ... 
           fullfile(scene_path, LABELING_DIR, BBOXES_BY_CLASS_DIR));




end%for i,  each scene



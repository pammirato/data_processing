%converts .ply file with object point cloud to .mat file, while also scaling
% the coordinates of the points.  


%TODO  - what to add next

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'SN208_k1'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


label_name = 'laptop';%make this 'all' to do it for all labels, 'bigBIRD' to do bigBIRD stuff
use_custom_labels = 0;
custom_labels_list = {};



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




  %get the map to find all the images that 'see' each label
  label_to_images_that_see_it_map = load(fullfile(meta_path,LABELING_DIR,...
                                      DATA_FOR_LABELING_DIR, ...
                                      LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE));
   
  label_to_images_that_see_it_map = label_to_images_that_see_it_map.( ...
                                                  LABEL_TO_IMAGES_THAT_SEE_IT_MAP);
  
  %get names of all labels           
  all_labels = label_to_images_that_see_it_map.keys;
  
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







  %load image_structs file to get the scale for this scene
  image_structs_file = load(fullfile(scene_path, 'image_structs.mat'));
  scale = image_structs_file.scale;  


  %for each label, process  its point cloud
  for j=1:length(all_labels) %num_labels
         
    %load the .ply file
    p_cloud  = pcread(fullfile(meta_path, LABELING_DIR, OBJECT_POINT_CLOUDS, ...
                              ORIGINAL_POINT_CLOUDS,strcat(label_name, '.ply'))); 


    
    locs = p_cloud.Location * scale;
    %p_cloud.Location = p_cloud.Location * scale;   
 
    norms = p_cloud.Normal * scale;
    %p_cloud.Normal = p_cloud.Normal * scale;   

    scaled_p_cloud = pointCloud(locs,'Color', p_cloud.Color, 'Normal', norms);

    pcwrite(scaled_p_cloud, fullfile(meta_path, LABELING_DIR, OBJECT_POINT_CLOUDS, ...
                              SCALED_POINT_CLOUDS,strcat(label_name, '.ply'))); 

  end% for j, each label_name
end%for i,  each scene



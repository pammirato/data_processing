function update_instance_ids(scene_name, label_type)
%Changes the numberic instance id label for all bounding boxes
%to match what is in the text file instance_id_map.txt
%
%
%INPUTS:
%         scene_name: char array of single scene name, 'all' for all scenes, 
%                     or a cell array of char arrays, one for each desired scene
%         label_type: OPTIONAL 'raw_labels'(default) or 'verified_labels'
%


%Updates the numeric instance id of all labels for a scene(s) using the 
%text file instance_id_map.txt 

%TODO  -  function?


%CLEANED - yes 
%TESTED - yes

%initialize contants, paths and file names, etc. init;
init;


%% USER OPTIONS


%whether or not to run for the scenes in the custom list
%scene_name = 'Kitchen_Living_08_2';
if(iscell(scene_name))
  use_custom_scenes = 1;  custom_scenes_list = scene_name; 
else
  use_custom_scenes = 0;
end

%set default label_type if not inputted by user
if(nargin > 1)
  label_type = 'raw_labels'; 
end

label_loc = 'meta'; %which path to use: scene or meta 
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
  scene_path = fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %set label_path, where to load the labels from
  if(strcmp(label_loc,'meta'))
    label_path = meta_path;
  else
    label_path = scene_path;
  end


  %get a list of all the instances in the scene
  instance_name_to_id_map = get_instance_name_to_id_map();
  instance_names = keys(instance_name_to_id_map);

  %for each instance, add a box to each image's cell that this instance is in
  for jl=1:length(instance_names)
    cur_instance_name = instance_names{jl}; 
    cur_instance_file_name = strcat(cur_instance_name, '.mat');
    disp(cur_instance_name);
 
    %load the boxes for this instance and make a map
    try
      cur_instance_labels= load(fullfile(label_path,LABELING_DIR, label_type, ...
                                  BBOXES_BY_INSTANCE, cur_instance_file_name));
    catch
      %this instance may not be in this scene, so skip it
      continue;
    end
    %get the image names and boxes for this instance from the loaded file struct 
    image_names = cur_instance_labels.image_names;
    boxes = cur_instance_labels.boxes; 

    %get the numeric id for this instance name from the map    
    cur_instance_id = instance_name_to_id_map(cur_instance_name);

    %set the id field of all the boxes to be this id
    boxes(:,5) = cur_instance_id;

    %save the boxes
    save(fullfile(label_path,LABELING_DIR, label_type, ...
                                  BBOXES_BY_INSTANCE, cur_instance_file_name), ...
                              'image_names', 'boxes');
                  

  end %for jl, each instance

  %update the other box format for this scene(boxes by image)
  convert_boxes_by_instance_to_image_instance(scene_name,label_type);
end%for il,  each scene

end


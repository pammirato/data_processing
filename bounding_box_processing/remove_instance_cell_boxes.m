%Switches boxes from cell array to mat(numeric matrix). Probably not useful anymore,  
% ws used to switch format

%TODO  -  delete this whole file


%CLEANED -  
%TESTED - 

%initialize contants, paths and file names, etc. init;
init;


%% USER OPTIONS


%whether or not to run for the scenes in the custom list
scene_name = 'Bedroom_01_1';
if(iscell(scene_name))
  use_custom_scenes = 1;  custom_scenes_list = scene_name; 
else
  use_custom_scenes = 0;
end

%set default label_type if not inputted by user
  label_type = 'raw_labels'; 

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
    cur_instance_id = instance_name_to_id_map(cur_instance_name);
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
    boxes_org = boxes;
    if(strcmp(class(boxes), 'cell'))
      try
      boxes = cell2mat(boxes);
      catch
        boxes(end) = [];
        boxes_org(end) = [];
        boxes = cell2mat(boxes);
      end
      if(size(boxes,1) < length(boxes_org))
        boxes = cell2mat(boxes_org');
      end
    else
      continue;
    end  
      save(fullfile(label_path,LABELING_DIR, label_type, ...
                                  BBOXES_BY_INSTANCE, cur_instance_file_name), ...
                              'image_names', 'boxes');
                  

  end %for jl, each instance
end%for il,  each scene




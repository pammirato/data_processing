%converts structs from vatic output to a cleaner form 



%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'SN208_2cm_paths'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 




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

  %get a list of all the instances in the scene
  all_instance_names = get_names_of_X_for_scene(scene_name,'instance_labels'); 



  %for each instance, add a box to each image's struct that has this instance
  for j=1:length(all_instance_names)
    cur_instance_file_name = all_instance_names{j};
    cur_instance_name = cur_instance_file_name(1:end-4);   
 
    %load the boxes for this instance
    cur_instance_labels_file = load(fullfile(scene_path,LABELING_DIR, ...
                                  BBOXES_BY_INSTANCE_DIR, cur_instance_file_name));
    cur_instance_labels = cell2mat(cur_instance_labels_file.annotations);


    %get the bounding box and image name
    bboxes = double([cur_instance_labels.xtl; cur_instance_labels.ytl; ...
              cur_instance_labels.xbr;cur_instance_labels.ybr]');
    image_names = {cur_instance_labels.frame};

    %remove unwanted fields
    cur_instance_labels = rmfield(cur_instance_labels, 'generated');
    cur_instance_labels = rmfield(cur_instance_labels, 'lost');
    cur_instance_labels = rmfield(cur_instance_labels, 'occluded');
    cur_instance_labels = rmfield(cur_instance_labels, 'ybr');
    cur_instance_labels = rmfield(cur_instance_labels, 'label');
    cur_instance_labels = rmfield(cur_instance_labels, 'xbr');
    cur_instance_labels = rmfield(cur_instance_labels, 'ytl');
    cur_instance_labels = rmfield(cur_instance_labels, 'frame');
    cur_instance_labels = rmfield(cur_instance_labels, 'attributes');
    cur_instance_labels = rmfield(cur_instance_labels, 'xtl');
    cur_instance_labels = rmfield(cur_instance_labels, 'id');


    %prepare bboxes for addition to struct
    bboxes_cell = mat2cell(bboxes,ones(1,size(bboxes,1)),4);

    %add the wanted fields
    [cur_instance_labels.image_name] = image_names{:};
    [cur_instance_labels.bbox] = bboxes_cell{:}; 
    
    %save the new file
    annotations = cur_instance_labels;
    save(fullfile(scene_path,LABELING_DIR,BBOXES_BY_INSTANCE_DIR, ...
                  cur_instance_file_name), 'annotations');

  end%for j, each instance name
end%for each scene



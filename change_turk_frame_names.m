%changes frame name in turk annotation structs to names that match image names in rgb directory 


%initialize contants, paths and file names, etc. 
init;

%TODO - test


%% USER OPTIONS

scene_name = 'SN208_Density_1by1'; %make this = 'all' to run all scenes
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
  meta_path =fullfile(ROHIT_META_BASE_PATH, scene_name);


  instance_names = get_names_of_X_for_scene(scene_path,'instance_labels');

  for j=1:length(instance_names)
    i_name = instance_names{j};

    i_mat = load(fullfile(scene_path,LABELING_DIR,BBOXES_BY_INSTANCE_DIR,i_name));


    image_names = get_names_of_X_for_scene(meta_path,'images_for_labeling');


    annotations = i_mat.annotations;

    for k=1:length(annotations)
        ann = annotations{k};

        cur_name = image_names{ann.frame + 1}; 

        %ann.frame = str2num(cur_name(1:10));
        ann.frame = strcat(cur_name(1:10),'.png');

        annotations{j} = ann;
    end%for k, each annotation

    i_mat.annotations = annotations;

    save(fullfile(scene_path,LABELING_DIR,BBOXES_BY_INSTANCE_DIR,i_name),'-struct','i_mat');

  end%for j ,each instance 
end%for i,  each scene






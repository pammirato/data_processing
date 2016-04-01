%description of file 


%TODO  - what to add next

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'SN208_Density_2by2_same_chair'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


recognition_system_name = 'fast_rcnn';



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


  %get names of all images in the scene
  all_image_names = get_names_of_X_for_scene(scene_name, 'rgb_images');

  %for each image, get its recognition output and and format it
  for j=1:length(all_image_names)
  
    %get the image name and change the extenstion for the .mat
    cur_image_name = all_image_names{j};
    cur_mat_name = strcat(cur_image_name(1:10), '.mat');


    if(strcmp(recognition_system_name, 'fast_rcnn'))
    %fast-rcnn is easy, just save it as a struct   

 
      %load the file 
      cur_recognition_file = load(fullfile(meta_path, RECOGNITION_DIR, ...
                           recognition_system_name, BBOXES_BY_IMAGE_CLASS_DIR, cur_mat_name));

      %get the detection structs
      cur_rec_struct = cur_recognition_file.dets;
   
      %save it as a struct 
      save(fullfile(meta_path, RECOGNITION_DIR, recognition_system_name, ...
                    BBOXES_BY_IMAGE_CLASS_DIR, cur_mat_name), '-struct', 'cur_rec_struct');
     
    end%if, check recognition system
  end%for j, each image name
end%for i,  each scene



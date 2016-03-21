% produces one struct per image, with each field being an instance and each value being the
% bounding box for that instance in the image. 


%TODO  - add option to just add a single instance to existing img_structs 

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'SN208_Density_2by2_same_chair'; %make this = 'all' to run all scenes
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
  scene_path = fullfile(ROHIT_BASE_PATH, scene_name);

  %get a list of all the instances in the scene
  all_instance_names = get_names_of_X_for_scene(scene_name,'instance_labels'); 


  %get names of all the images in the scene
  all_image_names  = get_names_of_X_for_scene(scene_name, 'rgb_images');

  %make a struct for each image, and put them all in a map based on name

  %make a cell array with an empty struct in each cell
  temp = repmat(struct,length(all_image_names),1);
  all_structs = mat2cell(temp,repmat(1,length(all_image_names),1),1);

  %make the struct
  img_structs_map = containers.Map(all_image_names,all_structs);  

   

  %% populate the structs
  
  %for each instance, add a box to each image's struct that has this instance
  for j=1:length(all_instance_names)
    cur_instance_file_name = all_instance_names{j};
    cur_instance_name = cur_instance_file_name(1:end-4);   
 
    %load the boxes for this instance
    cur_instance_labels_file = load(fullfile(scene_path,LABELING_DIR, ...
                                  BBOXES_BY_INSTANCE_DIR, cur_instance_file_name));
    cur_instance_labels = cell2mat(cur_instance_labels_file.annotations);

    %for each instance label, add it to the corresponding image struct
    for k=1:length(cur_instance_labels)
      cur_label = cur_instance_labels(k);

      %get the name of the image for this label
      cur_image_name = cur_label.frame;

      %get the struct for this image, add this label, update the struct map
      cur_img_struct = img_structs_map(cur_image_name);
      cur_img_struct.(cur_instance_name) = [cur_label.xtl, cur_label.ytl, ...
                                            cur_label.xbr, cur_label.ybr];
      img_structs_map(cur_image_name) = cur_img_struct;


    end% for k, each instance label 
  end%for j, each instance 
  

  %now save each struct in img_structs_map to its own file
  for j=1:length(all_image_names)
  
    cur_image_name = all_image_names{j};
    cur_img_struct = img_structs_map(cur_image_name);



    save(fullfile(scene_path,LABELING_DIR,BBOXES_BY_IMAGE_INSTANCE_DIR, ...
                  strcat(cur_image_name(1:10),'.mat')), '-struct', 'cur_img_struct');

  end %for j


end%for each scene



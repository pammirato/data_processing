
%TODO

%CLEANED - no 
%TESTED - no


%clearvars;
%initialize contants, paths and file names, etc. 
 init;



%% USER OPTIONS

scene_name = 'Home_04_2'; %make this = 'all' to run all scenes
model_number = '0';
%use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
%custom_scenes_list = {'Bedroom_01_1', 'Kitchen_Living_01_1', 'Kitchen_Living_02_1', 'Kitchen_Living_03_1', 'Kitchen_Living_04_2', 'Kitchen_05_1', 'Kitchen_Living_06', 'Office_01_1'};%populate this 



label_type = 'verified_labels';

%which instances to use
label_to_process = 'all'; %make 'all' for every label
label_names = {label_to_process};



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




%% MAIN LOOP

for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %get the names of all the labels
  if(strcmp(label_to_process, 'all'))
    instance_name_to_id_map = get_instance_name_to_id_map();
    label_names = keys(instance_name_to_id_map);
  end





  %% get info about camera position for each image
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;


  %rename image names in image structs
  for jl=1:length(image_structs)
    cur_struct = image_structs(jl);
    img_name = cur_struct.image_name;
    img_name = strcat(img_name(1:10), '.jpg');
    cur_struct.image_name = img_name;
    image_structs(jl) = cur_struct; 
  end

  save(fullfile(meta_path,'reconstruction_results', ...
                 'colmap_results', model_number,IMAGE_STRUCTS_FILE),...
                  'image_structs', 'scale');


  




  %rename image names in instance labels
  for jl=1:length(label_names)
    
    %get the name of the label
    cur_label_name = label_names{jl};
    disp(cur_label_name);%display progress


    %load the boxes for this instance                
    try
      cur_instance_boxes = load(fullfile(meta_path, LABELING_DIR, label_type, ...
                              BBOXES_BY_INSTANCE, strcat(cur_label_name, '.mat')));
    catch
      %this instance hasn't been labeled yet, skip it
      continue;
    end
    

    %get all the image names and boxes for the instance 
    image_names = cur_instance_boxes.image_names; 
    cur_instance_boxes = cur_instance_boxes.boxes;

    assert(length(image_names) == size(cur_instance_boxes,1));

    

    %% for each box,image classify the box 
    for kl = 1:length(image_names) 
      cur_name = image_names{kl};
      cur_name = strcat(cur_name(1:10),'.jpg');
      image_names{kl} = cur_name; 
    end%for kl, each image name

    %create the struct for the boxes
    boxes = cur_instance_boxes;
    %save 
    save(fullfile(meta_path,LABELING_DIR, label_type, ...
                            BBOXES_BY_INSTANCE,...
                             strcat(cur_label_name, '.mat')),...
                               'boxes' ,'image_names');

  end%for jl, each instance label name 

  convert_boxes_by_instance_to_image_instance(scene_name, label_type);
end%for il, each scene_name




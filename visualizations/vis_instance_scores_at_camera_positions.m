
%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Kitchen_Living_02_1'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


recognition_system_name = 'ssd_bigBIRD';


instance_name = 'all';%make this 'all' to do it for all labels, 'bigBIRD' to do bigBIRD stuff
use_custom_instances = 0;
custom_instances_list = {};




show_figures = 1;
save_figures = 1;
save_results = 1;

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

  %get all the instance labels in this scene
  all_instance_names = get_names_of_X_for_scene(scene_name, 'instance_labels');



   %decide which labels to process    
  if(use_custom_instances && ~isempty(custom_instances_list))
    all_instance_names = custom_instances_list;
  elseif(strcmp(instance_name,'bigBIRD'))
    temp = dir(fullfile(BIGBIRD_BASE_PATH));
    temp = temp(3:end);
    all_instance_names = {temp.name};
  elseif(strcmp(instance_name, 'all'))
    all_instance_names = all_instance_names;
  else
    all_instance_names = {instance_name};
  end


  %load image_structs for all images
  image_structs_file =  load(fullfile(meta_path, 'reconstruction_results', ...
                                group_name, 'colmap_results', ...
                                model_number, IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;

  %get a list of all the image file names
  image_names = {image_structs.(IMAGE_NAME)};

  %make a map from image name to image_struct
  image_structs_map = containers.Map(image_names,...
                                 cell(1,length(image_names)));
  %populate the map
  for jl=1:length(image_names)
    image_structs_map(image_names{jl}) = image_structs(jl);
  end


  %get all the image names in the scene
  all_image_names = get_names_of_X_for_scene(scene_name,'rgb_images'); 

  
  instance_images_map = containers.Map(all_instance_names, cell(1,length(all_instance_names)));

  
  for j=1:length(all_instance_names)
   
    cur_instance_name = all_instance_names{j};


    %load all detections for this instance
    detections_file = load(fullfile(meta_path, RECOGNITION_DIR, ...
                                       recognition_system_name, BBOXES_BY_INSTANCE_DIR, ...
                                      strcat(cur_instance_name, '.mat')));
 

     
    all_detections_for_instance = detections_file.detections;
    

    figure; 
    hold on;
    colors = colormap;
    
    for k=1:length(all_detections_for_instance)

      cur_detection = all_detections_for_instance(k);

    
      cur_image_name = cur_detection.image_name;
      bbox = cur_detection.bbox;
      if(bbox(5) > 0)
        breakp=1;
      end
      
      cur_image_struct = image_structs_map(cur_image_name);
      
      cam_pos = cur_image_struct.world_pos*scale;
      
      plot(cam_pos(1), cam_pos(3), '.','MarkerSize', 20, 'Color', colors(floor(bbox(5)*63 + 1), :));
 
    end
    
    hold off;
  end%for j, each instance_name


end%for each scene


if(~show_figures)
  close all;
end

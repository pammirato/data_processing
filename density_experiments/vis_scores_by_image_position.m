%shows bounding boxes by image, with many options.  Can view vatic outputted boxes,
%results from a recognition system, or both. Also allows changing of vatic boxes. 

%TODO  - add scores to rec bboxes
%      - add labels to rec bboxes
%      - move picking labels to show outside of loop

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'SN208_Density_2by2_same_chair'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


grid_size = 21;

recognition_system_name = 'fast_rcnn';

group_by_class = 1;
classes = {'chair','bottle'};

show_figures = 0;
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

  %get all the image names in the scene
  all_image_names = get_names_of_X_for_scene(scene_name,'rgb_images'); 

  
  instance_images_map = containers.Map(all_instance_names, cell(1,length(all_instance_names)));

  
  for j=1:length(all_instance_names)
   
    cur_instance_name = all_instance_names{j};


    cur_instance_results = -zeros(grid_size,grid_size);

    %load all detections for this instance
    detections_file = load(fullfile(meta_path, RECOGNITION_DIR, ...
                                       recognition_system_name, BBOXES_BY_INSTANCE_DIR, ...
                                        cur_instance_name));
  
    all_detections_for_instance = detections_file.detections;
    

    for k=1:length(all_detections_for_instance)

      cur_detection = all_detections_for_instance(k);

      cur_image_name = cur_detection.image_name;
      %get the 'position index' of the image
      image_index = str2double(cur_image_name(1:6)) -1;
      %get row and column in the grid
      col = 1 + floor(image_index/grid_size);
      row = mod(image_index,grid_size) +1;

      cur_bbox = cur_detection.bbox;
      if(~isempty(cur_bbox))
        cur_score = cur_bbox(5); 
        cur_instance_results(row,col) = cur_score;
      end
    end%for k, each detection

    if(show_figures)
      f = figure;
    else
      f = figure('Visible', 'off');
    end 

    %lose file extension
    cur_instance_name = cur_instance_name(1:end-4);

    %plot the results as an image
    imagesc(cur_instance_results);
    hold on;
    title(cur_instance_name);
    h = colorbar;
    caxis([0,1]);
    ylabel(h, 'Score (-1 means no box)');%color bar label
    xlabel('X Poisiton (1 = 10cm)');
    ylabel('Y Poisiton (1 = 10cm)');


    if(save_figures)
      saveas(f, fullfile(meta_path,DENSITY_EXPERIMENTS_DIR, recognition_system_name, ...
                          SCORE_IMAGES_DIR, strcat(cur_instance_name, '.jpg')));
    end

    %close the figure if we are not showing it
    if(~show_figures)
      close(f);
    end


    if(save_results)
      scores_grid = cur_instance_results;
      save(fullfile(meta_path,DENSITY_EXPERIMENTS_DIR, recognition_system_name, ...
                    SCORE_ARRAYS_BY_INSTANCE_DIR, strcat(cur_instance_name, '.mat')), ...
                    'scores_grid');
    end
  
  end%for j, each instance_name








%  %for each class have multiple images
%  class_to_images_map = containers.Map(classes, cell(1,length(classes)));
%  for j=1:length(classes)
%    class_to_images_map.(classes{j}) = containers.Map(); 
%  end%for j, each class
%  
% 
%
%  %for each instance make an image
%  for j=1:length(all_instance_names)
%    cur_instance_name = all_instance_names{j};
%    cur_class_name = get_class_name_from_intance_name(cur_instance_name);
%
%    %if the class is one of the classes the user chose to display,
%    %then make an empty 'image'(array),and put it in the map for that class
%    try
%      instance_to_images_map = class_to_images_map(cur_class_name):
%      instance_to_images_map.(cur_instance_name) = zeros(grid_size,grid_size);
%      class_to_images_map(cur_class_name) = instance_to_image_map;
%    catch
%      %if we are not using this class do nothing
%    end
%  end%for j, each instance name






end%for each scene


if(~show_figures)
  close all;
end

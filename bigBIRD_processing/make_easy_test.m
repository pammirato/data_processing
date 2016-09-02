%shows bounding boxes by image, with many options.  Can view vatic outputted boxes,
%results from a recognition system, or both. Also allows changing of vatic boxes. 

%TODO  - add scores to rec bboxes
%      - add labels to rec bboxes
%      - move picking labels to show outside of loop
clearvars;
%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
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

for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


  instance_names = get_names_of_X_for_scene(scene_name, 'instance_labels');

  average_precision = zeros(1,length(instance_names));
  for jl=1:length(instance_names)
    cur_instance_name = instance_names{jl};
    gt_labels = load(fullfile(meta_path, 'labels', 'strict_labels', ...
                              'bounding_boxes_by_instance', strcat(cur_instance_name, '.mat'))); 
                            
    gt_boxes = gt_labels.boxes; %reshape(cell2mat(gt_labels.boxes),length(gt_labels.boxes),4);
    gt_image_names = gt_labels.image_names;
  

    for kl=1:length(gt_image_names)
      cur_image_name = gt_image_names{kl};
      img = imread(fullfile(scene_path, 'rgb', cur_image_name));

      cur_gt_box = gt_boxes{kl};

      start_row = max(1,cur_gt_box(2) - randi(200, 1,1));
      end_row = min(size(img,1),cur_gt_box(4) + randi(200, 1,1));
      start_col = max(1,cur_gt_box(1) - randi(200,1,1));
      end_col = min(size(img,2),cur_gt_box(3) + randi(200,1,1));
   

      new_img = img(start_row:end_row, start_col:end_col,:);

      imshow(new_img);
      ginput(1); 

      imwrite(new_img,fullfile(scene_path, 'easy_rgb', cur_image_name));
    end%for kl, each gt image name
  end%for jl, each instance
end 


 


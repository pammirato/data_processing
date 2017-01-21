function clean_boxes_max_dims(scene_name, label_type)
% assigns a label to each bounding box indicating how difficult it may
% for a detection system to duplicate
%
% It assumed boxes follow the following format:
%
%   [xmin ymin xmax ymax cat_id hardness ...]
%
%INPUTS:
%         scene_name: char array of single scene name, 'all' for all scenes, 
%                     or a cell array of char arrays, one for each desired scene
%         label_type: OPTIONAL 'verified_labels'(default) or 'raw_labels'
%

%TODO

%CLEANED - no 
%TESTED - no


%clearvars;
%initialize contants, paths and file names, etc. 
 init;



%% USER OPTIONS

%scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
model_number = '0';
%use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
%custom_scenes_list = {'Bedroom_01_1', 'Kitchen_Living_01_1', 'Kitchen_Living_02_1', 'Kitchen_Living_03_1', 'Kitchen_Living_04_2', 'Kitchen_05_1', 'Kitchen_Living_06', 'Office_01_1'};%populate this 





%which instances to use
label_to_process = 'all'; %make 'all' for every label
label_names = {label_to_process};

if(nargin <2)
  label_type = 'verified_labels';  %raw_labels - automatically generated labels
end                                %verified_labels - boxes looked over by human


debug =0;

kImageWidth = 1920;
kImageHeight = 1080;
%% SET UP GLOBAL DATA STRUCTURES


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





  %for each  instance label
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
      %get the image name, and the coressponding image struct     
      cur_image_name = image_names{kl};

      %get the true labeled box and its dimensions 
      box = cur_instance_boxes(kl,:);

      if(box(3) > 1920 || box(4) > 1080)
        breakp = 1;
      end
      box(1) = max(1,box(1));
      box(2) = max(1,box(2));
      box(3) = min(1920,box(3));
      box(4) = min(1080,box(4));
  
      

      %add the hardness meseaure to the box 
      cur_instance_boxes(kl,:) = box;
    end%for kl, each image name

    %% save the newly classified boxes for this instance label

    %create the struct for the boxes
    boxes = cur_instance_boxes;
    %cur_instance_boxes = struct('image_names', cell(1), ...
    %                            'boxes', cell(1));
    %cur_instance_boxes.image_names = image_names;
    %cur_instance_boxes.boxes = boxes;
    %save 
    save(fullfile(meta_path,LABELING_DIR, label_type, ...
                            BBOXES_BY_INSTANCE,...
                             strcat(cur_label_name, '.mat')),...
                               'boxes' ,'image_names');

  end%for jl, each instance label name 

  convert_boxes_by_instance_to_image_instance(scene_name, label_type);
end%for il, each scene_name

end



%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object


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

for i=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{i};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


  instance_names = get_names_of_X_for_scene(scene_name, 'instance_labels');


  labeled_image_names = dir(fullfile(meta_path, 'labels','raw_labels', 'bounding_boxes_by_image_instance',...
                                '*.mat'));
  labeled_image_names = {labeled_image_names.name};


  image_labels = cell(1,length(labeled_image_names));

  for jl=1:length(labeled_image_names)

    cur_image_name = labeled_image_names{jl};
    cur_struct = load(fullfile(meta_path, 'labels', 'raw_labels', 'bounding_boxes_by_image_instance', ...
                    strcat(cur_image_name(1:10), '.mat'))); 

    image_labels{jl} = cur_struct;
  end


  image_labels = cell2mat(image_labels);



  for jl=1:length(instance_names)
    

    cur_instance_name = instance_names{jl};
    
    disp(cur_instance_name);


    cur_instance_labels = {image_labels.(cur_instance_name)};

    assert(length(cur_instance_labels) == length(labeled_image_names));

    valid_image_names = cell(1,length(labeled_image_names));
    valid_boxes = cell(1,length(labeled_image_names));


    valid_counter = 0;
    for kl = 1:length(labeled_image_names) 

      cur_box =  cur_instance_labels{kl};
      if(isempty(cur_box))
        continue;
      end
    
      valid_counter = valid_counter+1;
      valid_boxes{valid_counter} = cur_box;
      img_name = labeled_image_names{kl};
      valid_image_names{valid_counter} = img_name(1:10); 
    end%for k, each image name
  
    valid_image_names = valid_image_names(~cellfun('isempty', valid_image_names));
    valid_boxes = valid_boxes(~cellfun('isempty', valid_boxes));
 
    image_names = valid_image_names;
    boxes = valid_boxes;
 
    save(fullfile(meta_path, 'labels', 'raw_labels', 'bounding_boxes_by_instance', ...
                  strcat(cur_instance_name,'.mat')), 'image_names', 'boxes');

   end%for jl, each instance name 

end%for i, each scene_name


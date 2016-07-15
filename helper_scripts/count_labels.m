%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object


clearvars;

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Kitchen_Living_03_1'; %make this = 'all' to run all scenes
group_name = 'all_minus_boring';
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


label_to_process = 'all'; %make 'all' for every label
label_names = {label_to_process};



do_occlusion_filtering = 1;
occlusion_threshold = 150;  %make > 12000 to remove occlusion thresholding 



debug =0;

kinect_to_use = 1;

%size of rgb image in pixels
kImageWidth = 1920;
kImageHeight = 1080;



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

categories = {'chair', 'diningtable', 'tv', 'couch'};
category_ids = {1,2,3,4}
instance_to_cat_id_map = containers.Map(categories, category_ids);





%% MAIN LOOP

for i=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{i};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);





  %get info about camera position for each image
  %image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', group_name, ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;




  %get a list of all the image file names
  %temp = cell2mat(image_structs);
  %image_names = {temp.(IMAGE_NAME)};
  image_names = {image_structs.(IMAGE_NAME)};


  %% MAIN LOOP

  count_struct = struct('chair', 0, 'diningtable', 0, 'tv', 0, 'couch',0);


  %for each point cloud
  for jl=1:length(image_names)
    

    cur_image_name = image_names{jl};

    cur_bboxes =  load(fullfile(meta_path, 'labels_pascal', 'instance_label_structs', ...
                    strcat(cur_image_name(1:10), '.mat'))); 

    instance_labels = fields(cur_bboxes);

    for kl=1:length(instance_labels)
      inst = instance_labels{kl};
      bbox = cur_bboxes.(inst);

      if(isempty(bbox))
        continue;
      end

      cat= inst(1:end-1);
      count_struct.(cat) =  count_struct.(cat) + size(bbox,1);

    end%kl 


   end%for jl, each image name

end%for i, each scene_name


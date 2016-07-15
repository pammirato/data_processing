%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object


clearvars;

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Kitchen_Living_04_2'; %make this = 'all' to run all scenes
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




  pose_image_names = dir(fullfile(meta_path, 'labels', 'pose_images', '*.png'));
  pose_image_names = {pose_image_names.name};


  %get info about camera position for each image
  %image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', group_name, ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;



  blank_struct = struct();
  blank_struct.image_name = '';
  for jl=1:length(pose_image_names)
    pi_name = pose_image_names{jl};
    split_name = strsplit(pi_name, '_');
    
    blank_struct.(split_name{2}) = []; 
  end


  label_structs = repmat(blank_struct, length(image_structs), 1);


  %get a list of all the image file names
  %temp = cell2mat(image_structs);
  %image_names = {temp.(IMAGE_NAME)};
  image_names = {image_structs.(IMAGE_NAME)};

  %make a map from image name to image_struct
  %image_structs_map = containers.Map(image_names, image_structs);


  image_structs_map = containers.Map(image_names,...
                                 cell(1,length(image_names)));

  for jl=1:length(image_names)
    image_structs_map(image_names{jl}) = image_structs(jl);
  end



  %% MAIN LOOP

  %for each point cloud
  for jl=1:length(image_names)
    

    cur_image_name = image_names{jl};

    cur_bboxes =  load(fullfile(meta_path, 'labels', 'instance_label_structs', ...
                    strcat(cur_image_name(1:10), '.mat'))); 

    cur_poses =  load(fullfile(meta_path, 'labels', 'pose_label_structs', ...
                    strcat(cur_image_name(1:10), '.mat'))); 



    %cur_bboxes.diningtable1 = cur_bboxes.dining_table1;
    %cur_bboxes.diningtable2 = cur_bboxes.dining_table2;

    %cur_bboxes = rmfield(cur_bboxes, 'dining_table1');
    %cur_bboxes = rmfield(cur_bboxes, 'dining_table2');


    instance_labels = fields(cur_poses);

    objects = zeros(length(instance_labels), 6);


    bad_inds =[];

    for kl=1:length(instance_labels)
      pose_angle = cur_poses.(instance_labels{kl});

      bbox = cur_bboxes.(instance_labels{kl});

      category = instance_labels{kl};
      category = category(1:end-1);

      cat_id = instance_to_cat_id_map(category); 

      objects(kl,1) = cat_id;
      
      if(~isempty(bbox))
        objects(kl,2:3) = bbox(1:2);

        width = bbox(3) - bbox(1);
        height = bbox(4) - bbox(2);

        objects(kl,4:5) = [width, height];
      else
        bad_inds(end+1) = kl;
      end


    
      objects(kl,6) = pose_angle;


    end%kl 


    objects(bad_inds,:) = [];

    if(size(objects,1) == 0)
      objects = [];
      continue;
    end

    %if(strcmp(cur_image_name, '0008970101.png'))
    %  breakp = 1;
    %end


    save(fullfile(meta_path, 'labels',scene_name, ...
                   'labels', strcat(cur_image_name(1:10), '.mat')), ...
                  'objects');

   end%for jl, each image name

end%for i, each scene_name


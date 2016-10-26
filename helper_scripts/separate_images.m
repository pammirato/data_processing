% Attempts to remove boring images to make reconstruction easier/faster


%CLEANED - yes 
%TESTED - yes 

%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

scene_name = 'Office_02_1'; %make this = 'all' to run all scenes
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};

boring_threshold = 50; 
cluster_size = 12;
min_images_per_cluster = 3;

debug = 0;

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

%for each scene, copy all images and rename the copy
for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %where to move the images
  moved_rgb_path = fullfile(meta_path, RECONSTRUCTION_SETUP, 'rgb_not_for_reconstruction');
  mkdir(moved_rgb_path);

  %path where all the images currently are
  rgb_image_path = fullfile(meta_path,RECONSTRUCTION_SETUP, 'rgb');

  %get all the image names
  image_names = dir(fullfile(rgb_image_path, '*.png'));
  image_names = {image_names.name};


  %set up data to make sure at least min_images_per_cluster images per cluster are kept
  org_num_images = length(image_names);
  num_clusters = org_num_images / cluster_size;

  %make sure each cluster has the same number of images
  assert(mod(org_num_images,cluster_size) == 0);

  %each cluster needs >= min_images_per_cluster pints, to define its circle
  min_images = num_clusters *min_images_per_cluster;

  %make data structure to keep track of how many images each cluster still has
  cluster_images_kept = ones(num_clusters, cluster_size);


  %% remove all the boring images 
  for jl = 1:length(image_names)

    %get the current image name and load the image
    cur_image_name = image_names{jl};
    rgb_img = imread(fullfile(rgb_image_path, cur_image_name));

    %display progress
    if(mod(jl, 50) == 0)
      disp(cur_image_name);
    end


    %get the metric to see if the image is boring
    metric = get_single_metric_for_image(rgb_img, 'boring');

    %if this image is boring, try to remove it
    if(metric < boring_threshold)
      [cluster_images_kept, success] = safe_remove_image_from_cluster(cluster_images_kept,...
                                                     cur_image_name, ...
                                                    min_images_per_cluster); 
   
      %if able to be removed, move the file to the new directory  
      if(success)
        movefile(fullfile(rgb_image_path, cur_image_name), ...
                  fullfile(moved_rgb_path, cur_image_name));
      end
      %show what kind of images are removed
      if(debug)
        imshow(rgb_img);
        hold on;
        title(num2str(metric));
        ginput(1);
      end%if debug
    end%if image is boring
  end%for jl, each image name
end%for il, each scene




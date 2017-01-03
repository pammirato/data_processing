%NOT USEED


%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object

%TODO -get rid of image structs map. Just use indexes. (Make it sorted?)


clearvars;

%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


label_to_process = 'all'; %make 'all' for every label
label_names = {label_to_process};

%how close in meters two points have to be to be considered the same point
similar_point_dist_thresh = .001;



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




%% MAIN LOOP

for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


  %% get info about camera position for each image
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', group_name, ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;

  %remove image structs that were not reconstructed. These will be hand labeled
  no_R_inds = cellfun('isempty', {image_structs.R});
  no_R_structs = image_structs(no_R_inds);
  image_structs = image_structs(~no_R_inds);

  %get a list of all the image file names
  image_names = {image_structs.(IMAGE_NAME)};

  %make a map from image name to image_struct
  image_structs_map = containers.Map(image_names,...
                                 cell(1,length(image_names)));
  %populate the map
  for jl=1:length(image_names)
    image_structs_map(image_names{jl}) = image_structs(jl);
  end

  image_order = randperm(length(image_names));
  image_names = image_names(image_order);


  image_names = {...
                 '0000110101.png', ...
                 '0000100101.png', ...
                 '0000180101.png', ...
                 '0000340101.png', ...
                 '0000350101.png', ...
                 '0000980101.png', ...
                 '0001360101.png', ...
                 '0001370101.png', ...
                 '0001490101.png', ...
                };




  cur_image_name = image_names{1};
  cur_image_struct = image_structs_map(cur_image_name);
  disp(cur_image_name);
  global_pc = pcread(fullfile(meta_path, 'point_clouds', strcat(cur_image_name(1:10), '.ply')));

  for jl= 2:length(image_names) 
    
    %if(~(mod(jl,8)==0))
    %  continue;
    %end
   
    %% get the image name, position/direction info 
    cur_image_name = image_names{jl};
    cur_image_struct = image_structs_map(cur_image_name);
    disp(cur_image_name);
    cur_pc =  pcread(fullfile(meta_path, 'point_clouds', strcat(cur_image_name(1:10), '.ply')));
  
    %find which points are at about the same point
    %dists = pdist2(global_pc.Location, cur_pc.Location); 
    %same = find(dists < similar_point_dist_thresh);
    comb_locs = [global_pc.Location; cur_pc.Location];
    comb_colors = [global_pc.Color; cur_pc.Color];
 
    global_pc = pointCloud(comb_locs, 'Color', comb_colors);
    global_pc = pcdownsample(global_pc, 'gridAverage', similar_point_dist_thresh);
    
    if(mod(jl,20) == 0)
      breakp = 1;
      pcwrite(global_pc, fullfile(meta_path, strcat('global_pc_choosy_1cm_', num2str(jl), '.ply')));  
      disp(jl);
    end

  end%for jl, each image name

end%for i, each scene_name


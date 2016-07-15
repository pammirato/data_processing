
%% USER OPTIONS

scene_name = 'all'; %make this = 'all' to run all scenes
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


  rgb_path =  fullfile(scene_path, 'rgb');
  depth_path =  fullfile(scene_path, 'high_res_depth');
  save_path = fullfile(scene_path, 'filled_high_res_depth');

  mkdir(save_path);

  rgb_image_names = dir(fullfile(rgb_path, '*.png'));
  rgb_image_names = {rgb_image_names.name};

  %for each image, make the filled depth image
  for jl=1:length(rgb_image_names)
    fprintf('%d of %d %s\n', jl, length(rgb_image_names), scene_name); 
    cur_rgb_name = rgb_image_names{jl};
    cur_depth_name = strcat(cur_rgb_name(1:8), '03.png');
    imgRgb = imread(fullfile(rgb_path, cur_rgb_name));
    imgDepthAbs = imread(fullfile(depth_path, cur_depth_name));


    imgDepthFilled = fill_depth_colorization(double(imgRgb), double(imgDepthAbs), 1);


    img_out = uint16(imgDepthFilled);

    imwrite(img_out, fullfile(save_path, strcat(cur_rgb_name(1:8), '04.png')));
  end
end



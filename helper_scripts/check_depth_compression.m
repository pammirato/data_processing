
%CLEANED - no 
%TESTED - ish 

clearvars;

%initialize contants, paths and file names, etc. 
init;

%% USER OPTIONS
%'Home_05_1',
scene_name = {  ...
              'Office_01_1', 'Office_01_2'}; %make this = 'all' to run all scenes
model_number = '0';


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


  disp(scene_name);

  image_names = get_scenes_rgb_names(scene_path);

  %now hand label each image, and save after image is labeled
  for jl=1:length(image_names)

    cur_img_name = image_names{jl};
    if(mod(jl,200) == 0)
      disp(jl);
    end

    org_dimg = imread(fullfile(scene_path, 'high_res_depth',  ...
                      strcat(cur_img_name(1:13), '03.png')));

    comp_dimg = imread(fullfile(meta_path, 'compressed_high_res_depth',  ...
                      strcat(cur_img_name(1:13), '03.png')));


    assert(max(abs(org_dimg(:)-comp_dimg(:))) == 0);


  end%for jl, each image name

end%for il, each scene


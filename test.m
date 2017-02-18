scenes = {'Home_01_1', 'Home_01_2', 'Home_02_1', 'Home_02_2', 'Home_03_1', 'Home_03_2', 'Home_04_1', 'Home_04_2', 'Home_05_1', 'Home_05_2', 'Home_06_1', 'Home_08_1', 'Home_08_2', 'Home_14_1', 'Home_14_2', 'Office_01_1', 'Office_01_2'};


scene_name = scenes(1:end)';


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
  scene_path = fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  a = dir(fullfile(scene_path,'high_res_depth'));
  b = dir(fullfile(scene_path,'jpg_rgb'));

  assert(length(a) == length(b));
  disp(length(a));

end

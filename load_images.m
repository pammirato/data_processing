%this function loads all the rgb and raw_depth images for a scene
%into cell arrays


init;


scene_name = 'Room15';





%setup paths
scene_path = fullfile(BASE_PATH, scene_name);
rgb_path = fullfile(scene_path, RGB_IMAGES_DIR);
depth_path = fullfile(scene_path,RAW_DEPTH_IMAGES_DIR);






rgb_dir = dir(rgb_path);
rgb_dir = rgb_dir(3:end);

depth_dir = dir(depth_path);
depth_dir = depth_dir(3:end);

%should be the same number of rgb and depth images
assert(length(rgb_dir) == length(depth_dir));


rgb_cell = cell(1,length(rgb_dir));
depth_cell = cell(1,length(rgb_dir));

%now load all the images
for(i=1:length(rgb_dir))

   cur_rgb_name = rgb_dir(i).name;
                         
%    rgb_cell{i} = imread(fullfile(rgb_path,cur_rgb_name));
   
   %rgb_cell{i} = imread(fullfile(scene_path,RGB_JPG_IMAGES_DIR, ...
   %                          strcat(cur_rgb_name(1:end-3), 'jpg'))); 
   
   
   

   cur_depth_name = strcat('raw_depth', cur_rgb_name(4:end));
   depth_cell{i} = imread(fullfile(depth_path, cur_depth_name));
    
end% for i



%make standard variable names

% rgb_var_name = matlab.lang.makeValidName('rgb_images_',scene_name);
% depth_var_name = matlab.lang.makeValidName('depth_images_',scene_name);
rgb_var_name = strcat('rgb_images_',scene_name);
depth_var_name = strcat('depth_images_',scene_name);



eval([rgb_var_name '= rgb_cell;']);
eval([depth_var_name '= depth_cell;']);


clear rgb_cell;
clear rgb_cell;






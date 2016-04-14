
rgb_base_path = fullfile(ROHIT_BASE_PATH, 'FB209_2cm_paths', 'rgb_to_rename');
depth_base_path = fullfile(ROHIT_BASE_PATH, 'FB209_2cm_paths', 'unreg_depth_to_rename');

counter = 506;


d = dir(fullfile(rgb_base_path, '*.png'));
image_names = {d.name};



for i=1:length(image_names)
  cur_name = image_names{i};

  full_rgb_name = fullfile(rgb_base_path,cur_name);
  full_depth_name = fullfile(depth_base_path, strcat(cur_name(1:8), '02.png'));  

  new_index =  sprintf('%06d', counter);
  new_name = strcat(new_index, '0101.png');

  new_rgb_name = fullfile(rgb_base_path,new_name);
  new_depth_name = fullfile(depth_base_path, strcat(new_name(1:8), '02.png'));  


  movefile(full_rgb_name, new_rgb_name);
  movefile(full_depth_name, new_depth_name);
  
  counter = counter+1
end


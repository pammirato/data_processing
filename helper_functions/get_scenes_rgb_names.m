function = [image_names] = get_scenes_rgb_names(scene_path)

  temp = dir(fullfile(scene_path,RGB,'*.jpg'));
  image_names = {temp.name}; 

end



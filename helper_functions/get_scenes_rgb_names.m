function [image_names] = get_scenes_rgb_names(scene_path)
%return names of all rgb images for given scene path
% just looks in rgb/ directory for .png files

  init;
  temp = dir(fullfile(scene_path,JPG_RGB,'*.jpg'));
  image_names = {temp.name}; 
end



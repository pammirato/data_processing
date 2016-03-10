function  [all_names] = get_names_of_X_for_scene(scene_path, items)

  init;
  all_names = {};

  switch items
    case 'rgb_images'
      temp = dir(fullfile(scene_path,RGB,'*.png'));
      all_names = {temp.name}; 
    case 'instance_labels'
      temp = dir(fullfile(scene_path,LABELING_DIR,BBOXES_BY_INSTANCE_DIR,'*.mat'));
      all_names = {temp.name};
    otherwise
      all_names = {}; 
  end
end



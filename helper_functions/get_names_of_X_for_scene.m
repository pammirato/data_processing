function  [all_names] = get_names_of_X_for_scene(scene_path, items, items2)

  init;
  all_names = {};

  switch items
    case 'rgb_images'
      temp = dir(fullfile(scene_path,RGB,'*.png'));
      all_names = {temp.name}; 
    case 'instance_labels'
      temp = dir(fullfile(scene_path,LABELING_DIR,BBOXES_BY_INSTANCE_DIR,'*.mat'));
      all_names = {temp.name};
    case 'images_for_labeling'
      if(exist('items2','var'))
        temp = dir(fullfile(scene_path,LABELING_DIR,'images_for_labeling', items2,'*.mat'));
        all_names = {temp.name};
      end
    otherwise
      all_names = {}; 
  end
end



function  [all_names] = get_names_of_X_for_scene(scene_name, items, items2)

  init;
  all_names = {};

  switch items
    case 'rgb_images'
      temp = dir(fullfile(ROHIT_BASE_PATH,scene_name,RGB,'*.png'));
      all_names = {temp.name}; 
    case 'instance_labels'
      temp = dir(fullfile(ROHIT_BASE_PATH,scene_name, ...
                          LABELING_DIR,BBOXES_BY_INSTANCE_DIR,'*.mat'));
      all_names = {temp.name};
    case 'images_for_labeling'
      if(exist('items2','var'))
        temp = dir(fullfile(ROHIT_META_BASE_PATH,scene_name, ...
                            LABELING_DIR,'images_for_labeling', items2,'*.jpg'));
        all_names = {temp.name};
      end
    case 'label_names'
      %get all of the label names label
      label_to_images_that_see_it_map = load(fullfile(ROHIT_META_BASE_PAHT, scene_name, ...
                                          LABELING_DIR, DATA_FOR_LABELING_DIR, ...
                                          LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE));
       
      label_to_images_that_see_it_map = label_to_images_that_see_it_map.( ...
                                                      LABEL_TO_IMAGES_THAT_SEE_IT_MAP);
      %get names of all labels           
      all_names = label_to_images_that_see_it_map.keys;
  

    otherwise
      all_names = {}; 
  end
end



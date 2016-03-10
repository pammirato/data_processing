function [bboxes] = get_bounding_boxes_struct_array(scene_path,instance_name)
  %returns a mat array of structs for each bounding box
  
  %TODO   - load other types of boxes

  init;

  instance_file = load(fullfile(scene_path,LABELING_DIR,BBOXES_BY_INSTANCE_DIR,instance_name));
  temp = instance_file.annotations;
  bboxes = cell2mat(temp);

end

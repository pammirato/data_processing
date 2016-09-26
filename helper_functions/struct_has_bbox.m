function [label_exists] = struct_has_bbox(annotations, label_name)
% returns 1 if the given struct of bounding boxes has a valid bounding box
% for the given label name

  %will hold the bounding box if the struct has one
  ann = [];

  if(isfield(annotations,label_name))
    ann = annotations.(label_name);
  end

  %a valid bounding box has 4 entries. (x,y) for top left and bottom right 
  label_exists = (length(ann) == 4);
end


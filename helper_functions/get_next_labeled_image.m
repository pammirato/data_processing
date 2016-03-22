function [image_struct, annotation] = get_next_labeled_image(base_image_name,...
                                                           image_structs_map,...
                                                           annotations_map, ...
                                                           label_name, ...
                                                           direction)

%returns image name and bounding box annotation of the given label name
% in the labeled image closest to the base_image_name in the given direction


  %get the image struct for the starting image
  base_image_struct = image_structs_map(base_image_name);

  %move next until we hit an image that has been labeled
  %there is a next pointer by the main assumption of this method
  cur_image_name = get_next_image_name(base_image_struct, direction);
  cur_annotation = [];

  while(isempty(cur_annotation))
    %get the annotation struct and see if it has the label
    cur_ann_struct = annotations_map(cur_image_name);

    %see if this image was annotated
    if(struct_has_bbox(cur_ann_struct,label_name))
      %if it was, save the bbox
      cur_annotation = cur_ann_struct.(label_name);
    else
      %if it wasnt, get the next image in the given direction 
      cur_image_struct = image_structs_map(cur_image_name);
      cur_image_name = get_next_image_name(cur_image_struct, direction); 
    end
  end%while next annotation is empty

  %set return values
  image_struct= image_structs_map(cur_image_name);
  annotation = cur_annotation;
end%function, get next labeled image



function [image_name] = get_next_image_name(image_struct,direction)
%return the image name from the pointer from the given direction

  image_name = '';
  switch direction
    case 'forward' 
      image_name = image_struct.translate_forward; 
    case 'backward' 
      image_name = image_struct.translate_backward; 
  end
end%function, get next image

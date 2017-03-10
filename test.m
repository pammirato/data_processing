for jl=1:length(label_structs)

    %get the next label struct and corresponding image name
    cur_struct = label_structs(jl);
    if(strcmp(cur_struct.image_name, ''))
      cur_struct.image_name = image_names{jl};
    end
    cur_image_name = cur_struct.image_name;
    cur_struct = rmfield(cur_struct,'image_name');

    %name the file to save the data for this image in
    save_file_path=fullfile(save_path, strcat(cur_image_name(1:10), '.mat'));

    %convert the label struct to ouput format, array of vectors
    %one vector per labels, [xmin, ymin, xmax, ymax, cat_id, hardness]
    cur_fields = fieldnames(cur_struct);
    boxes = cell(0);
    %lood through all instance names in the label struct
    for kl=1:length(cur_fields)
      %get id of this instance name
      inst_id = instance_name_to_id_map(cur_fields{kl});
      temp = cur_struct.(cur_fields{kl});
      if(isempty(temp))
        continue; %there is no label for this instance
      end
      boxes{end+1} = [temp inst_id 0];
    end%for kl
    boxes = cell2mat(boxes');


    %check for pre-existing labels, only overwrite newly generated labels
    if(exist(save_file_path, 'file'))
      prev_boxes = load(save_file_path);
      prev_boxes = prev_boxes.boxes; 
      if(~isempty(prev_boxes))
        inds_to_remove = zeros(1,size(boxes,1));
        for kl=1:size(boxes,1)
          inst_id = boxes(kl,5);
          prev_box_ind = find(prev_boxes(:,5) == inst_id);
          if(isempty(prev_box_ind))
            continue;
          end
          prev_boxes(prev_box_ind,:) = boxes(kl,:);
          inds_to_remove(kl) = 1; 
        end%for kl, each new box 
        boxes(find(inds_to_remove),:) = [];
        boxes = cat(1,boxes,prev_boxes);
      end
    end%if labels already exist
    
    boxes = double(boxes); %save space?
    %save the boxes to file 
    save(save_file_path, 'boxes');
end%for jl, each label struct
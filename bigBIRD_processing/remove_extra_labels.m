

img_path = fullfile('/playpen/ammirato/Data/background_composite_images_pose/');
label_path = fullfile('/playpen/ammirato/Data/background_labels_pose/');
delete_path = fullfile('/playpen/ammirato/Data/back_labels_to_delete');


label_names = dir(fullfile(label_path, '*.txt'));
label_names = {label_names.name};

for il=1:length(label_names)
  cur_label_name = label_names{il};

  

  cur_img_name = strcat(cur_label_name(1:end-3), 'jpg');


  if(~exist(fullfile(img_path,cur_img_name), 'file'))
    disp(cur_label_name);
    movefile(fullfile(label_path, cur_label_name), fullfile(delete_path, cur_label_name)); 
  end

end

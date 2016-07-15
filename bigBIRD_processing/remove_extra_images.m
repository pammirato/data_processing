

img_path = fullfile('/playpen/ammirato/Data/background_composite_images2/');
label_path = fullfile('/playpen/ammirato/Data/background_labels2/');
delete_path = fullfile('/playpen/ammirato/Data/back_imgs_to_delete');


img_names = dir(fullfile(img_path, '*.jpg'));
img_names = {img_names.name};

for il=1:length(img_names)
  cur_img_name = img_names{il};

  

  cur_label_name = strcat(cur_img_name(1:end-3), 'txt');


  if(~exist(fullfile(label_path,cur_label_name), 'file'))
    disp(cur_img_name);
    movefile(fullfile(img_path, cur_img_name), fullfile(delete_path, cur_img_name)); 
  end

end

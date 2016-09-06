clearvars;
init_bigBIRD;


%TODO - add   rotation
%             alpha composition
%             illumination
%





debug = 0;

d = dir(BIGBIRD_BASE_PATH);
object_names = {d(3:end).name};
%object_names = {'listerine_green'};


%load mapping from bigbird name ot category id
%obj_cat_map = containers.Map();
%fid_bb_map = fopen('/playpen/ammirato/Data/RohitMetaMetaData/big_bird_cat_map.txt', 'rt');
%
%line = fgetl(fid_bb_map);
%while(ischar(line))
%  line = strsplit(line);
%  obj_cat_map(line{1}) = str2double(line{2}); 
%  line = fgetl(fid_bb_map);
%end
%fclose(fid_bb_map);

save_base_path = fullfile('/playpen/ammirato/Data/new_masks_post');
load_base_path = fullfile('/playpen/ammirato/Data/new_masks2');


image_names = dir(fullfile(load_base_path, '*.png'));
image_names = {image_names.name};
for il=1:length(image_names)

  cur_image_name = image_names{il};
  img = imread(fullfile(load_base_path, cur_image_name));


  %% crop around the center
  row_offset = 250; 
  col_offset = 300;
  start_row = row_offset;
  end_row = 1024 - row_offset;
  start_col = col_offset;
  end_col = 1280-col_offset;


  resized_img = imresize(img, [525, 681]);

  final_img = zeros(1024, 1280);

  

  final_img(start_row:end_row, start_col:end_col, :) = resized_img;

  final_img = ~(final_img > 0);
  
  split_name = strsplit(cur_image_name, '_');
  label_name = split_name{1};
  for jl=2:(length(split_name)-2)
    label_name = strcat(label_name, '_');
    label_name = strcat(label_name, split_name{jl});
  end
  
  file_name = strcat(split_name{end-1}, '_');
  file_name = strcat(file_name, split_name{end});
  file_name(end-3:end) = [];
  file_name = strcat(file_name, '_mask.pbm');
  
  if(~exist(fullfile(save_base_path, label_name), 'dir'))
    mkdir(fullfile(save_base_path, label_name));
  end
  
  
  imwrite(final_img, fullfile(save_base_path, label_name, file_name));
  
end   
 

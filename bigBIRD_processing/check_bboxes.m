

img_path = fullfile('/playpen/ammirato/Data/background_composite_images/');
label_path = fullfile('/playpen/ammirato/Data/background_labels/');

img_names = dir(fullfile(img_path, '*.jpg'));
img_names = {img_names.name};

for il=1:length(img_names)
  cur_img_name = img_names{il};

  img = imread(fullfile(img_path, cur_img_name));

  fid_label = fopen(fullfile(label_path, strcat(cur_img_name(1:end-3), 'txt')));

  line = fgetl(fid_label);
  fclose(fid_label);
  line = strsplit(line);

  bbox = [str2double(line{2}) str2double(line{3}) str2double(line{4}) str2double(line{5})]; 

  height = bbox(4) - bbox(2);
  width = bbox(3) - bbox(1);



  imshow(img);

  hold on;
  rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], ...
               'LineWidth',2, 'EdgeColor','r');


  ginput(1);
end

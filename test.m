scene_name = 'Home_03_2';

scene_path = fullfile(ROHIT_BASE_PATH, scene_name);
meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


labels = load(fullfile(meta_path,'labels','verified_labels', ...
              'bounding_boxes_by_instance', 'nature_valley_sweet_and_salty_nut_peanut.mat'));

image_names = labels.image_names;
boxes = labels.boxes;

bad_inds = [];

for il=50:length(image_names)

  img_name = image_names{il};
  img = imread(fullfile(scene_path,'jpg_rgb', img_name));

  bbox = boxes(il,:); 
 
  hold off;
  imshow(img);
  hold on;
  rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], ...
               'LineWidth',2, 'EdgeColor','r');


  [~,~,but] = ginput(1);

  if(but == 3)
    disp(img_name);
    bad_inds(end+1) = il;    
  end 
end


boxes(bad_inds,:) = [];

image_names(bad_inds) = [];

save(fullfile(meta_path,'labels','verified_labels', ...
              'bounding_boxes_by_instance', 'nature_valley_sweet_and_salty_nut_peanut.mat'), ...
     'image_names', 'boxes');




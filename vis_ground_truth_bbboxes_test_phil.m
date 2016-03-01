%draws the bboxes on the images



init;

scene_name = 'SN208';

density = 1;
class_name = 'pringles_bbq';
label_name = class_name;%'monitor1';

scene_path = fullfile(BASE_PATH,scene_name);
if(density)
    scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
end
                       

boxes_path = fullfile(scene_path,'labeling','chair_boxes_per_image_concat');

boxes_name = dir(fullfile(boxes_path,'*.mat'));
boxes_name = {boxes_name.name};

for i=1:length(boxes_name)
    box_name= boxes_name{i};
    image_name = strcat(box_name(1:10),'.png');

    
    rgb_image = imread(fullfile(scene_path,RGB_IMAGES_DIR, image_name));
    
    imshow(rgb_image);
    hold on;
    
    
    a = load(fullfile(boxes_path,box_name));

    boxes = a.boxes;
    
    for j=1:size(boxes,1)
        bbox = boxes(j,:)
        rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');

    end
    
    ginput(1);
    hold off;
  %  save(fullfile(boxes_path,box_name),'boxes');
end








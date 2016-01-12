%draws the bboxes on the images



init;

room_name = 'FB209';

class_name = 'pringles_bbq';
label_name = class_name;%'monitor1';

scene_path = fullfile(BASE_PATH,scene_name);

labeled_boxes_path = fullfile(scene_path,LABELING_DIR, LABELED_BBOXES_DIR, label_name);



%load names of images we care about
map = load(fullfile(scene_path, LABELING_DIR, ...
                            DATA_FOR_LABELING_DIR, ...
                              LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE)); 
map = map.(LABEL_TO_IMAGES_THAT_SEE_IT_MAP);

label_structs = map(label_name);
temp = cell2mat(label_structs);
labeled_image_names = {temp.(IMAGE_NAME)};
clear temp;


ground_truth_bboxes= load(fullfile(scene_path,LABELING_DIR, GROUND_TRUTH_BBOXES_DIR, label_name, '/ground_truth_bboxes.mat'));
ground_truth_bboxes = ground_truth_bboxes.ground_truth_bboxes;






for i=1:length(labeled_image_names)
    
    cur_name = labeled_image_names{i};
    
    rgb_image = imread(fullfile(scene_path,RGB_IMAGES_DIR, cur_name));
    
    imshow(rgb_image);
    hold on;
    
    bbox = ground_truth_bboxes{i};
    
    rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
    
    
    ginput(1);
    hold off;
end





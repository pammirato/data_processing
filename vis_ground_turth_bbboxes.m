





room_name = 'KitchenLiving12';

class_name = 'monitor';
label_name = 'monitor1';

base_path =['/home/ammirato/Data/' room_name];

rgb_images_path = [base_path '/rgb/'];
labeled_names_path = [base_path '/labeling/' label_name '/']
%load names of images we care about
labeled_image_names = load([labeled_names_path 'labeled_image_names.mat']); 
labeled_image_names = labeled_image_names.labeled_image_names;

ground_truth_bboxes= load([base_path '/labeling/' label_name '/ground_truth_bboxes.mat']);
ground_truth_bboxes = ground_truth_bboxes.ground_truth_bboxes;






for i=1:length(labeled_image_names)
    
    cur_name = labeled_image_names{i};
    
    rgb_image = imread([rgb_images_path cur_name]);
    
    imshow(rgb_image);
    hold on;
    
    bbox = ground_truth_bboxes{i};
    
    rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
    
    
    ginput(1);
    hold off;
end






room_name = 'KitchenLiving12';

class_name = 'monitor';
label_name = 'monitor1';

base_path =['/home/ammirato/Data/' room_name];

rgb_images_path = [base_path '/rgb/'];
labeled_names_path = [base_path '/labeling/' label_name '/'];

write_path = [base_path '/labeling/' label_name '/'];



%load names of images we care about
labeled_image_names = load([labeled_names_path 'labeled_image_names.mat']); 
labeled_image_names = labeled_image_names.labeled_image_names;


%ground_truth_bboxes = cell(1,length(labeled_image_names));


% for i=366:length(labeled_image_names)
%     
%     cur_name = labeled_image_names{i};
%     
%     rgb_image = imread([rgb_images_path cur_name]);
%     
%     %get two points for bbox
%     pts = readPoints(rgb_image,1);
%     
%     if(length(pts) <2)
%        cur_bbox = [-1 -1 -1 -1];
%     else
%         cur_bbox = [pts(1) pts(2) 0 0];
%     end
%     
%     
%     ground_truth_bboxes{i} = cur_bbox;
%     
%     disp(i);
%     
% end%for i

for i=222:length(labeled_image_names)
    
    cur_name = labeled_image_names{i};
    
    rgb_image = imread([rgb_images_path cur_name]);
    
    cur_bbox = ground_truth_bboxes{i};
    
    
    
    %get two points for bbox
    pts = readPoints(rgb_image,1);
    
    if(length(pts) <2)
       cur_box(3) = -1;
       cur_box(4) = -1;
    else
        cur_bbox(3) = pts(1);
        cur_bbox(4) = pts(2);
    end
    
    
    ground_truth_bboxes{i} = cur_bbox;
    
    disp(i);
    
end%for i



save([write_path 'ground_truth_bboxes.mat'], ground_truth_bboxes);
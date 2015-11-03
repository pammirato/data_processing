%tool for making ground truth bounding boxes im a set of images, for one label

clear all, close all;
init;

scene_name = 'Room15';


%class_name = 'monitor';  
label_name = 'monitor1';  %what label will be given to every bounding box

scene_path = fullfile(BASE_PATH,scene_name);

write_path = fullfile(scene_path,LABELING_DIR, GROUND_TRUTH_BBOXES_DIR, 'label_name');
mkdir(write_path);



%load names of images we care about
map = load(fullfile(scene_path, LABELING_DIR, ...
                            DATA_FOR_LABELING_DIR, ...
                              LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE)); 
map = map.(LABEL_TO_IMAGES_THAT_SEE_IT_MAP);

label_structs = map(label_name);
temp = cell2mat(label_structs);
labeled_image_names = {temp.(IMAGE_NAME)};
clear temp;


holds all bboxes
ground_truth_bboxes = cell(1,length(labeled_image_names));



First label the top left corner of the bbox in every image, then the bottom right in every image
this is faster because the images are often close and so it takes less mouse movement




%label all the top left corners
for i=1:length(labeled_image_names)
     
    cur_name = labeled_image_names{i};
     
    rgb_image = imread(fullfile(scene_path, RGB_IMAGES_DIR, cur_name)); 
    
    imshow(rgb_image);

    %get the clicked on point for bbox
    [xi, yi, but] = ginput(1);
    %pts = readPoints(rgb_image,1);
     
    if(but~=1)%(length(pts) <2)
        cur_bbox = [-1 -1 -1 -1];
    else
	cur_bbox = [xi yi 0 0];
        %cur_bbox = [pts(1) pts(2) 0 0];
    end
     
     
    ground_truth_bboxes{i} = cur_bbox;
     
    disp(i);
     
end



%label all the bottom right corners
for i=1:length(labeled_image_names)
    
    cur_name = labeled_image_names{i};
    
    rgb_image = imread(fullfile(scene_path, RGB_IMAGES_DIR, cur_name));
    
    imshow(rgb_image);
    
    cur_bbox = ground_truth_bboxes{i};
    
    
    [xi, yi, but] = ginput(1);
    %pts = readPoints(rgb_image,1);
    
    if(but~=1)%(length(pts) <2)
       cur_box(3) = -1;
       cur_box(4) = -1;
    else
        cur_bbox(3) = xi %pts(1);
        cur_bbox(4) = yi %pts(2);
    end
    
    
    ground_truth_bboxes{i} = cur_bbox;
    
    disp(i);
    
end%for i



save(fullfile(write_path, 'ground_truth_bboxes.mat'), 'ground_truth_bboxes');


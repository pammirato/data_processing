%tool for making ground truth bounding boxes im a set of images, for one label

clear all, close all;
init;

scene_name = 'FB209';


%class_name = 'monitor';  
label_name = 'hunts_sauce' ;  %what label will be given to every bounding box


center_label = 0;



scene_path = fullfile(BASE_PATH,scene_name);

write_path = fullfile(scene_path,LABELING_DIR, GROUND_TRUTH_BBOXES_DIR, label_name);
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

% 
% holds all bboxes
ground_truth_bboxes = cell(1,length(labeled_image_names));



% First label the top left corner of the bbox in every image, then the bottom right in every image
% this is faster because the images are often close and so it takes less mouse movement

disp(length(labeled_image_names))

%figure('Position', [0, 0, 1800, 1000]);

%label all the top left corners
for i=1:length(labeled_image_names)
    
    
     
    cur_name = labeled_image_names{i};
    
     
    rgb_image = imread(fullfile(scene_path, RGB_IMAGES_DIR, cur_name)); 
    
    if(center_label)  
        ls = label_structs{i};
        display_image = uint8(zeros(2*size(rgb_image,1),2*size(rgb_image,2),3));
        center_pos = [size(rgb_image,1), size(rgb_image,2)];

        label_pos = double([ls.y ls.x]);

        diff_pos = center_pos - label_pos ;

        start_row = 1+diff_pos(1);
        end_row = start_row+size(rgb_image,1)-1;
        start_col = 1+diff_pos(2);
        end_col = start_col+size(rgb_image,2)-1;


        display_image(start_row:end_row,start_col:end_col,:) = rgb_image;

        imshow(display_image);

    else
        imshow(rgb_image);
    end
        

    %get the clicked on point for bbox
    [xi, yi, but] = ginput(1);
    %pts = readPoints(rgb_image,1);
    
    if(center_label)  
        xi = xi - diff_pos(2);
        yi = yi - diff_pos(1);
    end
    
    
    if(xi < 1)
        xi = 1;
    end
    if(xi > size(rgb_image,2))
        xi = size(rgb_image,2);
    end
    if(yi <1)
        yi = 1;
    end
    if(yi > size(rgb_image,1))
        yi = size(rgb_image,1)
    end
     
    if(but~=1)%(length(pts) <2)
        cur_bbox = [-1 -1 -1 -1];
    else
        cur_bbox = [xi yi 0 0];
        %cur_bbox = [pts(1) pts(2) 0 0];
    end
     
     
    ground_truth_bboxes{i} = cur_bbox;
     
    disp(i);
     
end

close all;
figure;
title('switch to bottom left!  (click to continue)');
ginput(1);


%label all the bottom right corners
for i=1:length(labeled_image_names)
    
    cur_name = labeled_image_names{i};
    
    rgb_image = imread(fullfile(scene_path, RGB_IMAGES_DIR, cur_name));
    
    
    
    cur_bbox = ground_truth_bboxes{i};
    
    
    
    
    
    
    
    
    
    if(center_label)  
        ls = label_structs{i};
        display_image = uint8(zeros(2*size(rgb_image,1),2*size(rgb_image,2),3));
        center_pos = [size(rgb_image,1), size(rgb_image,2)];

        label_pos = double([ls.y ls.x]);

        diff_pos = center_pos - label_pos ;

        start_row = 1+diff_pos(1);
        end_row = start_row+size(rgb_image,1)-1;
        start_col = 1+diff_pos(2);
        end_col = start_col+size(rgb_image,2)-1;


        display_image(start_row:end_row,start_col:end_col,:) = rgb_image;





        imshow(display_image);
    else
        imshow(rgb_image);
    end
    
    
    
    
    
    
    
    
    
    
    
    
    [xi, yi, but] = ginput(1);
    %pts = readPoints(rgb_image,1);
    
    
    if(center_label)
        xi = xi - diff_pos(2);
        yi = yi - diff_pos(1);
    end
    
    
    
    if(xi < 1)
        xi = 1;
    end
    if(xi > size(rgb_image,2))
        xi = size(rgb_image,2);
    end
    if(yi <1)
        yi = 1;
    end
    if(yi > size(rgb_image,1))
        yi = size(rgb_image,1)
    end
    
    
    
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

save(fullfile(write_path, 'ground_truth_bboxes_pretrim.mat'), 'ground_truth_bboxes', 'labeled_image_names');

indices_to_remove = [];
%% remove images without the object
for i=1:length(ground_truth_bboxes)
    
   bbox = ground_truth_bboxes{i};
   
   %remove images without the object
   if(bbox(1) == -1)
%       temp(i) = []; 
%       label_structs(i) = [];
%       labeled_image_names(i) = [];
        indices_to_remove(end+1) = i;
       
   end
    
end

% ground_truth_bboxes = temp;
ground_truth_bboxes(indices_to_remove) = []; 
label_structs(indices_to_remove) = [];
labeled_image_names(indices_to_remove) = [];


%find the index of this label
keys= map.keys;
values = map.values;

cur_index = 0;

for i=1:length(keys)
    if(strcmp(keys{i},label_name))
        cur_index = i;
        break;
    end
end

%replace the old label_structs
values{cur_index} = label_structs;

label_to_images_that_see_it_map = containers.Map(keys,values);

save(fullfile(scene_path, LABELING_DIR, ...
                            DATA_FOR_LABELING_DIR, ...
                              LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE), ...
                              LABEL_TO_IMAGES_THAT_SEE_IT_MAP); 






%save the bboxes
save(fullfile(write_path, 'ground_truth_bboxes.mat'), 'ground_truth_bboxes', 'labeled_image_names');


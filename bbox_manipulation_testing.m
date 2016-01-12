%draws the bboxes on the images



init;

scene_name = 'FB209_2';

label_name = 'advil_liqui_gels';


scene_path = fullfile(BASE_PATH,scene_name);
turk_path = fullfile(scene_path,LABELING_DIR,'turk_boxes');


label_to_images_that_see_it_map = load(fullfile(scene_path,LABELING_DIR,...
                                    DATA_FOR_LABELING_DIR, ...
                                    LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE));
 
label_to_images_that_see_it_map = label_to_images_that_see_it_map.(LABEL_TO_IMAGES_THAT_SEE_IT_MAP);
             
label_structs = label_to_images_that_see_it_map(label_name);

%load names of images we care about
annotations = load(fullfile(turk_path,strcat(label_name,'.mat')));

boxes_diff = cell(0);

annotations = annotations.annotations;
for i=2:1:length(annotations)-1
    
    ann = annotations{i};
    
    
    
    bbox = [ann.xtl, ann.ytl, ann.xbr, ann.ybr];
    image_name = ann.frame;
    
    if(image_name ==0)
        continue;
    end
    image_name = strcat(image_name(1:end-3),'jpg');
    
    if(image_name(8) ~= '1')
        continue;
    end
    
%     rgb_image = imread(fullfile(scene_path,JPG_RGB_IMAGES_DIR, image_name));
%     
%     imshow(rgb_image);
%     hold on;
%     
%     
%     rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
%     
    
    next_image_name = image_name;
    next_image_name(8) = '3';
    
    next_ann = annotations{i+1};
    next_frame = next_ann.frame;
    if(strcmp(next_image_name(1:10),next_frame(1:10)))
        next_bbox = [next_ann.xtl, next_ann.ytl, next_ann.xbr, next_ann.ybr];
        
        ls = label_structs{i};
        ls2 = label_structs{i+1};
        
        box_diff = next_bbox - bbox;
        boxes_diff{end+1} = [box_diff ls.depth ls2.depth];
    end
    
    
    %ginput(1);
%     ch = getkey();
%     if(ch == 'q')
%         break;
%     end
    hold off;
end





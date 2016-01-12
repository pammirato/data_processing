%draws the bboxes on the images



init;

scene_name = 'Room15';

label_name = 'spongebob_squarepants_fruit_snaks';


scene_path = fullfile(BASE_PATH,scene_name);
turk_path = fullfile(scene_path,LABELING_DIR,'turk_boxes');




%load names of images we care about
annotations = load(fullfile(turk_path,strcat(label_name,'.mat')));

annotations = annotations.annotations;
for i=2:5:length(annotations)
    
    ann = annotations{i};
    
    bbox = [ann.xtl, ann.ytl, ann.xbr, ann.ybr];
    frame = ann.frame;
    
    if(frame ==0)
        continue;
    end
    
%     image_name = strcat(sprintf('%010d',frame),'.png');
    image_name = frame;
 
    image_name = strcat(image_name(1:end-3),'jpg');
    
    rgb_image = imread(fullfile(scene_path,JPG_RGB_IMAGES_DIR, image_name));
    
    imshow(rgb_image);
    hold on;
    
    
    rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
    
    
    ginput(1);
%     ch = getkey();
%     if(ch == 'q')
%         break;
%     end
    hold off;
end





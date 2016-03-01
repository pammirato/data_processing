%draws the bboxes on the images



init;

density = 1;
scene_name = 'SN208';

label_name = 'table2';


scene_path = fullfile(BASE_PATH,scene_name);
if(density)
    scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
end
turk_path = fullfile(scene_path,LABELING_DIR,'turk_boxes');


save_changes = 0;

%load names of images we care about
ann_file = load(fullfile(turk_path,strcat(label_name,'.mat')));

annotations = ann_file.annotations;
for i=1:1:length(annotations)
    
    ann = annotations{i};
    
    bbox = [ann.xtl, ann.ytl, ann.xbr, ann.ybr];
    frame = ann.frame;
    
    if(frame(8) =='0')
        continue;
    end
    
%     image_name = strcat(sprintf('%010d',frame),'.png');
    image_name = frame;
 
    image_name = strcat(image_name(1:end-3),'jpg');
    
    rgb_image = imread(fullfile(scene_path,JPG_RGB_IMAGES_DIR, image_name));
    
    imshow(rgb_image);
    hold on;
    
    title(strcat(num2str(i),'/',num2str(length(annotations))));
    rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
    
    
    [x, y, but] = ginput(1);
    
    if(but~=1)
        save_changes = 1;
        [x, y, but] = ginput(2);
        
        if(but(1) ~=1)
            break;
        end
        
        x(1) = max(1,x(1));
        x(2) = min(size(rgb_image,2),x(2));
        y(1) = max(1,y(1));
        y(2) = min(size(rgb_image,1),y(2));
        
        
        ann.xtl = x(1);
        ann.ytl = y(1);
        ann.xbr = x(2);
        ann.ybr = y(2);
        
        
        annotations{i} = ann;
        
    end%if but
%     ch = getkey();
%     if(ch == 'q')
%         break;
%     end
    hold off;
end



if(save_changes)
    ann_file.annotations = annotations;
    
    save(fullfile(turk_path,strcat(label_name,'.mat')),'-struct','ann_file')
end




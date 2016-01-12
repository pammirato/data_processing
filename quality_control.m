%draws the bboxes on the images



init;

scene_name = 'FB209_2';

label_name = 'spongebob_squarepants_fruit_snaks';


scene_path = fullfile(BASE_PATH,scene_name);
turk_path = fullfile(scene_path,LABELING_DIR,'turk_boxes');




%load names of images we care about
annotations = load(fullfile(turk_path,strcat(label_name,'.mat')));

annotations = annotations.annotations;

cur_image_index = 2;
while(cur_image_index < length(annotations)+1)
    
    ann = annotations{cur_image_index};
    
    bbox = [ann.xtl, ann.ytl, ann.xbr, ann.ybr];
    image_name = ann.frame;
    
    if(image_name ==0)
        continue;
        cur_image_index = cur_image_index +1;
    end
    image_name = strcat(image_name(1:end-3),'jpg');
    
    rgb_image = imread(fullfile(scene_path,JPG_RGB_IMAGES_DIR, image_name));
    
    imshow(rgb_image);
    hold on;
    
    
    rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
     hold off;
    
    
    
    move_command = input(['Enter command(' num2str(cur_image_index) '/' ...
                          num2str(length(annotations)) '):' ], 's');

    if(strcmp(move_command, 'q'))
      disp('quiting...');
      break;

    elseif(strcmp(move_command,'n'))
      %move forward one image 
      cur_image_index = cur_image_index+1;   
    elseif(strcmp(move_command,'p'))
      %move backward one image 
      cur_image_index = cur_image_index-1;
      if(cur_image_index < 1)
        cur_image_index = 1;
      end
    end
    
    
    %pause(.3);
    %ginput(1);
%     ch = getkey();
%     if(ch == 'q')
%         break;
%     end
   
end




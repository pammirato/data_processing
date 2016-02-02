%draws the bboxes on the images



init;

scene_name = 'Room15';

label_name = 'chair';


scene_path = fullfile(BASE_PATH,scene_name);
turk_path = fullfile(scene_path,LABELING_DIR,'turk_boxes');






%load data about psition of each image in this scene
camera_structs_file =  load(fullfile(scene_path,RECONSTRUCTION_DIR,NEW_CAMERA_STRUCTS_FILE));
camera_structs = camera_structs_file.(CAMERA_STRUCTS);
scale  = camera_structs_file.scale;

%get a list of all the image file names in the entire scene
temp = cell2mat(camera_structs);
all_image_names = {temp.(IMAGE_NAME)};
clear temp;

%make a map from image name to camera_struct
camera_struct_map = containers.Map(all_image_names, camera_structs);
clear all_image_names;







if(strcmp(label_name,'all'))
    d = dir(fullfile(scene_path,LABELING_DIR,'turk_boxes','*.mat'));
    label_names = {d.name};
    num_labels = length(label_names);
else
    num_labels = 1;
end



for i=1:num_labels
    
    if(num_labels > 1)
        label_name = label_names{i};
        label_name = label_name(1:end-4);
        disp(label_name);
    end
        


    %load names of images we care about
    ann_file = load(fullfile(turk_path,strcat(label_name,'.mat')));

    annotations = ann_file.annotations;
    
    %     ch = getkey();
    %     if(ch == 'q')
    %         break;
    %     end
        hold off;
        
        
        
        
        
        
        
        
    cur_image_index = 1;
    move_command = 'n';

    while(cur_image_index < length(annotations)) 



        ann = annotations{cur_image_index};

        bbox = [ann.xtl, ann.ytl, ann.xbr, ann.ybr];
        frame = ann.frame;

        if(frame(8) =='0')
            cur_image_index = cur_image_index+1; 
            continue;
        end

    %     image_name = strcat(sprintf('%010d',frame),'.png');
        image_name = frame;

        image_name = strcat(image_name(1:end-3),'jpg');

        rgb_image = imread(fullfile(scene_path,JPG_RGB_IMAGES_DIR, image_name));

        imshow(rgb_image);
        hold on;

        title(strcat(label_name,num2str(cur_image_index),'/',num2str(length(annotations))));
        rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
        hold off;


        move_command = input(['Enter move command(' num2str(cur_image_index) '/' ...
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
        elseif(strcmp(move_command,'m'))
          %let the user decide how much to move(forward or back) 
          num_to_move = input('How many images to move: ', 's');
          num_to_move = str2num(num_to_move);

          cur_image_index = cur_image_index + num_to_move;
          if(cur_image_index < 1)
            cur_image_index = 1;
          end
        elseif(strcmp(move_command,'f'))
          %move forward 50 iamges
          num_to_move = 50;
          cur_image_index = cur_image_index + num_to_move;
        elseif(strcmp(move_command,'g'))
          %move forward 100 images
          num_to_move = 100;
        elseif(strcmp(move_command,'s'))
          %move forward 100 images

            camera_struct = camera_struct_map(strcat(image_name(1:end-3),'png'));

            save(fullfile(scene_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name,'view_0_struct.mat'),'-struct','camera_struct');

            disp('SAVED!!  0');
            break;
        elseif(strcmp(move_command,'x'))
          %move forward 100 images

            camera_struct = camera_struct_map(strcat(image_name(1:end-3),'png'));

            save(fullfile(scene_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name,'view_180_struct.mat'),'-struct','camera_struct');

            disp('SAVED!! 180');
            break;
            
        elseif(strcmp(move_command,'h'))
        disp('help: ');

        disp('1) click a point on an image ');
        disp('2) type: ');
        disp('	a label - this will be stored with the point, to be saved later ');
        disp('	q  - to quit and save labels so far ');
        disp('	n - go to the next image ');
        disp('	p - go to the previous image  ');
        disp('	m - move some number of images,  ');
        disp('		enter the number of images after typing m  and hitting enter once ');
        disp('	f - move foward 50 images ');
        disp('	g - move forward 100 images ');
        end    
    end %while cur_image_index < 
        
       

end% for i, each label




%this script plots detection scores for one instance in a scene againts 
%variation in viewpoint of the instance, and distance from the camera
%to the instance


clearvars , close all;
init;



%the scene and instance we are interested in
scene_name = 'SN208';
recognition_system_name = 'fast-rcnn';
font_size = 10;

%any of the fast-rcnn categories
category_name = 'chair'; %make this 'all' to see all categories

score_threshold = .1;

scene_path = fullfile(BASE_PATH,scene_name);


image_names = dir(fullfile(scene_path,JPG_RGB_IMAGES_DIR,'*0101.jpg'));
image_names = {image_names.name};






cur_image_index = 1;
move_command = 'n';

while(cur_image_index < length(image_names) ) 



    
    
    rgb_name = image_names{cur_image_index};
    rgb_image = imread(fullfile(scene_path,JPG_RGB_IMAGES_DIR,rgb_name));
    
    imshow(rgb_image);
    
    
    rec_name = strcat(rgb_name(1:10),'.mat');
    rec_mat = load(fullfile(scene_path,RECOGNITION_DIR,recognition_system_name,rec_name));
   
    
    all_detections = rec_mat.dets;
    categories = fields(all_detections);
    
    dets_to_show = [];
    for j=1:length(categories)
        cur_label = categories{j};
        
        cur_dets = (all_detections.(cur_label));
        
        cur_dets = cur_dets(cur_dets(:,5)>score_threshold,:);
        
        
        for k=1:size(cur_dets,1)
            bbox = double(cur_dets(k,:));
            rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');

            text(bbox(1), bbox(2)-font_size,strcat(num2str(bbox(5)),cur_label),  ...
                                    'FontSize',font_size, 'Color','white');

        end%for k      
%         if(length(dets_to_show) > 0)
%             dets_to_show = cat(1,dets_to_show,cur_dets);
%         else
%             dets_to_show = cur_dets;
%         end
    end%for j
    

    
    
    
    
    
    
    
    
    
    
    










    move_command = input(['Enter move command(' num2str(cur_image_index) '/' ...
                          num2str(length(image_names)) '):' ], 's');

    if(strcmp(move_command, 'q'))
      disp('quiting...');
      break;

    elseif(strcmp(move_command,'n'))
      %move forward one image 
      cur_image_index = cur_image_index+25;   
    elseif(strcmp(move_command,'p'))
      %move backward one image 
      cur_image_index = cur_image_index-25;
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

      cur_image_index = cur_image_index + num_to_move;
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

%this script plots detection scores for one instance in a scene againts 
%variation in viewpoint of the instance, and distance from the camera
%to the instance


clearvars , close all;
init;



%the scene and instance we are interested in
scene_name = 'Room15';
instance_name = 'bottle2';
font_size = 10;
%label_name = instance_name;
% eval(['depth_images = depth_images_' scene_name ';']);

%any of the fast-rcnn categories
category_name = 'bottle'; %usually the only difference is this has no index

%whether or not to show some bboxes at the end
vis_detections = 1;
vis_detections2 = 0;
vis_angles = 0;


scene_path = fullfile(BASE_PATH,scene_name);


%get the map to find all the interesting images
label_to_images_that_see_it_map = load(fullfile(scene_path,LABELING_DIR,...
                                    DATA_FOR_LABELING_DIR, ...
                                    LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE));
 
label_to_images_that_see_it_map = label_to_images_that_see_it_map.(LABEL_TO_IMAGES_THAT_SEE_IT_MAP);
             
             
             
%get the structs with IMAGE_NAME, X, Y, DEPTH for images that see this
%instance
label_structs = label_to_images_that_see_it_map(instance_name);

%get all the image names
temp = cell2mat(label_structs);
image_names = {temp.(IMAGE_NAME)};
clear temp;







figure;
% 
% %for each image
% for i=1:length(image_names)
%     
%     imshow(fullfile(scene_path,RGB_IMAGES_DIR,image_names{i}));
%     title(image_names{i});
%     
%     %load all the fast-rcnn detections for this image
%     cur_image_mat_name = image_names{i};
%     %replace .png with .mat
%     cur_image_mat_name = strcat(cur_image_mat_name(1:end-3), 'mat');
%     
%     cur_image_detections = load(fullfile(scene_path, RECOGNITION_DIR, ...
%                          FAST_RCNN_DIR, cur_image_mat_name));                   
%     cur_image_detections = cur_image_detections.(DETECTIONS_STRUCT);
%     
%     
%     
%     %get the detections just for our category
%     cur_image_detections = cur_image_detections.(category_name);
%     
% 
%     
% 
% 
%     
%     for j=1:size(cur_image_detections,1)
%         
%         
%         %check if labeled point is near bbox
%         bbox = double(cur_image_detections(j,1:4));
%         width =  bbox(3)-bbox(1);
%         height =  bbox(4) - bbox(2);
%         
%               
%         
%         if(cur_image_detections(j,5) > .1)
%             rectangle('Position', [bbox(1:2), width, height], 'EdgeColor', 'red' );
%             
%             rectangle('Position', [bbox(1), bbox(2)-font_size, width, font_size], 'EdgeColor', 'red','FaceColor', 'red');
%             text(bbox(1), bbox(2)-font_size, num2str(cur_image_detections(j,5)),  ...
%                                 'FontSize',font_size, 'Color','white');
%         end
% 
%         
%     end% for j in cur_detections
%     
%     [x y but]  =ginput(1);
%     
% end%for i in image_names





cur_image_index = 1;
move_command = 'n';


best_scores = zeros(1,length(image_names));
best_bboxes = cell(1,length(image_names));

all_images = cell(1,length(image_names));

save_dir = 'alex4';

mkdir(save_dir);

% 
% while(cur_image_index < length(image_names) ) 
for i=1:length(image_names)


  %%%%%%
  %%%%%%
  %%% VIEWING CODE
  
      imshow(fullfile(scene_path,RGB_IMAGES_DIR,image_names{i}));
    title(image_names{i});
    
    %load all the fast-rcnn detections for this image
    cur_image_mat_name = image_names{i};
    %replace .png with .mat
    cur_image_mat_name = strcat(cur_image_mat_name(1:end-3), 'mat');
    
    cur_image_detections = load(fullfile(scene_path, RECOGNITION_DIR, ...
                         FAST_RCNN_DIR, cur_image_mat_name));                   
    cur_image_detections = cur_image_detections.(DETECTIONS_STRUCT);
    
    
    
    %get the detections just for our category
    cur_image_detections = cur_image_detections.(category_name);
    
    

   max_score = 0;
   b_bbox = [0 0 0 0];


    
    for j=1:size(cur_image_detections,1)
        
        
        %check if labeled point is near bbox
        bbox = double(cur_image_detections(j,1:4));
        width =  bbox(3)-bbox(1);
        height =  bbox(4) - bbox(2);
        
              
        
        if(cur_image_detections(j,5) > .1)
            rectangle('Position', [bbox(1:2), width, height], 'EdgeColor', 'red' );
            
            rectangle('Position', [bbox(1), bbox(2)-2*font_size, width, ...
                2*font_size], 'EdgeColor', 'red','FaceColor', 'red');
            text(bbox(1), bbox(2)-font_size, num2str(cur_image_detections(j,5)),  ...
                                'FontSize',font_size, 'Color','white');
        end
        
        
        if(cur_image_detections(j,5) > max_score)
            max_score = cur_image_detections(j,5);
            b_bbox = bbox;
        end

        
    end% for j in cur_detections
  %%%%%%
  %%%%%%


  print('-djpeg95', fullfile(save_dir, [sprintf('%0.6f',max_score) image_names{i}(1:end-3) 'jpg']));

  best_scores(i) = max_score;
  best_bboxes{i} = [i b_bbox max_score];





% 
% 
%   move_command = input(['Enter move command(' num2str(cur_image_index) '/' ...
%                           num2str(length(image_names)) '):' ], 's');
% 
%   if(strcmp(move_command, 'q'))
%       disp('quiting...');
%       break;
% 
%   elseif(strcmp(move_command,'n'))
%       %move forward one image 
%       cur_image_index = cur_image_index+1;   
%   elseif(strcmp(move_command,'p'))
%       %move backward one image 
%       cur_image_index = cur_image_index-1;
%       if(cur_image_index < 1)
%         cur_image_index = 1;
%       end
%   elseif(strcmp(move_command,'m'))
%       %let the user decide how much to move(forward or back) 
%       num_to_move = input('How many images to move: ', 's');
%       num_to_move = str2num(num_to_move);
%       
%       cur_image_index = cur_image_index + num_to_move;
%       if(cur_image_index < 1)
%         cur_image_index = 1;
%       end
%   elseif(strcmp(move_command,'f'))
%       %move forward 50 iamges
%       num_to_move = 50;
%       cur_image_index = cur_image_index + num_to_move;
%   elseif(strcmp(move_command,'g'))
%       %move forward 100 images
%       num_to_move = 100;
%       
%       cur_image_index = cur_image_index + num_to_move;
%   elseif(strcmp(move_command,'h'))
%     disp('help: ');
% 
%     disp('1) click a point on an image ');
%     disp('2) type: ');
%     disp('	a label - this will be stored with the point, to be saved later ');
%     disp('	q  - to quit and save labels so far ');
%     disp('	n - go to the next image ');
%     disp('	p - go to the previous image  ');
%     disp('	m - move some number of images,  ');
%     disp('		enter the number of images after typing m  and hitting enter once ');
%     disp('	f - move foward 50 images ');
%     disp('	g - move forward 100 images ');
%   end    
end %while cur_image_index < 

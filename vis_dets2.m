%this script plots detection scores for one instance in a scene againts 
%variation in viewpoint of the instance, and distance from the camera
%to the instance


clearvars , close all;
init;



%the scene and instance we are interested in
scene_name = 'Room15';
font_size = 15;
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


rgb_dir = dir(fullfile(category_name));
rgb_dir = rgb_dir(3:end);

image_names = {rgb_dir.name};





figure;





cur_image_index = 1;
move_command = 'n';


best_scores = zeros(1,length(image_names));
best_bboxes = cell(1,length(image_names));

all_images = cell(1,length(image_names));

save_dir = 'alex4';


% 
% while(cur_image_index < length(image_names) ) 
for i=1:length(image_names)


  %%%%%%
  %%%%%%
  %%% VIEWING CODE
  
      imshow(fullfile(scene_path,RGB_IMAGES_DIR,image_names{i}));
    %title(image_names{i});
    
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
        
%           ginput(1);
        %check if labeled point is near bbox
        bbox = double(cur_image_detections(j,1:4));
        width =  bbox(3)-bbox(1);
        height =  bbox(4) - bbox(2);
        
              
        
        if(cur_image_detections(j,5) > .1)
            rectangle('Position', [bbox(1)+1, bbox(2)+1, width, height], 'EdgeColor', 'red', 'LineWidth',2 );
            
            rectangle('Position', [bbox(1), bbox(2), width, ...
                2*font_size], 'EdgeColor', 'red','FaceColor', 'red');
            text(bbox(1), bbox(2)+font_size, sprintf('%0.2f',cur_image_detections(j,5)),  ...
                                'FontSize',font_size, 'Color','white');
        end
        
        
        if(cur_image_detections(j,5) > max_score)
            max_score = cur_image_detections(j,5);
            b_bbox = bbox;
        end

        
    end% for j in cur_detections
  %%%%%%
  %%%%%%
  
  
  
  
  
  
  
    ti = get(gca,'TightInset')
    set(gca,'Position',[ti(1) ti(2) 1-ti(3)-ti(1) 1-ti(4)-ti(2)]);

  
    set(gca,'units','centimeters')
    pos = get(gca,'Position');
    ti = get(gca,'TightInset');

    set(gcf, 'PaperUnits','centimeters');
    set(gcf, 'PaperSize', [pos(3)+ti(1)+ti(3) pos(4)+ti(2)+ti(4)]);
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperPosition',[0 0 pos(3)+ti(1)+ti(3) pos(4)+ti(2)+ti(4)]);
  
  
  
  
  
  
  


  %ginput(1);
  print('-djpeg95', fullfile(category_name, [sprintf('%0.6f',max_score) image_names{i}(1:end-3) 'jpg']));
  
  
  img = imread( fullfile(category_name, [sprintf('%0.6f',max_score) image_names{i}(1:end-3) 'jpg']));


  img2 = img;
    sum_img = sum(img2,3);
    thresh_img = sum_img;
    thresh_img(thresh_img<765) =0;

    firstCol = find(thresh_img(1,:)==0,1);
    lastCol = find(thresh_img(1,:)==0,1,'last');

    firstRow = find(thresh_img(:,firstCol)==0,1);
    lastRow = find(thresh_img(:,firstCol)==0,1,'last');


    cropped_image = img(firstRow:lastRow, firstCol:lastCol,:);

    imwrite(cropped_image, fullfile(category_name, [sprintf('%0.6f',max_score) image_names{i}(1:end-3) 'jpg']));

  
  
  
  
  
  
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
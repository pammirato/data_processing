%this script plots detection scores for one instance in a scene againts 
%variation in viewpoint of the instance, and distance from the camera
%to the instance


clearvars -except 'depth_images_*', close all;
init;



%the scene and instance we are interested in
scene_name = 'Room15';
instance_name = 'bottle1';
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




% %load depth images
% depth_images = cell(1,length(image_names));
% rgb_images = cell(1,length(image_names));
% for i=1:length(depth_images)
%     cur_name = image_names{i};
%     suffix = cur_name(strfind(cur_name,'b') + 1 : end);
%     prefix = cur_name(1:end-3);
% 
%     depth_images{i} = imread(fullfile(scene_path, RAW_DEPTH_IMAGES_DIR,...
%                              strcat('raw_depth', suffix)));
%                          
%     rgb_images{i} = imread(fullfile(scene_path,RGB_JPG_IMAGES_DIR, ...
%                              strcat(prefix, 'jpg')));                 
% end%for i                             




% %load the ground_truth bboxes for this instance
% ground_truth_bboxes= load(fullfile(scene_path,LABELING_DIR, GROUND_TRUTH_BBOXES_DIR, label_name, '/ground_truth_bboxes.mat'));
% ground_truth_bboxes = ground_truth_bboxes.ground_truth_bboxes;





%load data about psition of each image in this scene
camera_structs_file =  load(fullfile(scene_path,RECONSTRUCTION_DIR,CAMERA_STRUCTS_FILE));
camera_structs = camera_structs_file.(CAMERA_STRUCTS);
camera_structscale  = camera_structs_file.scale;

%get a list of all the image file names in the entire scene
temp = cell2mat(camera_structs);
all_image_names = {temp.(IMAGE_NAME)};
clear temp;

%make a map from image name to camera_struct
camera_structs_map = containers.Map(all_image_names, camera_structs);
clear all_image_names;




% 
% %pick the zero view image
% for i=1:length(image_names)
%     
%    ls = label_structs{i};
%    if(ls.(DEPTH) > 0)
%        imshow(rgb_images{i});
%        hold on;
%        plot(ls.(X), ls.(Y), 'r.', 'MarkerSize' ,40);
%        hold off;
%        
%        
%        [x y but] = ginput(1);
%        
%        if(but ~=1)
%            view_zero_camera_struct = camera_structs_map(image_names{i});
%            view_zero_ls = ls;
%            break;
%        end
%    end
% end%for i  


% 
%pick the zero view image
for i=1:length(image_names)
    
%    img = imread(fullfile(scene_path,RGB_IMAGES_DIR,image_names{i}));
%    
%    if(i==1)
%        imshow(img)
%    end
%    
%    imwrite(img, fullfile('./pringles/', image_names{i}));
    
   %get info about the labeled point
   ls = label_structs{i};
   
   %skip any points with 0 depth
   if(ls.(DEPTH) == 0)
     continue;
   end
   
   %just pick the first one with depth
   view_zero_ls = ls;
   view_zero_camera_struct = camera_structs_map(ls.(IMAGE_NAME));
   break;
end%for i  



breakp=1;

%%%%%%%%%%%%%%%%%% GET WORLD  COORDS OF INSTANCE  %%%%%%%%%%%%%%%%


%get the data for the labeled image
%view_zero_camera_struct = camera_struct_map(image_names{1});

%intrinsic matrix of kinect1
%decide which intrinsic matrix to use
%     K = eye(3);
%     if(labeled_image_name(end-4) =='1')
%         K = intrinsic1;
%     elseif(labeled_image_name(end-4) =='2')
%         K = intrinsic2;
%     else
%         K = intrinsic3;
%     end
K = intrinsic1;

t = view_zero_camera_struct.(TRANSLATION_VECTOR);
R = view_zero_camera_struct.(ROTATION_MATRIX);
%C = view_zero_camera_struct.(SCALED_WORLD_POSITION);

t = t*scale;


%l1 = label_structs{1};
%pt = double([l1.(X); l1.(Y) ]);
pt = double([view_zero_ls.(X) view_zero_ls.(Y)])';
depth = double(view_zero_ls.(DEPTH));




instance_world_coords = R' * depth * pinv(K) *  [pt;1] - R'*t;




%%%%%%%%%%%%%%%%%% END GET WORLD  COORDS OF INSTANCE  %%%%%%%%%%%%%%%%















%use this for compaing angle
view_zero_world_position = view_zero_camera_struct.(SCALED_WORLD_POSITION);



%will hold all bboxes and score for the detections
best_detections = zeros(length(image_names),5);

%will hold distances from cameras tp instance for best detections
best_depths = zeros(1,length(image_names));

%will viewpoint angle change
best_viewpoint_angles = zeros(1,length(image_names));

%for each image, get its best detection for this instance
for i=1:length(image_names)
    
    %get the labeled point
    cur_label_struct = label_structs{i};
    labeled_point = double( [cur_label_struct.(X) cur_label_struct.(Y) ...
                                                cur_label_struct.(DEPTH)]);
    
    %load all the fast-rcnn detections for this image
    cur_image_mat_name = image_names{i};
    %replace .png with .mat
    cur_image_mat_name = strcat(cur_image_mat_name(1:end-3), 'mat');
    
    cur_image_detections = load(fullfile(scene_path, RECOGNITION_DIR, ...
                         FAST_RCNN_DIR, cur_image_mat_name));
                     
    cur_image_detections = cur_image_detections.(DETECTIONS_STRUCT);
    
    %get the detections just for our category
    cur_image_detections = cur_image_detections.(category_name);
    
    
    
    

    
    %now find the detection with the highest scrore that contains our
    %labeled point (or at least make sure the point is close)
    max_score = 0;
    max_bbox = zeros(1,4);
    max_depth = 0;
    
    %keep track of which bboxes are not thrown out
    %b/c of location or depth
    bboxes_considered = zeros(1,length(cur_image_detections));
    
    if(vis_detections2)
        
        %figure;
        imshow(fullfile(scene_path, RGB_IMAGES_DIR, image_names{i}));
        
        hold on;
        h = imagesc(depth_images{i});
        set(h,'AlphaData',.5);
        hold off;
    end
    
    for j=1:size(cur_image_detections,1)
        
        
        %check if labeled point is near bbox
        bbox = cur_image_detections(j,1:4);
        width =  bbox(3)-bbox(1);
        height =  bbox(4) - bbox(2);
        
        %http://gamedev.stackexchange.com/questions/44483/how-do-i-calculate-distance-between-a-point-and-an-axis-aligned-rectangle
        %find distance from point to closest point on bbox boundary
        cx = max(min(labeled_point(1), bbox(1)+width ), bbox(1));
        cy = max(min(labeled_point(2), bbox(2)+height), bbox(2));
        dist =  sqrt( (labeled_point(1)-cx)*(labeled_point(1)-cx) + ...
                    (labeled_point(2)-cy)*(labeled_point(2)-cy) );
                
        if(vis_detections2)       

            ls = label_structs{i};
            hold on;
            plot(ls.(X), ls.(Y),'r.','MarkerSize',40);
            hold off;
            rectangle('Position', [bbox(1) bbox(2) width height], 'EdgeColor', 'green' );
            title(num2str(dist));
            
            if(i==9)
                breakp = 1;
            end
        end

% %        http://gamedev.stackexchange.com/questions/44483/how-do-i-calculate-distance-between-a-point-and-an-axis-aligned-rectangle 
%         dx = max(abs(labeled_point(1) - bbox(1)) - width / 2, 0);
%         dy = max(abs(labeled_point(2) - bbox(2)) - height / 2, 0);
%         dist = sqrt( dx * dx + dy * dy);
%         
        %if the labeled point is too far away don't consider this detection     
        if(dist > 200)
            if(vis_detections2)
                rectangle('Position', [bbox(1) bbox(2), width, height], 'EdgeColor', 'black' );
            end            
            continue;
        end
        
        
        
        
        
        
        
        
        
        
        
        
        
        %check to see if the depth of the bbox is near the depth of the
        %label
        ls = label_structs{i};
        label_depth = ls.(DEPTH);
        
        %if the label depth is 0, then we can't tell so keep it
        if(label_depth > 0)
       
            depth_image =  depth_images{i};

            
            %generate random points inside the bbox, dependent on size of
            %bbox
            bb_area = width*height;
            num_rand = 1000;%floor(bb_area/10);
            
            rand_bbxs = randi(floor([bbox(1)+1 bbox(3)]),1,num_rand);
            rand_bbys = randi(floor([bbox(2)+1 bbox(4)]),1,num_rand);


            %bb_depths = zeros(1,num_rand);

            %if we found a dpeth that is close to label
            one_good_depth = 0;
            
            %will be used to check if at least one depth was > 0
            sum_depths = 0;

            
            
            bb_depths = depth_image(rand_bbys, rand_bbxs);
            bb_depths = diag(bb_depths);
            
            %make sure at least one depth is non zero
            if(sum(bb_depths) >0)
                 diffs= abs(double(bb_depths) - double(label_depth));
                 
                 %make sure one depth is close
                 if(min(diffs) > 200)
                     if(vis_detections2)
                        rectangle('Position', [bbox(1:2), width, height], 'EdgeColor', 'black' );
                     end
                     continue;
                 end    
            end %5if sum >0
            
%             
%             for k=1:num_rand
%                 bb_depth = depth_image(rand_bbys(k), rand_bbxs(k));
%                 sum_depths = sum_depths + bb_depth;
%                 
%                 %have to cast to double b/c they are uint16,
%                 if(abs(double(bb_depth) - double(label_depth)) < 200)
%                     one_good_depth = 1;
%                     break;
%                 end
%             end% for k

            %if no close depth was found, and at least 1 was >0
            if( ~ one_good_depth   && sum_depths >0)
                if(vis_detections2)
                    rectangle('Position', [bbox(1:2), width, height], 'EdgeColor', 'black' );
                end
                continue;
            end
        end
        
        
        
        
        
        
        
        
        
        
        
        
            if(i == 9)
                breakp = 1;
            end        
        
        
        bboxes_considered(j) = 1;
        
        if(vis_detections2)
            rectangle('Position', [bbox(1:2), width, height], 'EdgeColor', 'blue' );
        end
        
        %otherwise see if this is the best so far in this image
        score = cur_image_detections(j,5);
        if(score > max_score)
            max_score = score;
            max_bbox = bbox;
            max_depth = labeled_point(3);
        end
        
    end% for j in cur_detections
    
    %save the best for this image
    best_detections(i,:) = [max_bbox max_score];
    best_depths(i) = max_depth;
    
    
    cur_camera_struct = camera_structs_map(image_names{i});
    cur_world_pos = cur_camera_struct.(SCALED_WORLD_POSITION);
    
    
    %%compute viewpoint angle
    sidea = pdist2(view_zero_world_position', cur_world_pos');
    sideb = pdist2(view_zero_world_position', instance_world_coords');
    sidec = pdist2(cur_world_pos', instance_world_coords');
    
    [angleA, angleB, angleC] = get_triangle_angles_test_phil(sidea, sideb, sidec);
    
    best_viewpoint_angles(i) = angleA;
    
    
    if(vis_angles)
        
        
        plot3(view_zero_world_position(1),view_zero_world_position(2),view_zero_world_position(3),'b.');
        hold on;
        plot3(instance_world_coords(1),instance_world_coords(2),instance_world_coords(3),'r.');
        plot3(cur_world_pos(1),cur_world_pos(2),cur_world_pos(3),'g.');
        hold off;
        
        breakp =1;
    end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    


    if(vis_detections)

        bboxes_considered = find(bboxes_considered);
        bboxes_considered_counter = 1;

    %%%%%%%%%%%%%%%%%%%%%% VIS SOME DETECTIONS  %%%%%%%%%%%%%%%%%%%%
        
        %figure;
        imshow(fullfile(scene_path, RGB_IMAGES_DIR, image_names{i}));
        
%         hold on;
%         h = imagesc(depth_images{i});
%         set(h,'AlphaData',.5);
%         hold off;

%         for k=1:size(cur_image_detections,1)
%             bbox = cur_image_detections(k,1:4);
%             width = bbox(3) - bbox(1);
%             height = bbox(4) - bbox(2);
% 
% 
%             if(cur_image_detections(k,5) < 0)
%                 conitnue;
%             end
% 
%             if( bboxes_considered_counter <= length(bboxes_considered) && ...
%                     k == bboxes_considered(bboxes_considered_counter))
%                 rectangle('Position', [bbox(1) bbox(2) width height], 'EdgeColor', 'blue');
%                 bboxes_considered_counter = bboxes_considered_counter+1;
%             else
%                 rectangle('Position', [bbox(1) bbox(2) width height], 'EdgeColor', 'black' );
%             end
% 
% 
%         end


        best_bbox = best_detections(i,1:4);
        bwidth = best_bbox(3) - best_bbox(1);
        bheight = best_bbox(4) - best_bbox(2);
        rectangle('Position', [best_bbox(1) best_bbox(2) bwidth bheight], 'EdgeColor', 'red','LineWidth',3 );
        title(num2str(best_detections(i,5)));


%         ls = label_structs{i};
%         hold on;
%         plot(ls.(X), ls.(Y),'r.','MarkerSize',40);
%         hold off;


        breakp  =1;%kin = input('Next?(y/q): ', 's');
        

%         if( kin == 'q')
%                vis_detections = 0;
%                vis_detections2 = 0;
%         end
     end


    %%%%%%%%%%%%%%%%%%%%%% END  VIS SOME DETECTIONS  %%%%%%%%%%%%%%%%%%%%



    
    
    
    
    
    
    
    
    
    
    
    
    
    
end%for i in image_names














plot3(best_viewpoint_angles,best_depths,best_detections(:,5),'b.');
xlabel('viewpoint'), ylabel('depth'), zlabel('score');


figure;
plot(best_depths,best_detections(:,5),'b.');
xlabel('depth'), ylabel('score');
title(instance_name);


figure;
plot(best_viewpoint_angles,best_detections(:,5),'b.');
xlabel('viewpoint'), ylabel('score');
title(instance_name);






%figure;










% 
% 
% 
% if(vis_detections)
% 
% 
%     
%     
%     
%     
%             
%     cur_name = image_names{i};
%     %replace .png with .mat
%     cur_name = strcat(cur_name(1:end-3), 'mat');
%     
%     
%     cur_detections = load(fullfile(scene_path, RECOGNITION_DIR, ...
%                          FAST_RCNN_DIR, cur_name));
%                      
%     cur_detections = cur_detections.(DETECTIONS_STRUCT);
%     
%     %get the detections just for our category
%     cur_detections = cur_detections.(category_name);
%     
%     
%     
% 
% % %%%%%%%%%%%%%%%%%%%%%% VIS SOME DETECTIONS  %%%%%%%%%%%%%%%%%%%%
%     figure;
%     for i=1:length(image_names)
%         imshow(fullfile(scene_path, RGB_IMAGES_DIR, image_names{i}));
%         %hold on;
% 
%         bbbox = cur_detections(i,1:4);
%         bwidth = bbbox(3) - bbbox(1);
%         bheight = bbbox(4) - bbbox(2);
% 
%         %rectangle('Position', cur_detections(i,1:4) );
% 
%           % display the recognition score for the bounding box
%             title(num2str(cur_detections(i,5)));
%         
%         %hold off;
%         
%         
% 
% 
%     
%     imshow(fullfile(scene_path, RGB_IMAGES_DIR, image_names{i}));
%     %hold on;
% 
%     for qq=1:length(cur_detections)
%         bbox = cur_detections(qq,1:4);
%         width = bbox(3) - bbox(1);
%         height = bbox(4) - bbox(2);
%         
%         
%         if(cur_detections(qq,5) < 0)
%             conitnue;
%         end
% 
%         %rectangle('Position', cur_detections(i,1:4) );
%         rectangle('Position', [bbox(1:2), width, height] );
% 
%           % display the recognition score for the bounding box
%             %title(num2str(cur_detections(i,5)));
% 
% 
%     
%     
%     end
% 
%         
%                 rectangle('Position', [bbbox(1:2), bwidth, bheight], 'EdgeColor', 'red' );
% title(num2str(cur_detections(i,5)));
%         
%         
%          ls = label_structs{i};
%          hold on;
%          plot(ls.(X), ls.(Y),'r.','MarkerSize',40);
%          hold off;
%         
% 
%         kin = input('Next?(y/q): ', 's');
% 
%         if( kin == 'q')
%             break;
%         end
%     end
% 
% 
% 
%     %%%%%%%%%%%%%%%%%%%%%% END  VIS SOME DETECTIONS  %%%%%%%%%%%%%%%%%%%%
% 
% 
% end
% 
% 



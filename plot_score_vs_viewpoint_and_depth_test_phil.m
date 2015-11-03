%this script plots detection scores for one instance in a scene againts 
%variation in viewpoint of the instance, and distance from the camera
%to the instance


clear all, close all;
init;



%the scene and instance we are interested in
scene_name = 'Room15';
instance_name = 'bottle2';
%label_name = instance_name;
category_name = 'bottle'; %usually the only difference is this has no index

%whether or not to show some bboxes at the end
vis_detections = 1;

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




%load depth images
depth_images = cell(1,length(image_names));
for i=1:length(depth_images)
    suffix = image_names{i};
    suffix = suffix(strfind(suffix,'b') + 1 : end);

    depth_images{i} = imread(fullfile(scene_path, RAW_DEPTH_IMAGES_DIR,...
                             strcat('raw_depth', suffix)));
end%for i                             




% %load the ground_truth bboxes for this instance
% ground_truth_bboxes= load(fullfile(scene_path,LABELING_DIR, GROUND_TRUTH_BBOXES_DIR, label_name, '/ground_truth_bboxes.mat'));
% ground_truth_bboxes = ground_truth_bboxes.ground_truth_bboxes;





%load data about psition of each image in this scene
camera_structs_file =  load(fullfile(scene_path,RECONSTRUCTION_DIR,CAMERA_STRUCTS_FILE));
camera_structs = camera_structs_file.(CAMERA_STRUCTS);
scale  = camera_structs_file.scale;

%get a list of all the image file names in the entire scene
temp = cell2mat(camera_structs);
all_image_names = {temp.(IMAGE_NAME)};
clear temp;

%make a map from image name to camera_struct
camera_struct_map = containers.Map(all_image_names, camera_structs);
clear all_image_names;


%%%%%%%%%%%%%%%%%% GET WORLD  COORDS OF INSTANCE  %%%%%%%%%%%%%%%%


%get the data for the labeled image
view_zero_camera_struct = camera_struct_map(image_names{1});

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


l1 = label_structs{1};
pt = double([l1.(X); l1.(Y) ]);
depth = double(l1.(DEPTH));




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
    
    
    cur_image_name = image_names{i};
    %replace .png with .mat
    cur_image_name = strcat(cur_image_name(1:end-3), 'mat');
    
    
    cur_image_detections = load(fullfile(scene_path, RECOGNITION_DIR, ...
                         FAST_RCNN_DIR, cur_image_name));
                     
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
    if(vis_detections)
        bboxes_considered = zeros(1,length(cur_image_detections));
        %figure;
        imshow(fullfile(scene_path, RGB_IMAGES_DIR, image_names{i}));
        
        hold on;
        h = imagesc(depth_images{i});
        set(h,'AlphaData',.5);
        hold off;
    end
    
    for j=1:length(cur_image_detections)
        
        
        %check if labeled point is near bbox
        bbox = cur_image_detections(j,1:4);
        width =  bbox(3);
        height =  bbox(4);
        
        %http://gamedev.stackexchange.com/questions/44483/how-do-i-calculate-distance-between-a-point-and-an-axis-aligned-rectangle
        %find distance from point to closest point on bbox boundary
        cx = max(min(labeled_point(1), bbox(1)+width ), bbox(1));
        cy = max(min(labeled_point(2), bbox(2)+height), bbox(2));
        dist =  sqrt( (labeled_point(1)-cx)*(labeled_point(1)-cx) + ...
                    (labeled_point(2)-cy)*(labeled_point(2)-cy) );
                
        if(vis_detections)       

            ls = label_structs{i};
            hold on;
            plot(ls.(X), ls.(Y),'r.','MarkerSize',40);
            hold off;
            rectangle('Position', [bbox(1:2), width, height], 'EdgeColor', 'green' );
            title(num2str(dist));
            
            brealp = 1;
        end

% %        http://gamedev.stackexchange.com/questions/44483/how-do-i-calculate-distance-between-a-point-and-an-axis-aligned-rectangle 
%         dx = max(abs(labeled_point(1) - bbox(1)) - width / 2, 0);
%         dy = max(abs(labeled_point(2) - bbox(2)) - height / 2, 0);
%         dist = sqrt( dx * dx + dy * dy);
%         
        %if the labeled point is too far away don't consider this detection     
        if(dist > 20)
            if(vis_detections)
                rectangle('Position', [bbox(1:2), width, height], 'EdgeColor', 'black' );
            end            
            continue;
        end
        
        
        %check to see if the depth of the bbox is near the depth of the
        %label
        ls = label_structs{i};
        label_depth = ls.(DEPTH);
       
        depth_image =  depth_images{i};
        
        
        num_rand = 10;
        %generate 10 random points inside the bbox
        rand_bbxs = randi(floor([bbox(1) bbox(3)]),1,num_rand);
        rand_bbys = randi(floor([bbox(2) bbox(4)]),1,num_rand);
        
        %bb_depths = zeros(1,num_rand);
        
        one_good_depth = 0;
        
        for k=1:num_rand
            bb_depth = depth_image(rand_bbys(k), rand_bbxs(k));
            
            if(abs(bb_depth - label_depth) < 200)
                one_good_depth = 1;
                break;
            end
        end% for k
        

        if( ~ one_good_depth)
            if(vis_detections)
                rectangle('Position', [bbox(1:2), width, height], 'EdgeColor', 'black' );
            end
            continue;
        end
                
        
        bboxes_considered(j) = 1;
        
        if(vis_detections)
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
    
    
    cur_camera_struct = camera_struct_map(image_names{i});
    cur_world_pos = cur_camera_struct.(SCALED_WORLD_POSITION);
    
    
    %%compute viewpoint angle
    sidea = pdist2(view_zero_world_position', cur_world_pos');
    sideb = pdist2(view_zero_world_position', instance_world_coords');
    sidec = pdist2(cur_world_pos', instance_world_coords');
    
    [angleA, angleB, angleC] = get_triangle_angles_test_phil(sidea, sideb, sidec);
    
    best_viewpoint_angles(i) = angleA;
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    


    if(vis_detections)

        bboxes_considered = find(bboxes_considered);
        bboxes_considered_counter = 1;

    %%%%%%%%%%%%%%%%%%%%%% VIS SOME DETECTIONS  %%%%%%%%%%%%%%%%%%%%
        
        %figure;
        imshow(fullfile(scene_path, RGB_IMAGES_DIR, image_names{i}));
        
        hold on;
        h = imagesc(depth_images{i});
        set(h,'AlphaData',.5);
        hold off;

        for qq=1:length(cur_image_detections)
            bbox = cur_image_detections(qq,1:4);
            width = bbox(3) - bbox(1);
            height = bbox(4) - bbox(2);


            if(cur_image_detections(qq,5) < 0)
                conitnue;
            end

            if( bboxes_considered_counter < length(bboxes_considered) && ...
                    qq == bboxes_considered(bboxes_considered_counter))
                rectangle('Position', [bbox(1:2), width, height], 'EdgeColor', 'blue');
                bboxes_considered_counter = bboxes_considered_counter+1;
            else
                rectangle('Position', [bbox(1:2), width, height] );
            end


        end


        bestbbox = best_detections(i,1:4);
        bwidth = bestbbox(3) - bestbbox(1);
        bheight = bestbbox(4) - bestbbox(2);
        rectangle('Position', [bestbbox(1:2), bwidth, bheight], 'EdgeColor', 'red' );
        title(num2str(best_detections(i,5)));


        ls = label_structs{i};
        hold on;
        plot(ls.(X), ls.(Y),'r.','MarkerSize',40);
        hold off;


        kin = input('Next?(y/q): ', 's');
        

        if( kin == 'q')
               vis_detections = 0;
        end
     end



    %%%%%%%%%%%%%%%%%%%%%% END  VIS SOME DETECTIONS  %%%%%%%%%%%%%%%%%%%%



    
    
    
    
    
    
    
    
    
    
    
    
    
    
end%for i in image_names














plot3(best_viewpoint_angles,best_depths,best_detections(:,5),'b.');
xlabel('viewpoint'), ylabel('depth'), zlabel('score');











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
% %%%%%%%%%%%%%%%%%%%%%% VIS SOME DETECTIONS  %%%%%%%%%%%%%%%%%%%%
%     figure;
%     for i=1:length(image_names)
%         imshow(fullfile(scene_path, RGB_IMAGES_DIR, image_names{i}));
%         %hold on;
% 
%         bbbox = all_detections(i,1:4);
%         bwidth = bbbox(3) - bbbox(1);
%         bheight = bbbox(4) - bbbox(2);
% 
%         %rectangle('Position', all_detections(i,1:4) );
% 
%           % display the recognition score for the bounding box
%             title(num2str(all_detections(i,5)));
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
%         %rectangle('Position', all_detections(i,1:4) );
%         rectangle('Position', [bbox(1:2), width, height] );
% 
%           % display the recognition score for the bounding box
%             %title(num2str(all_detections(i,5)));
% 
% 
%     
%     
%     end
% 
%         
%                 rectangle('Position', [bbbox(1:2), bwidth, bheight], 'EdgeColor', 'red' );
% title(num2str(all_detections(i,5)));
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





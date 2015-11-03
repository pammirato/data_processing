%this script plots detection scores for one instance in a scene againts 
%variation in viewpoint of the instance, and distance from the camera
%to the instance


clear all, close all;
init;



%the scene and instance we are interested in
scene_name = 'Room15';
instance_name = 'monitor1';
label_name = instance_name;
category_name = 'monitor'; %usually the only difference is this has no index

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



%load the ground_truth bboxes for this instance
ground_truth_bboxes= load(fullfile(scene_path,LABELING_DIR, GROUND_TRUTH_BBOXES_DIR, label_name, '/ground_truth_bboxes.mat'));
ground_truth_bboxes = ground_truth_bboxes.ground_truth_bboxes;





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
all_detections = zeros(length(image_names),6);

%will hold distances from cameras tp instance for best detections
all_depths = zeros(1,length(image_names));

%will viewpoint angle change
all_viewpoint_angles = zeros(1,length(image_names));

%for each image, get its best detection for this instance
for i=1:length(image_names)
    
    %get the labeled point
    cur_label_struct = label_structs{i};
    labeled_point = double( [cur_label_struct.(X) cur_label_struct.(Y) ...
                                                cur_label_struct.(DEPTH)]);
    
    
    cur_name = image_names{i};
    %replace .png with .mat
    cur_name = strcat(cur_name(1:end-3), 'mat');
    
    
    cur_detections = load(fullfile(scene_path, RECOGNITION_DIR, ...
                         FAST_RCNN_DIR, cur_name));
                     
    cur_detections = cur_detections.(DETECTIONS_STRUCT);
    
    %get the detections just for our category
    cur_detections = cur_detections.(category_name);
    
    %now find the detection with the highest scrore that contains our
    %labeled point (or at least make sure the point is close)
    max_score = -1;
    max_bbox = zeros(1,4);
    max_depth = 0;

    score_threshold = .5;
    max_iou = -1;
   
    %ground_truth bbox 
    gt_bbox = ground_truth_bboxes{i};
    for j=1:length(cur_detections)
%         
%         
%         %check if labeled point is near bbox
%         bbox = cur_detections(j,1:4);
%         width =  bbox(3);
%         height =  bbox(4);
%         
%         %http://gamedev.stackexchange.com/questions/44483/how-do-i-calculate-distance-between-a-point-and-an-axis-aligned-rectangle
%         cx = max(min(labeled_point(1), bbox(1)+width ), bbox(1));
%         cy = max(min(labeled_point(2), bbox(2)+height), bbox(2));
%         dist =  sqrt( (labeled_point(1)-cx)*(labeled_point(1)-cx) + ...
%                     (labeled_point(2)-cy)*(labeled_point(2)-cy) );
%         
%                 
%         %if the labeled point is too far away don't consider this detection     
%         if(dist > 50)
%             continue;
%         end
%         
          cur_bbox = cur_detections(j,1:4); 
      
         
        
        
         x_p = cur_bbox(1);
         y_p = cur_bbox(2);
         x_g = gt_bbox(1);
         y_g = gt_bbox(2);

         width_p = cur_bbox(3) - cur_bbox(1); 
         height_p = cur_bbox(4) - cur_bbox(2); 
         width_g = gt_bbox(3) - gt_bbox(1); 
         height_g = gt_bbox(4) - gt_bbox(2); 
 
         intersectionArea=rectint([gt_bbox(1:2) width_g height_g], ...
                                    [cur_bbox(1:2) width_p height_p]);

         
         
         unionCoords=[min(x_g,x_p),min(y_g,y_p),max(x_g+width_g-1,x_p+width_p-1),max(y_g+height_g-1,y_p+height_p-1)];


         unionArea=(unionCoords(3)-unionCoords(1)+1)*(unionCoords(4)-unionCoords(2)+1);
 
         cur_iou=intersectionArea/unionArea; %This should be greater than 0.5 to consider it as a valid detection.
         
         
        
        %otherwise see if this is the best so far in this image
        score = cur_detections(j,5);
        if(cur_iou > max_iou )%&& score > score_threshold)
            max_score = score;
            max_bbox = cur_bbox;
            max_depth = labeled_point(3);
            max_iou = cur_iou;
        end
        
    end% for j in cur_detections
    
    %save the best for this image
    all_detections(i,:) = [max_bbox max_score max_iou];
    all_depths(i) = max_depth;
    
    
    cur_camera_struct = camera_struct_map(image_names{i});
    cur_world_pos = cur_camera_struct.(SCALED_WORLD_POSITION);
    
    
    %%compute viewpoint angle
    sidea = pdist2(view_zero_world_position', cur_world_pos');
    sideb = pdist2(view_zero_world_position', instance_world_coords');
    sidec = pdist2(cur_world_pos', instance_world_coords');
    
    [angleA, angleB, angleC] = get_triangle_angles_test_phil(sidea, sideb, sidec);
    
    all_viewpoint_angles(i) = angleA;
    
end%for i in image_names














plot3(all_viewpoint_angles,all_depths,all_detections(:,6),'b.');
xlabel('viewpoint'), ylabel('depth'), zlabel('score');









if(vis_detections)



%%%%%%%%%%%%%%%%%%%%%% VIS SOME DETECTIONS  %%%%%%%%%%%%%%%%%%%%
    figure;
    for i=1:length(image_names)
        imshow(fullfile(scene_path, RGB_IMAGES_DIR, image_names{i}));
        %hold on;

        bbox = all_detections(i,1:4);
        width = bbox(1) - bbox(3);
        height = bbox(2) - bbox(4);

       % rectangle('Position', all_detections(i,1:4) );
        rectangle('Position', [all_detections(i,1:2), width, height] );
        
                  % display the recognition score for the bounding box
            title(num2str(all_detections(i,5)));
        %hold off;

        kin = input('Next?(y/q): ', 's');

        if( kin == 'q')
            break;
        end
    end



    %%%%%%%%%%%%%%%%%%%%%% END  VIS SOME DETECTIONS  %%%%%%%%%%%%%%%%%%%%


end


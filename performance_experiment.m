%this script plots detection scores for one instance in a scene againts 
%variation in viewpoint of the instance, and distance from the camera
%to the instance


close all;
close all hidden;
init;


 
%the scene and instance we are interested in
scene_name = 'Room15';
instance_name = 'all';
label_name = instance_name;
category_name = 'chair'; %usually the only difference is this has no index
recognition_system = 'fast-rcnn';
score_threshold = .1;
save_rec_output_vis = 0;



%set some paths
scene_path = fullfile(BASE_PATH,scene_name);
image_path = fullfile(scene_path, RGB_IMAGES_DIR);
 results_path = fullfile(scene_path, RECOGNITION_DIR, FAST_RCNN_DIR);
 
 
 
 %load data about position of each image in this scene
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
 
 
 

%get the map to find all the interesting images
label_to_images_that_see_it_map = load(fullfile(scene_path,LABELING_DIR,...
                                    DATA_FOR_LABELING_DIR, ...
                                    LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE));
 
label_to_images_that_see_it_map = label_to_images_that_see_it_map.(LABEL_TO_IMAGES_THAT_SEE_IT_MAP);
             
             
%are we doing this for all labels or just one label?
if(strcmp(label_name,'all'))
    d = dir(fullfile(scene_path,LABELING_DIR,'turk_boxes','*.mat'));
    label_names = {d.name};
    num_labels = length(label_names);
else
    num_labels = 1;
end



%for each label
for i=1:num_labels
   
    %get the label/category name 
    if(num_labels > 1)
        label_name = label_names{i};
        label_name = label_name(1:end-4);
        disp(label_name);
        
        category_name = label_name(1:end-1);
    end
        




    %get the structs with IMAGE_NAME, X, Y, DEPTH for images that see this
    %instance
    label_structs = label_to_images_that_see_it_map(label_name);

    %get all the image names of the images that see this instance
    temp = cell2mat(label_structs);
    image_names = {temp.(IMAGE_NAME)};
    clear temp;




    %load the ground_truth bboxes for this instance
    turk_boxes= load(fullfile(scene_path,LABELING_DIR, 'turk_boxes', strcat(label_name, '.mat')));
    turk_annotations = cell2mat(turk_boxes.annotations);

    %get all the names of annotated images
    image_names = {turk_annotations.frame};

    %maybe get rid of the first image if it was a BIGBird image
    image_name = image_names{1};
    if(image_name(10)=='0')
            image_names = image_names(2:end);
    end






    %%%%%%%%%%%%%%%%%% GET WORLD  COORDS OF INSTANCE  %%%%%%%%%%%%%%%%


    %get the data for a point in a labeled image
    done = 0;
    counter = 1;

    %make sure the depth >0
    while(~done)
        ls = label_structs{counter};
        if(ls.depth > 0)
            done = 1;
        end
        counter = counter+1;
    end
    view_zero_camera_struct = camera_struct_map(image_names{counter});

    K = intrinsic1;

    t = view_zero_camera_struct.(TRANSLATION_VECTOR);
    R = view_zero_camera_struct.(ROTATION_MATRIX);
    %C = view_zero_camera_struct.(SCALED_WORLD_POSITION);
    t = t*(scale);


    l1 = label_structs{counter};
    pt = double([l1.(X); l1.(Y) ]);
    depth = double(l1.(DEPTH));



    %calculate the world cordinates of the instance
    instance_world_coords = R' * depth * pinv(K) *  [pt;1] - R'*t;




    %%%%%%%%%%%%%%%%%% END GET WORLD  COORDS OF INSTANCE  %%%%%%%%%%%%%%%%






    %figure for the positions of all the cameras used
    positions_fig = figure('Visible','off');

    title('position/score (plus direction and object position)');
    hold on;

    %plot3(instance_world_coords(1),instance_world_coords(2),instance_world_coords(3),'k.','MarkerSize',20);
    plot3(instance_world_coords(1),instance_world_coords(3),0 ,'k.','MarkerSize',50);







    %% setup for computing viewing angle
    if(exist(fullfile(scene_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name,'view_0_struct.mat') ,'file'))

       %get the labeled view_zero camera struct if it exists
        view_zero_struct = load(fullfile(scene_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name,'view_0_struct.mat'));
        zero_point = view_zero_struct.scaled_world_pos;
        plot3(zero_point(1),zero_point(3),0 ,'r.','MarkerSize',35);
        zero_point = zero_point([1,3]);

        zero_vec = zero_point - instance_world_coords([1,3]) ;

    elseif(exist(fullfile(scene_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name,'view_180_struct.mat') ,'file'))
        %get the labeled view_180 camera struct if it exists
        view_180_struct = load(fullfile(scene_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name,'view_180_struct.mat'));
        point_180 = view_180_struct.scaled_world_pos; 
        plot3(point_180(1),point_180(3),0 ,'g.','MarkerSize',35);
        point_180 = point_180([1,3]);

        zero_vec = instance_world_coords([1,3]) - point_180;
        
        zero_point = point_180;

    else
        %disp('no pose stuff');
        continue;
    end

    %more stuff for calculating angles later
    zero_vec = zero_vec/norm(zero_vec);
    zero_slope = zero_vec(2)/zero_vec(1);
    zero_b = zero_point(2) - zero_slope*zero_point(1);

    %%










    %store recognition scores, camera positons, camera angles, camera distances
    rec_scores = -ones(1,length(turk_annotations));
    cam_points = zeros(2,length(turk_annotations));
    view_angles = -ones(1,length(turk_annotations));
    %zero_vec = -1;
    distances = -ones(1,length(turk_annotations));



    
    if(save_rec_output_vis)

        %figure to save rec boxes and turk box on image
        save_fig = figure('Visible','off');
        mkdir(fullfile(scene_path,RECOGNITION_DIR,recognition_system,'performance_images',label_name));
    end
   


 
    flag = 1;
    %for each turk annotation
    for j=1:length(turk_annotations)
        
        ann = turk_annotations(j);
        
        %get the bbox dimensions and image name
        turk_box = double([ann.xtl, ann.ytl, ann.xbr, ann.ybr]);
        image_name = ann.frame;


        %skip a BIG BIRD image
        if(image_name(10)=='0')
            continue;
        end

        %skip K2 and K3 images
        if(image_name(8) ~= '1')
            continue;
        end




        %%  get struct info
        cur_struct = camera_struct_map(image_name);


        
        swp = cur_struct.scaled_world_pos;
        direction = cur_struct.direction;

        cam_points(1,j) = swp(1);
        cam_points(2,j) = swp(3);



    %     plot3(swp(1),swp(2),swp(3),'r.');
    %     quiver3(swp(1),swp(2),swp(3),dir(1)*scale,dir(2)*scale,dir(3)*scale, 'ShowArrowHead','off','Color' ,'b');
    %     




        %% get fast-rcnn output
        rec_mat = load(fullfile(scene_path,'recognition_results',recognition_system,...
                                'scores',strcat(image_name(1:10),'.mat')));
        rec_dets = rec_mat.dets;
       

        %make sure this category/label is in this recognition system 
        try
            rec_category_dets = rec_dets.(category_name);
        catch
            flag = 0;
            break;
        end

        %get rid of anything below score_threshold
        rec_category_dets = rec_category_dets(rec_category_dets(:,5) >=score_threshold,:);





        %% get 'best' box
        best_det = zeros(1,5);

        %for each bbox from rec output
        for k=1:size(rec_category_dets,1)
            cur_bbox = double(rec_category_dets(k,1:4)); 



             %find its Intersertion over Union with the turk labeld box
             x_p = cur_bbox(1);
             y_p = cur_bbox(2);
             x_g = turk_box(1);
             y_g = turk_box(2);

             width_p = cur_bbox(3) - cur_bbox(1); 
             height_p = cur_bbox(4) - cur_bbox(2); 
             width_g = turk_box(3) - turk_box(1); 
             height_g = turk_box(4) - turk_box(2); 

             intersectionArea=rectint([turk_box(1:2) width_g height_g], ...
                                        [cur_bbox(1:2) width_p height_p]);



             unionCoords=[min(x_g,x_p),min(y_g,y_p),max(x_g+width_g-1,x_p+width_p-1),max(y_g+height_g-1,y_p+height_p-1)];


             unionArea=(unionCoords(3)-unionCoords(1)+1)*(unionCoords(4)-unionCoords(2)+1);

             cur_iou=intersectionArea/unionArea; %This should be greater than 0.5 to consider it as a valid detection.


            %if IOU < .5 don't consider this box
            if(cur_iou < .5)
                continue;
            end

             %otherwise see if this is the best so far in this image
             score = rec_category_dets(k,5);

            if(score > best_det(5))
                best_det = rec_category_dets(k,:);
            end

        end% for j, each detection
       


        %idk  
        if(~flag)
            continue;
        end
        


        %save everything for this image
        rec_scores(j) = best_det(5);
        score = best_det(5)*2000;
        %% plot


        %%plot in the positions_fig
        plot3(swp(1),swp(3),score,'r.');
        quiver3(swp(1),swp(3),score,direction(1)*scale,direction(3)*scale,0, 'ShowArrowHead','off','Color' ,'b');



        %% calculate view angle/distance

        cur_point = swp([1,3]);

        if(sum(cur_point) == 0)
            continue;
        end

        point_vec = cur_point - instance_world_coords([1,3]);
        point_vec = point_vec/norm(point_vec);


        angle = acosd(dot(zero_vec,point_vec));

        

        %see if the angle is really greater than 180
        if(cur_point(1)*zero_slope + zero_b > cur_point(2))
            angle = 360 - angle;
        end

        %save the angle
        view_angles(j) = angle;

        %calulate and save the distance to the object
        distance = sqrt( sum(([instance_world_coords(1),instance_world_coords(3)] - [swp(1),swp(3)]).^2) );

        distances(j) = distance;





        %%

        %if we want the rec boxes vs. turk box overlayed on the image
        if(save_rec_output_vis)
            %set the current figure
            set(0,'CurrentFigure',save_fig); 


            %show the image
            imshow(imread(fullfile(scene_path,JPG_RGB_IMAGES_DIR,strcat(image_name(1:10),'.jpg'))));
            title(strcat(category_name,'  > ', num2str(score_threshold), '    (truth in red)'));

            %draw the turk bbox
            rectangle('Position',[turk_box(1) turk_box(2) (turk_box(3)-turk_box(1)) (turk_box(4)-turk_box(2))], 'LineWidth',3, 'EdgeColor','r');


            %draw all the rec bboxes
            font_size = 10;
            for k =1:size(rec_category_dets,1)
               bbox = double(rec_category_dets(k,1:5)); 
               rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b'); 
               text(bbox(1), bbox(2)-font_size,num2str(bbox(5)),  ...
                                            'FontSize',font_size, 'Color','white');
            end


            set(gca,'position',[0 0 1 1],'units','normalized');

            saveas(save_fig,fullfile(scene_path,RECOGNITION_DIR,recognition_system,'performance_images',label_name,strcat(image_name(1:8),'11.jpg')));


            %set the figure back to popsitions_fig
            set(0,'CurrentFigure',positions_fig); 
        end

    end%for i, each turk annotation








    %%for positions fig to look nice
    hold off;
    axis equal;

    % image_vis = figure;
    % 
    % turk_camera_structs = values(camera_struct_map,image_names);
    % 
    % dcm_obj = datacursormode(positions_fig); % get the data cursor object
    %   set(dcm_obj,'UpdateFcn',{@display_recognition_performance, turk_camera_structs, image_vis, category_name, label_name, scene_path});
    %                         
    %                         






    %make save directiories
    mkdir(fullfile(scene_path,RECOGNITION_DIR,recognition_system,'plots',label_name));


    saveas(positions_fig,fullfile(scene_path,RECOGNITION_DIR,recognition_system, ...
                'plots',label_name,'postions.jpg'));

    savefig(positions_fig,fullfile(scene_path,RECOGNITION_DIR,recognition_system, ...
                'plots',label_name,'postions_score_fig.fig'));

            
            
    %% get rid of points with no data
    a = find(view_angles ~= -1);

%     temp  = view_angles;
    view_angles = view_angles(a);
    cam_points = cam_points(:,a);
    distances = distances(a);
    rec_scores = rec_scores(a);

    %% plot to see what angles have been assigned to what points


    angle_assignment_fig = figure('Visible','off');
    skip = floor(length(cam_points)/15); %only do twentyish points
    plot(cam_points(1,1:skip:end),cam_points(2,1:skip:end),'r.');
    hold on;
    plot3(instance_world_coords(1),instance_world_coords(3),0 ,'k.','MarkerSize',50);
    plot3(zero_point(1),zero_point(2),0 ,'r.','MarkerSize',35);
    b = num2str(view_angles(1:skip:end)); c = strsplit(b);
    dx = 0.1; dy = 0.1; % displacement so the text does not overlay the data points
    text(cam_points(1,1:skip:end)+dx, cam_points(2,1:skip:end)+dy, c);
    hold off;
    saveas(angle_assignment_fig,fullfile(scene_path,RECOGNITION_DIR,recognition_system, ...
                'plots',label_name,'angle_assignment.jpg'));


    %view_angles = temp;


    %% plot stuff
    scatter_fig = figure('Visible','off');
    scatter(view_angles,distances,50,rec_scores, 'filled');
    h = colorbar;
    ylabel(h, 'score')
    xlabel('angle');
    ylabel('distance');
    saveas(scatter_fig,fullfile(scene_path,RECOGNITION_DIR,recognition_system, ...
                'plots',label_name,'angle_distance_score.jpg'));

    




    angle_dist_fig = figure('Visible','off');
    plot3(view_angles,distances,rec_scores, 'r.');
    title('angle/distance/score (iou > .5)');
    xlabel('angle');
    ylabel('distance');
    zlabel('score');
    savefig(angle_dist_fig,fullfile(scene_path,RECOGNITION_DIR,recognition_system, ...
                'plots',label_name,'angle_distance_score_fig.fig'));
            
            
     



    angle_fig = figure('Visible','off');
    plot(view_angles,rec_scores, 'r.');
    title('angle/score (iou > .5)');
    xlabel('angle');
    ylabel('score');
    saveas(angle_fig,fullfile(scene_path,RECOGNITION_DIR,recognition_system, ...
                'plots',label_name,'angle_score.jpg'));



    dist_fig = figure('Visible','off');
    plot(distances,rec_scores, 'r.');
    title('distance/score (iou > .5)');
    xlabel('distance');
    ylabel('score');
    saveas(dist_fig,fullfile(scene_path,RECOGNITION_DIR,recognition_system, ...
                'plots',label_name,'distance_score.jpg'));



    close all;
    close all hidden;
    


end % for i, each label







image_names = load([write_path 'names_of_images_that_see_instance.mat']);
image_names = image_names.image_names;

names_to_points = load([write_path 'map_image_name_to_labeled_points.mat']);%, 'names_to_points');
names_to_points = names_to_points.names_to_points;















%now find the bounding box with the highest score that contains at least
%one of the labeled points in each labeled image.

%holds highest score and bbox for each image
detections = cell(1,length( image_names));


%keep track of the overall best score for this instance(over all images)
max_score = 0;
max_index = 0;


%for each(unique) filename
for i=1:length(image_names)
    
    rgb_filename = image_names{i};
    
    %get all the points that are on the instance
    label_data = names_to_points(rgb_filename);


    %get name for detection scores
    file_prefix = rgb_filename(1:(strfind(rgb_filename,'.')-1));
%     
%     %get index for asscioated depth image
%    file_suffix = rgb_filename((strfind(rgb_filename,'b')+1):end);
%     depth_image = imread([base_path '/raw_depth/raw_depth' file_suffix]);
%    
% 
% 
% 
% 
%     
%     %update the label data to include the depth of the label
%     new_label_data = zeros(1,length(label_data)/2 *3);
%     for j=1:2:length(label_data)
%         label_x = label_data(1);
%         label_y = label_data(2);
% 
%         depth_of_label = depth_image(floor(label_y), floor(label_x));
%         
%         index = floor(j/2);
%         new_label_data((index*3)+1) = label_x;
%         new_label_data((index*3)+2) = label_y;
%         new_label_data((index*3)+3) = depth_of_label;
%     end
    

    
    
 
    %try to laod fast-rcnn score for this image (it might not exist!)
    try
        all_scores = load([detections_path class_name '/' file_prefix detections_suffix]);
    catch
        
        %if it doesn't exist, save the depth of he labels, and indicate no
        %detection
        
        disp(['could not load detection scores for ' file_prefix]);
        
        %update the label map to include the depth
        names_to_points(rgb_filename) = new_label_data;
        
        detections{i} = [-1 -1 -1 -1 -1];
        continue;
    end
    
    %get the scores from the struct
    all_scores = all_scores.dets;
    
    %sort according to score
    all_scores = sortrows(all_scores, -5);
    
    
    box_found = 0;
    counter = 1;
    
    %now get the box with the highest score that containts a labeled point
    
    %while we have not found a box that contains the labeled point
    while(~box_found && counter <= length(all_scores))
        bbox = all_scores(counter,1:4);
        
        %go every 2 b/c x,y
        for j=1:2:length(label_data)
            label_x = label_data(j);
            label_y = label_data(j+1);
            
            %if the point is in the box
            if(label_x >= bbox(1) && label_x <= bbox(3) && ...
               label_y >= bbox(2) && label_y <= bbox(4))
            
           %the first one found is the highest because we sorted
                detections{i} = all_scores(counter,:);
                
                %see if this is the overall max for all images
                if(all_scores(counter,5) > max_score)
                   max_score = all_scores(counter,5);
                   max_index = i;
                end
                box_found = 1;%stop looking at this image
                break;
       
            end %if label is in bounding box
        end
        counter = counter +1; %move to next bbox
    end%while we havent =found a box
    
    %make the point used to pick the bounding box the first in the array
    if(j ~=1)
        point_used = label_data(j:j+1);
        label_data(j:j+1) = label_data(1:2);
        label_data(1:2) = point_used;
    end
   
    %update the label map to include the depth
    names_to_points(rgb_filename) = new_label_data;
    
end%for i = labeled images




%save everything



%all the detection scores we found
top_detection_per_image_map = containers.Map(image_names, detections);

%save the new label_map that has depth (but dont overwrite the old one)
save([write_path 'names_to_points_depth.mat'], 'names_to_points');
save([write_path 'top_detection_per_image_map.mat'], 'top_detection_per_image_map');


%save data about the overall max score
max_score_image_name = image_names{max_index};
max_score_label_data = names_to_points(max_score_image_name);
max_score_detection_data = top_detection_per_image_map(max_score_image_name);
max_score_camera_data = camera_data_map(max_score_image_name);

save([write_path 'max_info.mat'], 'max_score_image_name', 'max_score_detection_data', 'max_score_label_data', 'max_score_camera_data');


    


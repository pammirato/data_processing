

room_name = 'KitchenLiving12';

class_name = 'monitor';
label_name = 'monitor1';


base_path =['/home/ammirato/Data/' room_name];

detections_data_path =[ base_path '/labeling/' label_name '/'];
write_path = [base_path '/labeling/' label_name '/'];

rgb_images_path = [base_path '/rgb/'];
mapping_label_path = [base_path '/labeling/mapping/labeled_mapping.txt'];

camera_data_path =[ base_path '/reconstruction_results/'];


detections_path = [base_path '/recognition_results/detections/matFiles/'];
detections_suffix = '.p.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
num_total_rgb_images = length(dir([base_path '/rgb_FIX/'])) -2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load camera positions and orientations for all images
cccc = load([base_path '/reconstruction_results/' 'camera_data.mat']);
camera_data_map = cccc.camera_data_map;

%load names of images we care about
labeled_image_names = load([detections_data_path 'labeled_image_names.mat']); 
labeled_image_names = labeled_image_names.labeled_image_names;

%load top bbox and score for each image
top_detection_per_image_map = load([detections_data_path 'top_detection_per_image_map.mat']);
top_detection_per_image_map = top_detection_per_image_map.top_detection_per_image_map;

%load label data for each image  (x,y,depth for each label)
%remeber the first point is the one used
labels_map = load([detections_data_path 'labels_map_depth']);
labels_map = labels_map.labels_map;

%get all the data about the highest score for this instance
max_info = load([detections_data_path 'max_info.mat']);
max_score_image_name = max_info.max_score_image_name;
max_score_label_data = max_info.max_score_label_data;
max_score_detection_data =max_info.max_score_detection_data;
max_score_camera_data = max_info.max_score_camera_data;

max_score_direction = max_score_camera_data(4:6) + max_score_camera_data(1:3);








angle_from_max = zeros(1,length(labeled_image_names));



pos = zeros(length(labeled_image_names),3);
dirs = zeros(length(labeled_image_names),3);
dirs2 = zeros(length(labeled_image_names),3);

depth_of_label = zeros(1,length(labeled_image_names));
detection_scores = zeros(1,length(labeled_image_names));

for i=1:length(labeled_image_names)

    cur_filename = labeled_image_names{i};
    
    cur_label_data = labels_map(cur_filename);
    depth_of_label(i) = cur_label_data(3);
  
    cur_detection = top_detection_per_image_map(cur_filename);
    detection_scores(i) = cur_detection(5);
    
    %if(depth_of_label(i) == 0)
     %   breakpoint = 1;
    %end
    
    cur_camera_data = camera_data_map(cur_filename);
    cur_direction = cur_camera_data(4:6) +cur_camera_data(1:3);
  
    pos(i,:) = cur_camera_data(1:3);
    dirs(i,:) = cur_camera_data(4:6);
    dirs2(i,:) = cur_direction(1:3);
    
    %distance between points
    a = sqrt(sum((max_score_camera_data(1:3) - cur_camera_data(1:3)) .^ 2));
    a = a*500;  %rough scale factor
    
    
    
    b = cur_label_data(3);
    c = max_score_label_data(3);
    
    AA = (b^2 + c^2 - a^2) / (2*a*b);
    
    [A B C] = get_triangle_angles(a,b,c);
    cur_angle = A;
    
    TOL=1e-10;
    if(b == 0)
        cur_angle = -1;
    elseif(abs(imag(A))>=TOL)
        cur_angle = -1;
    end
    %cur_angle = AA;
    

    %cur_angle = atan2(norm(cross(max_score_direction,cur_direction)), dot(max_score_direction,cur_direction));
    %cur_angle = acosd(norm(cross(max_score_direction(1:2),cur_direction(1:2))),dot(max_score_direction(1:2),cur_direction(1:2)));
    %CosTheta = dot(max_score_direction(1:2),cur_direction(1:2))/(norm(max_score_direction(1:2))*norm(cur_direction(1:2)));

    %cur_angle = acos(CosTheta)*180/pi;



    angle_from_max(i) = cur_angle;
end%for i 


%surf(depth_of_label,angle_from_max,detections(:,5));


plot3(depth_of_label,angle_from_max,detection_scores,'r.');


vals = camera_data_map.values;
vals = cell2mat(vals);

figure;


plot3(pos(:,1), pos(:,2), pos(:,3), 'r.');
hold on;
%plot3(dirs2(:,1), dirs2(:,2), dirs2(:,3), 'k.');
quiver3(pos(:,1), pos(:,2), pos(:,3),dirs2(:,1),dirs2(:,2),dirs2(:,3),'ShowArrowHead','off');
hold on;
scatter3(max_score_camera_data(1),max_score_camera_data(2),max_score_camera_data(3),45,'k','filled');



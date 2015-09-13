

angle_from_max = zeros(1,length(labeled_images));



pos = zeros(length(labeled_images),3);
dirs = zeros(length(labeled_images),3);
dirs2 = zeros(length(labeled_images),3);

for i=1:length(labeled_images)

  cur_label_data = labeled_images{i};
  cur_filename = cur_label_data{1};
  cur_camera_data = camera_data_map(cur_filename);
 % cur_direction = cur_camera_data(4:6);
  cur_direction = cur_camera_data(4:6) +cur_camera_data(1:3);
  
  pos(i,:) = cur_camera_data(1:3);
  dirs(i,:) = cur_camera_data(4:6);
  dirs2(i,:) = cur_direction(1:3);
  
  %cur_angle = atan2(norm(cross(max_score_direction,cur_direction)), dot(max_score_direction,cur_direction));
  %cur_angle = acosd(norm(cross(max_score_direction(1:2),cur_direction(1:2))),dot(max_score_direction(1:2),cur_direction(1:2)));
  CosTheta = dot(max_score_direction(1:2),cur_direction(1:2))/(norm(max_score_direction(1:2))*norm(cur_direction(1:2)));

  cur_angle = acos(CosTheta)*180/pi

  
  
  angle_from_max(i) = cur_angle;
end%for i 


%surf(depth_of_label,angle_from_max,detections(:,5));


plot3(depth_of_label,angle_from_max,detections(:,5),'r.');


vals = camera_data_map.values;
vals = cell2mat(vals);

figure;


plot3(pos(:,1), pos(:,2), pos(:,3), 'r.');
hold on;
plot3(dirs(:,1), dirs(:,2), dirs(:,3), 'k.');
hold on;
scatter3(max_camera_data(1),max_camera_data(2),max_camera_data(3),45,'b');



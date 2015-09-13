IMAGE_ID = 1;
QW = 2;
QX = 3;
QY = 4;
QZ = 5;
TX = 6;
TY = 7;
TZ = 8;
CAMERA_ID = 9;
NAME = 10;



room_name = 'KitchenLiving12';


base_path =['/home/ammirato/Data/' room_name];

mapping_label_path = [base_path '/labeling/mapping/labeled_mapping.txt'];

positions_path =[ base_path '/reconstruction_results/'];
%get the camera positions and orientations for the given images

fid_images = fopen([positions_path 'images.txt']); 


%skip header
fgetl(fid_images); 
fgetl(fid_images); 
line = fgetl(fid_images); 

camera_data = cell(1,num_total_rgb_images); 
names = cell(1,num_total_rgb_images); 

cur_image = zeros(1,CAMERA_ID); 

%for the orientation
abcur_vec = zeros(1,3);
vec1 = [0;0;1;1];
vec2 = [0;0;0;1];

i = 1;

while(ischar(line))

  %get image info
  line = fgetl(fid_images);
  line = strsplit(line);

  names{i} = line{end}; 
  cur_image = str2double(line(1:end-1)); 
  %camera_data{i} = cur_image; 

  if(length(cur_image) < QZ)
      break;
  end

  t = [cur_image(TX); cur_image(TY); cur_image(TZ)];
  quat = [cur_image(QW); cur_image(QX); cur_image(QY); cur_image(QZ)];
  R = quaternion_to_matrix(quat); % get rotation matrix from quaternion orientation
  %world camera positions = -(R)^T t (rotation matrix from quaternion(QX...) and t = TX, ...
  worldpos = -R' * t;

  proj = [-R' worldpos];

  cur_vec = (proj * vec1) - (proj*vec2);

  dX =-( worldpos(1) + cur_vec(1) );
  dY =-( worldpos(2) + cur_vec(2) );
  dZ =-( worldpos(3) + cur_vec(3) );


  camera_data{i} = [worldpos(1) worldpos(2) worldpos(3) dX dY dZ];

  %get Points2D 
  line =fgetl(fid_images); 

  i = i+1;
end


camera_data = camera_data(1:i-1);
names = names(1:i-1);


camera_data_map = containers.Map(names, camera_data);

save([base_path '/reconstruction_results/' 'camera_data.mat'], 'camera_data_map' );
    
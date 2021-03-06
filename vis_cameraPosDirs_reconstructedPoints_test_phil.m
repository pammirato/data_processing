%REQUIRES quaternion_to_matrix

%display all the reconstructed points, with rgb, and camera positions and directions for a scene





%%%%%%%%%%%%%%%%%%  plot reconstructed points

POINT_ID  = 1;
X = 2;
Y = 3;
Z = 4;
R = 5;
G = 6;
B = 7;
ERROR = 8;

room_name = 'FB341_2';

base_path = '/home/ammirato/Data/';

%where to read points from
points_path = [base_path room_name '/reconstruction_results/'];

fid_points = fopen([points_path 'points3D.txt']);

%get the first two comment lines
fgetl(fid_points);
fgetl(fid_points);

%get the first points' line
line = fgetl(fid_points);

%holds data for every point
points = cell(1,1);
%names = cell(1,1);

%holds data for one point
cur_point = zeros(1,B);

i = 1;

%while another line of data
while(ischar(line))

  %info is space separated
  line = strsplit(line);
  if(length(line) < B)
      break;
  end
  cur_point = str2double(line(1:B));
  points{i} = cur_point; 
  
  %get Points2D 
  line =fgetl(fid_points);


  i = i+1;
end


xs = zeros(length(points),1);
ys = zeros(length(points),1);
zs = zeros(length(points),1);
rgbs = zeros(length(points),3);

for i=1:length(points)

  cur_point = points{i};

  xs(i) = cur_point(X);
  ys(i) = cur_point(Y);
  zs(i) = cur_point(Z);
  rgbs(i,1) = cur_point(R);
  rgbs(i,2) = cur_point(G);
  rgbs(i,3) = cur_point(B);

end


figure;
scatter3(xs,ys,zs,10,rgbs/255.0,'filled');
axis equal;
axis([-30 30 -1 3 -30 30]);
















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

















hold on;







%%%%%%%%%%%%%%%%%%  plot camera positions and directions





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

%path = '/home/ammirato/Documents/results/shared-intrinsics-fisheye/';
reconstruction_path = ['/home/ammirato/Data/' room_name '/reconstruction_results/'];
image_path = ['/home/ammirato/Data/' room_name];




fid_images = fopen([reconstruction_path 'images.txt']); 

fgetl(fid_images); 
fgetl(fid_images); 
line = fgetl(fid_images); 

images = cell(1,1); 
names = cell(1,1); 

cur_image = zeros(1,CAMERA_ID); 

i = 1;

while(ischar(line))

  %get image info
  line = fgetl(fid_images);
  line = strsplit(line);

  names{i} = line{end}; 
  cur_image = str2double(line(1:end-1)); 
  images{i} = cur_image; 
  
  %get Points2D 
  line =fgetl(fid_images); 

  i = i+1;
end
 
%holds images
images = images(1:end-1);

%hold camera positions
X = zeros(1,length(images)); 
Y = zeros(1,length(images));
Z = zeros(1,length(images));

%holds points along camera directions
dX = zeros(1,length(images));
dY = zeros(1,length(images));
dZ = zeros(1,length(images));
vecs = cell(1,length(images));

cur_vec = zeros(1,3);
vec1 = [0;0;1;1];
vec2 = [0;0;0;1];

%draws camera direction line segment
dir_segs_x = -ones(1,length(images)*3);
dir_segs_y = -ones(1,length(images)*3);
dir_segs_z = -ones(1,length(images)*3);

scale = 2;


for i=1:length(images)
   %get image
  cur_image = images{i};
  
  %get translation and quaternion
  t = [cur_image(TX); cur_image(TY); cur_image(TZ)];
  quat = [cur_image(QW); cur_image(QX); cur_image(QY); cur_image(QZ)];
  R = quaternion_to_matrix(quat); % get rotation matrix from quaternion orientation
  
  %get camera position
  worldpos = -R' * t;

  X(i) = worldpos(1); 
  Y(i) = worldpos(2); 
  Z(i) = worldpos(3); 
  
  %make projection matrix
  proj = [-R' worldpos];

  %get camera direction vecotr
  cur_vec = (proj * vec1) - (proj*vec2);
  vecs{i} = cur_vec;

  %get a point along the camera direction
  dX(i) = worldpos(1) + cur_vec(1)/scale;
  dY(i) = worldpos(2) + cur_vec(2)/scale;
  dZ(i) = worldpos(3) + cur_vec(3)/scale;

  index = ((i-1)*3) +1;
  dir_segs_x(index) = X(i);
  dir_segs_x(index+1) = dX(i);
  dir_segs_x(index+2) = NaN;
  
  dir_segs_y(index) = Y(i);
  dir_segs_y(index+1) = dY(i);
  dir_segs_y(index+2) = NaN;

  dir_segs_z(index) = Z(i);
  dir_segs_z(index+1) = dZ(i);
  dir_segs_z(index+2) = NaN;
  
  
  

end%for i 

scatter3(X,Y,Z,'r.'); %plot camera positions in X and Z
hold on;
plot3(dir_segs_x, dir_segs_y, dir_segs_z,'b-');
%scatter3(dX,dY,dZ,'b.');%plot camera directions
axis equal;

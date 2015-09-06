
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


path = '/home/ammirato/Documents/results/shared-intrinsics-fisheye/';


fid_images = fopen([path 'images.txt']);

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


images = images(1:end-1);


X = zeros(1,length(images));
Y = zeros(1,length(images));
Z = zeros(1,length(images));

dX = zeros(1,length(images));
dY = zeros(1,length(images));
dZ = zeros(1,length(images));
vecs = cell(1,length(images));

cur_vec = zeros(1,3);
quat = zeros(1,4);
pos = zeros(3,1);
for i=1:length(images)

  cur_image = images{i};

  quat(1) = cur_image(QW);
  quat(2) = cur_image(QX);
  quat(3) = cur_image(QY);
  quat(4) = cur_image(QZ);

  pos(1)  = cur_image(TX);
  pos(2)  = cur_image(TY);
  pos(3)  = cur_image(TZ);

  pos2 = zeros(1,3);

  rot = quaternion_to_matrix(quat);

  pos2 = -rot' * pos; 


  proj = [-rot' pos]; 

  vec1 = [0;0;1;1];
  vec2 = [0;0;0;1];

  cur_vec = (proj * vec1) - (proj*vec2); 
  vecs{i} = cur_vec;


  X(i) = pos2(1); 
  Y(i) = pos2(2); 
  Z(i) = pos2(3); 

  dX(i) = pos2(1) + cur_vec(1); 
  dY(i) = pos2(2) + cur_vec(2); 
  dZ(i) = pos2(3) + cur_vec(3); 

end%for i 



plot3(X,Y,Z,'r.');
axis equal;

hold on;
plot3(dX,dY,dZ,'.b');

axis equal;





%wolrd camera positions = -(R)^T t (rotation matrix from quaternion(QX...) and t = TX, ...






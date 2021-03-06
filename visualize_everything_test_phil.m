
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

room_name = 'Room15';

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
plot3(dir_segs_x, dir_segs_y, dir_segs_z,'k-');
%scatter3(dX,dY,dZ,'b.');%plot camera directions
axis equal;





plotfig = figure;
scatter(X,Z,'r.'); %plot camera positions in X and Z

% allow user to click on camera positions to see the picture
imfig = figure;
figure(plotfig);
while 1
  if gcf == plotfig
    [xi, zi, but] = ginput(1)      % get a point

    pt = [xi zi];
    xz_worldpos = [X' Z'];
    [distance, index] = pdist2(xz_worldpos,pt,'euclidean','Smallest',1); % find position closest to click
    
    figure(imfig);
    imshow(strcat(image_path, names{index})); % show image camera took at that position
    figure(plotfig);
    names{index}
  end
end










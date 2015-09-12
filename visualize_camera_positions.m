
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
reconstruction_path = '/home/ammirato/Data/Bathroom1/reconstruction_results/0/';
image_path = '/home/ammirato/Data/Bathroom1/rgb/';

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
 

images = images(1:end-1);
X = zeros(1,length(images)); 
Y = zeros(1,length(images));
Z = zeros(1,length(images));

for i=1:length(images)

  cur_image = images{i};
  t = [cur_image(TX); cur_image(TY); cur_image(TZ)];
  quat = [cur_image(QW); cur_image(QX); cur_image(QY); cur_image(QZ)];
  R = quaternion_to_matrix(quat); % get rotation matrix from quaternion orientation
  %world camera positions = -(R)^T t (rotation matrix from quaternion(QX...) and t = TX, ...
  worldpos = -R' * t;

  X(i) = worldpos(1); 
  Y(i) = worldpos(2); 
  Z(i) = worldpos(3); 

end%for i 

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










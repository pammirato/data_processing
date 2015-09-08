




results_path = '/home/ammirato/Documents/Kinect/Data/Bathroom1/reconstruction_results/';




point3D_id = -1;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





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



fid_images = fopen([path 'images.txt']);

fgetl(fid_images);
fgetl(fid_images);
line = fgetl(fid_images);

images = cell(1,1);
names = cell(1,1);

cur_image = zeros(1,CAMERA_ID);

points2d = cell(1,1);
all_points_2d = cell(1,1);



while(ischar(line))

  %get image info
  line = fgetl(fid_images);
  line = strsplit(line);

  names{i} = line{end};
  cur_image = str2double(line(1:end-1));%avoid image name
  images{i} = cur_image;

  %get Points2D 
  line =fgetl(fid_images);
  line = strsplit(line);

  for k=1:3:length(line)
    points2d 



end

















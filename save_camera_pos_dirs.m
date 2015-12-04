%gets all the camera positions and orientations from the reconstruction output
%saves them in a map data structure, in a mat file. The structure maps from image name to a
%       a vector [X,Y,Z,dX,dY,dZ]  the camera position, and a point along the vector of its
%							orientation
%

%initialize contants, paths and file names, etc.
init;



%some constants that correspond to an index in each line the data is
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



scene_name = 'FB209';  %make this = 'all' to run all scenes

%get the names of all the scenes
d = dir(BASE_PATH);
d = d(3:end);

%determine if just one or all scenes are being processed
if(strcmp(scene_name,'all'))
    num_scenes = length(d);
else
    num_scenes = 1;
end

for i=1:num_scenes

    %if we are processing all scenes
    if(num_scenes >1)
        scene_name = d(i).name();
    end

    scene_path =fullfile(BASE_PATH, scene_name);


    positions_path =fullfile( scene_path, RECONSTRUCTION_DIR);
    %get the camera positions and orientations for the given images

    fid_images = fopen(fullfile(positions_path, IMAGES_RECONSTRUCTION));

    if(fid_images == -1)
        continue;
    end


    num_total_rgb_images = length(dir(fullfile(scene_path,RGB_IMAGES_DIR))) - 2;

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

%       dX =-( worldpos(1) + cur_vec(1) );
%       dY =-( worldpos(2) + cur_vec(2) );
%       dZ =-( worldpos(3) + cur_vec(3) );
      dX = -cur_vec(1);
      dY = -cur_vec(2);
      dZ = -cur_vec(3);


      camera_data{i} = [worldpos(1) worldpos(2) worldpos(3) dX dY dZ];

      %get Points2D
      line =fgetl(fid_images);

      i = i+1;
    end


    camera_data = camera_data(1:i-1);
    names = names(1:i-1);


    name_to_pos_dirs_map = containers.Map(names, camera_data);

    save(fullfile(scene_path, RECONSTRUCTION_DIR, NAME_TO_POS_DIRS_MAT_FILE), NAME_TO_POS_DIRS_MAP);

end

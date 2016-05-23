%saves a camera poistions and orientations from text file outputted from reconstruction
%saves a cell array of these 'image structs', and also saves the scale 
%also saves a list of reconstructed 3d points seen by each image


%TODO - better name, processing for points2d

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'SN208'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 




%% SET UP GLOBAL DATA STRUCTURES


%get the names of all the scenes
d = dir(ROHIT_BASE_PATH);
d = d(3:end);
all_scenes = {d.name};


%determine which scenes are to be processed 
if(use_custom_scenes && ~isempty(custom_scenes_list))
  %if we are using the custom list of scenes
  all_scenes = custom_scenes_list;
elseif(~strcmp(scene_name, 'all'))
  %if not using custom, or all scenes, use the one specified
  all_scenes = {scene_name};
end



%some constants that correspond to an index in each line the data is
IMG_ID = 1;
QW = 2;
QX = 3;
QY = 4;
QZ = 5;
TX = 6;
TY = 7;
TZ = 8;
CAM_ID = 9;
NAME = 10;





for i=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{i}
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


    
  %get the camera positions and orientations for the given images
  fid_images = fopen(fullfile(meta_path,RECONSTRUCTION_DIR,IMAGES_RECONSTRUCTION)); 

  %if the file didn't open
  if(fid_images == -1)
    disp(strcat('could not load ', IMAGES_RECONSTRUCTION, 'for ', scene_name));
    continue;
  end
  
  %get the number of images for this scene
  num_total_rgb_images = length(dir(fullfile(scene_path,RGB))) - 2;

  %skip header
  fgetl(fid_images); 
  fgetl(fid_images); 
  fgetl(fid_images); 
  fgetl(fid_images); 

  %holds all the structs, one per image, for this scene
  image_structs = cell(1,num_total_rgb_images); 
  point_2d_structs = cell(1,num_total_rgb_images);


  %for the orientation
  cur_vec = zeros(1,3);
  vec1 = [0;0;1;1];
  vec2 = [0;0;0;1];

  %count of number of structs made so far
  counter = 1;

  %% MAIN LOOP save the data
  line = fgetl(fid_images);
  while(ischar(line))

    %get image info
    line = strsplit(line);
    cur_image = str2double(line(1:end-1)); 

    %stop when line is empty
    if(length(cur_image) < QZ)
      break;
    end

    %translation vector?
    t = [cur_image(TX); cur_image(TY); cur_image(TZ)];
    
    %get quaternion and rotation matrix
    quat = [cur_image(QW); cur_image(QX); cur_image(QY); cur_image(QZ)];
    R = quaternion_to_matrix(quat); % get rotation matrix from quaternion orientation

    %get the 3D world position of the camera for this image
    worldpos = (-R' * t);
    
    %calculate the camera direction
    proj = [-R' worldpos];
    cur_vec = (proj * vec1) - (proj*vec2);

    %get the name of the image 
    name = line{end};
       
    %put all the info in a struct, with a place holder for scaled
    %position
    cur_struct = struct(IMAGE_NAME, name, TRANSLATION_VECTOR, t, ...
                       ROTATION_MATRIX, R, WORLD_POSITION, (-R' * t), ...
                       DIRECTION, -cur_vec, QUATERNION, quat, ...
                       SCALED_WORLD_POSITION, [0,0,0], IMAGE_ID,line{IMG_ID},...
                       CAMERA_ID, line{CAM_ID}, 'cluster_id', -1, 'rotate_cw', -1, ...
                       'rotate_ccw',-1, 'translate_forward',-1,'translate_backward',-1);

    image_structs{counter} = cur_struct;
    
    counter = counter+1;
    
    %get Points2D 
    line =fgetl(fid_images); 
     
    p2d_struct = struct(IMAGE_NAME, name, ...
        POINTS_2D, str2double(strsplit(line)));
    
    point_2d_structs{counter} = p2d_struct;
 
    
    %get the next line                
    line = fgetl(fid_images);

  end

  %get rid of empty cells if not all images were reconstructed
  %(because we pre-allocated the cell arrays)
  image_structs = image_structs(~cellfun('isempty',image_structs));
  point_2d_structs = point_2d_structs(~cellfun('isempty',point_2d_structs));
  
  %figure this out with another scirpt, just a place holder for now 
  scale = 0;

  %save everything
  save(fullfile(scene_path,IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE);
  save(fullfile(meta_path, RECONSTRUCTION_DIR, POINT_2D_STRUCTS_FILE), POINT_2D_STRUCTS);
    
end%for i, each scene

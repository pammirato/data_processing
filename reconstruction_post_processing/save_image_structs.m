%saves a camera poistions and orientations from text file outputted from COLMAP 
%saves an array of these 'image structs' (position, orientation, etc. for each image)
%also saves a placeholder for the scale, which scales positions to mm units
%also saves a list of reconstructed 3d points seen by each image

%TODO - better name, processing for points2d

%CLEANED - yes 
%TESTED - yes 

%initialize contants, paths and file names, etc. 
init;


%% USER OPTIONS

scene_name = 'Kitchen_Living_12_1'; %make this = 'all' to run all scenes
model_number = '0';
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



%for each scene, save the image structs for that scene
for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il}
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

   
  %open the file outputted from COLMAP
  %get the camera positions and orientations for the given images
  fid_images = fopen(fullfile(meta_path,RECONSTRUCTION_RESULTS,'colmap_results', ...
      model_number, IMAGES_RECONSTRUCTION)); 

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
  blank_struct = struct(IMAGE_NAME, '', TRANSLATION_VECTOR, [], ...
                       ROTATION_MATRIX, [], WORLD_POSITION, [], ...
                       DIRECTION, [], QUATERNION, [], ...
                       SCALED_WORLD_POSITION, [0,0,0], IMAGE_ID,'',...
                       CAMERA_ID, '', 'cluster_id', -1, 'rotate_cw', -1, ...
                       'rotate_ccw',-1, 'translate_forward',-1,'translate_backward',-1);

  %holds the structs with list of reconstructed 3D points seen by each image
  blank_p2d_struct = struct(IMAGE_NAME, '', POINTS_2D, []);
  image_structs = repmat(blank_struct,1,num_total_rgb_images); 
  point_2d_structs = repmat(blank_p2d_struct,1,num_total_rgb_images);


  %used to calculate the orientation later
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
      disp('too small')
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

    %skip hand scan images
    image_index = str2double(name(1:6));
    rgb_image_names = dir(fullfile(scene_path, 'rgb', '*.png'));
    if(image_index > length(rgb_image_names))
      disp(name);
      line =fgetl(fid_images); 
      line =fgetl(fid_images); 
      continue;
    end
       
    %put all the info in a struct, with a place holder for scaled
    %position
    cur_struct = struct(IMAGE_NAME, name, TRANSLATION_VECTOR, t, ...
                       ROTATION_MATRIX, R, WORLD_POSITION, (-R' * t), ...
                       DIRECTION, -cur_vec, QUATERNION, quat, ...
                       SCALED_WORLD_POSITION, [0,0,0], IMAGE_ID,line{IMG_ID},...
                       CAMERA_ID, line{CAM_ID}, 'cluster_id', -1, 'rotate_cw', -1, ...
                       'rotate_ccw',-1, 'translate_forward',-1,'translate_backward',-1);

    %image_structs{counter} = cur_struct;
    image_structs(counter) = cur_struct;
    
    %get Points2D 
    line =fgetl(fid_images); 
    p2d_struct = struct(IMAGE_NAME, name, ...
        POINTS_2D, str2double(strsplit(line)));
    point_2d_structs(counter) = p2d_struct;
 
    counter = counter+1;
    
    %get the next line                
    line = fgetl(fid_images);

    %just to show progress
    if(mod(counter,100)==0)
      disp(counter)
    end

  end%while there is another line to process

  %get rid of empty cells if not all images were reconstructed
  %(because we pre-allocated the cell arrays)
  image_structs(counter:end) = [];
  point_2d_structs(counter:end) = [];

  %sort the image structs by image name
  image_structs = nestedSortStruct2(image_structs, 'image_name'); 

  %figure this out with another scirpt, just a place holder for now 
  scale = 0;

  disp('saving...');

  %save everything
  save(fullfile(meta_path,RECONSTRUCTION_RESULTS,'colmap_results',...
                 model_number, 'image_structs.mat'),IMAGE_STRUCTS, SCALE);
                  
  save(fullfile(meta_path, RECONSTRUCTION_RESULTS,'colmap_results',...
                  model_number, POINT_2D_STRUCTS_FILE), POINT_2D_STRUCTS);
   
end%for il, each scene



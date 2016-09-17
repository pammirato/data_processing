%saves a camera poistions and orientations from text file outputted from reconstruction
%saves a cell array of these 'image structs', and also saves the scale 
%also saves a list of reconstructed 3d points seen by each image


%TODO - better name, processing for points2d

clearvars;

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'uwash_s7'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'Den_den2', 'Den_den3','Den_den4'};%populate this 




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
QW = 1;
QX = 2;
QY = 3;
QZ = 4;
X = 5;
Y = 6;
Z = 7;





for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il}
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


    
  %get the camera positions and orientations for the given images
  fid_images = fopen(fullfile(meta_path,RECONSTRUCTION_DIR,'07.pose'));

  %if the file didn't open
  if(fid_images == -1)
    disp(strcat('could not load ', IMAGES_RECONSTRUCTION, 'for ', scene_name));
    continue;
  end
  
  %get the number of images for this scene
  %num_total_rgb_images = length(dir(fullfile(scene_path,RGB))) - 2;
  num_total_rgb_images = 1000;%length(dir(fullfile(scene_path,RGB))) - 2;


  %holds all the structs, one per image, for this scene
  blank_struct = struct(IMAGE_NAME, '', TRANSLATION_VECTOR, [], ...
                       ROTATION_MATRIX, [], WORLD_POSITION, [], ...
                       DIRECTION, [], QUATERNION, [], ...
                       SCALED_WORLD_POSITION, [0,0,0], IMAGE_ID,'',...
                       CAMERA_ID, '', 'cluster_id', -1, 'rotate_cw', -1, ...
                       'rotate_ccw',-1, 'translate_forward',-1,'translate_backward',-1);

  %image_structs = cell(1,num_total_rgb_images); 
  image_structs = repmat(blank_struct,1,num_total_rgb_images); 
  %point_2d_structs = cell(1,num_total_rgb_images);


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
    line = str2double(line(1:end)); 

    %stop when line is empty
    if(length(line) < QZ)
      disp('too small')
      break;
    end

    
    %get quaternion and rotation matrix
    quat = [line(QW); line(QX); line(QY); line(QZ)];
    quat = quat(end:-1:1);
    R = quaternion_to_matrix(quat); % get rotation matrix from quaternion orientation
    %get the 3D world position of the camera for this image
    world_pos = [line(X) line(Y) line(Z)]';
   
    t = -R'*world_pos; 
    %calculate the camera direction
    proj = [-R' world_pos];
    cur_vec = (proj * vec1) - (proj*vec2);

    %get the name of the image 
    name = num2str(counter);

    %put all the info in a struct, with a place holder for scaled
    %position
    cur_struct = struct(IMAGE_NAME, name, TRANSLATION_VECTOR, t, ...
                       ROTATION_MATRIX, R, WORLD_POSITION, world_pos, ...
                       DIRECTION, -cur_vec, QUATERNION, quat, ...
                       SCALED_WORLD_POSITION, [0,0,0], IMAGE_ID,-1,...
                       CAMERA_ID, -1, 'cluster_id', -1, 'rotate_cw', -1, ...
                       'rotate_ccw',-1, 'translate_forward',-1,'translate_backward',-1);

    %image_structs{counter} = cur_struct;
    image_structs(counter) = cur_struct;
    
    counter = counter+1;
    
    %get the next line                
    line = fgetl(fid_images);

  end%while there is another line to process

  %get rid of empty cells if not all images were reconstructed
  %(because we pre-allocated the cell arrays)
  %image_structs = image_structs(~cellfun('isempty',image_structs));
  %point_2d_structs = point_2d_structs(~cellfun('isempty',point_2d_structs));
 
  image_structs(counter:end) = [];

  image_structs = nestedSortStruct2(image_structs, 'image_name'); 
  %figure this out with another scirpt, just a place holder for now 
  scale = 0;

  %save everything
  %save(fullfile(scene_path,IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE);
  save(fullfile(meta_path,RECONSTRUCTION_DIR, 'all', 'colmap_results', '0','image_structs.mat'), ...
                  IMAGE_STRUCTS, SCALE);
 
end%for i, each scene





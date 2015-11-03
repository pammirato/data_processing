%gets all the camera positions and orientations from the reconstruction output
%saves them in a map data structure, in a mat file. The structure maps from image name to a 
%       a vector [X,Y,Z,dX,dY,dZ]  the camera position, and a point along the vector of its
%							orientation
%

clear all, close all;
%initialize contants, paths and file names, etc. 
init;

 %size of rgb image in pixels
kImageWidth = 1920;
kImageHeight = 1080;

%distance from kinects in mm
kDistanceK1K2 = 291;
kDistanceK2K3 = 272;

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



scene_name = 'all';  %make this = 'all' to run all scenes

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
    
    %get the number of images for this scene
    num_total_rgb_images = length(dir(fullfile(scene_path,RGB_IMAGES_DIR))) - 2;

    %skip header
    fgetl(fid_images); 
    fgetl(fid_images); 
    line = fgetl(fid_images); 
  
    %holds all the structs, one per image, for this scene
    camera_structs = cell(1,num_total_rgb_images); 
 

    %for the orientation
    cur_vec = zeros(1,3);
    vec1 = [0;0;1;1];
    vec2 = [0;0;0;1];

    j = 1;

    while(ischar(line))

      %get image info
      line = fgetl(fid_images);
      line = strsplit(line);

      %get t and quat for this image
      cur_image = str2double(line(1:end-1)); 

      %stop when line is empty
      if(length(cur_image) < QZ)
          break;
      end

      %translation vector?
      t = [cur_image(TX); cur_image(TY); cur_image(TZ)];
      %t = t* 713.3619;
      
      
      %get quaternion adn rotation matrix
      quat = [cur_image(QW); cur_image(QX); cur_image(QY); cur_image(QZ)];
      R = quaternion_to_matrix(quat); % get rotation matrix from quaternion orientation

      worldpos = (-R' * t);
      
      %calculate the camera direction
      proj = [-R' worldpos];
      cur_vec = (proj * vec1) - (proj*vec2);
 
      %check to see if the image exists
      name = line{end};
      if ( exist(fullfile(scene_path,RGB_IMAGES_DIR, name),'file'))
         
          %put all the info in a struct, with a place holder for scaled
          %position
          cur_struct = struct(IMAGE_NAME, line{end}, TRANSLATION_VECTOR, t, ...
                             ROTATION_MATRIX, R, WORLD_POSITION, (-R' * t), ...
                             DIRECTION, -cur_vec, QUATERNION, quat, ...
                             SCALED_WORLD_POSITION, [0,0,0]);
     
          camera_structs{j} = cur_struct;
          
          j = j+1;
   
      end
      
                      
      %get Points2D 
      line =fgetl(fid_images); 

    end

    %get rid of empty cells if not all images were reconstructed
    camera_structs = camera_structs(~cellfun('isempty',camera_structs));

    
    
    
    
    %get a list of all the image file names
    temp = cell2mat(camera_structs);
    image_names = {temp.(IMAGE_NAME)};
    clear temp;

    %make a map from image name to camera_struct
    camera_struct_map = containers.Map(image_names, camera_structs);

    



        % 
    % %%%%%%%%%%%%%%% DETERMINE SCALE  OF RECONSTRUCTION  %%%%%%%%%%%%%%%%%%
    % 
    % 
    %hold the distances between camera positions for kinect1 to kinect2, and K2 to K3
    distances_k1k2 = cell(1,1);
    distances_k2k3 = cell(1,1);
    
    %keep track of where we are in the matrices
    k1k2_counter =1;
    k2k3_counter =1;
    
    %find all the distances from the reconstruction
    for i=1:length(image_names)
    
      cur_name = image_names{i};
    
    
      %if this is a k1, store the distance to the k2 above it 
      if( cur_name(end-4) == '1')
        %get name of image for k2 at same point
        k2_name = cur_name;
        k2_name(end -4) = '2';
    
        %get camera positions
        k1_data = camera_struct_map(cur_name);
        
        %this image might not exist
        try
          k2_data = camera_struct_map(k2_name);
        catch
          continue;
        end
        
        
        distances_k1k2{k1k2_counter} = pdist2(k2_data.(WORLD_POSITION)', k1_data.(WORLD_POSITION)');
        k1k2_counter =k1k2_counter+1;
    
      elseif( cur_name(end-4) == '2')
        %get name of image for k3 at same point
        k3_name = cur_name;
        k3_name(end -4) = '3';
    
        %get camera positions
        k2_data = camera_struct_map(cur_name);
    
        %this image might not exist
        try
          k3_data = camera_struct_map(k3_name);
        catch
          continue;
        end
        
    
        distances_k2k3{k2k3_counter} = pdist2(k3_data.(WORLD_POSITION)' ,k2_data.(WORLD_POSITION)');
        k2k3_counter =k2k3_counter+1;
    
    
      end %if cur_name == k1
    
    
    end%for i keys
    
    
    
    %get scale from ratio of actual_distance / average_reconstructed_distance
    scale_k1k2 = kDistanceK1K2 / mean(cell2mat(distances_k1k2));
    scale_k2k3 = kDistanceK2K3 / mean(cell2mat(distances_k2k3));
    
    %get the overall scale as a weighted average from the above
    scale  = ( length(distances_k1k2)*scale_k1k2  + length(distances_k2k3)*scale_k2k3 )...
              / ( length(distances_k1k2) + length(distances_k2k3) );
    % 
    % 
    % %%%%%%%%%%%%%%% END DETERMINE SCALE OF  RECONSTRUCTION  %%%%%%%%%%%%%%%%%%

    
    
    
    
    
    % %%%%%%%%%%%%%%% APPLY SCALE    %%%%%%%%%%%%%%%%%%
    
    
    
    for i=1:length(camera_structs)
        
        cur_struct = camera_structs{i};
        
        t = cur_struct.(TRANSLATION_VECTOR);
        R = cur_struct.(ROTATION_MATRIX);
        
        t = t*scale;
        
        cur_struct.(SCALED_WORLD_POSITION) = (-R' *t);
        
        camera_structs{i} = cur_struct;
        
    end%for camera_structs
    
    
    
    % %%%%%%%%%%%%%%% END APPLY SCALE   %%%%%%%%%%%%%%%%%%
    
        
    
   
    
    
    
    
    save(fullfile(scene_path, RECONSTRUCTION_DIR, CAMERA_STRUCTS_FILE), CAMERA_STRUCTS, SCALE);

end

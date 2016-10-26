%assigns pointers in each image struct to the image structs that are 
% clockwise and counter clockwise 
%to it. This represents a rotation in the scene. Only structs from the same cluster 
% are considered

%TODO - test

%CLEANED - yes 
%TESTED - no

clearvars;

%initialize contants, paths and file names, etc. 
init;


%% USER OPTIONS

scene_name = 'Kitchen_Living_08_1'; %make this = 'all' to run all scenes
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




%% MAIN LOOP -for each scene, assign the pointers for each image in that scene

for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


  %load image_structs for all images
  image_structs_file =  load(fullfile(meta_path, RECONSTRUCTION_RESULTS, ...
                                'colmap_results', ...
                                model_number, IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;

  %get a list of all the image file names
  image_names = {image_structs.(IMAGE_NAME)};

  %make a map from image name to image_struct
  image_structs_map = containers.Map(image_names,...
                                 cell(1,length(image_names)));
  %populate the map
  for jl=1:length(image_names)
    image_structs_map(image_names{jl}) = image_structs(jl);
  end
  
  %find max number of clusters 
  max_cluster_id = max([image_structs.cluster_id]);



  %for each cluster, assign the pointers to each image
  for jl=0:max_cluster_id

    %get the image structs in the current cluster
    cur_cluster = image_structs(find([image_structs.cluster_id] == jl));
   
    %for each image in the cluster 
    for kl=1:length(cur_cluster)
      %get this image's struct, position, and direction
      cur_struct = cur_cluster(kl);
      cur_world = cur_struct.world_pos;
      cur_dir = get_normalized_2D_vector(cur_struct.direction);
     
      %for debugging 
      if(strcmp(cur_struct.image_name, '0000010101.jpg'))
        breakp = 1;
      end
      
      %get the other structs in the cluster 
      other_structs = cur_cluster;
      other_structs(kl) = [];
     
      %keep track of which struct(image) is counter-clockwise(ccw) and clockwise(cw) 
      ccw_name = -1;
      cw_name = -1;
      ccw_angle = 360;
      cw_angle = 360;

      %for each other struct in this cluster
      for ll=1:length(other_structs)
        %get the sturct, position, and direction
        o_struct = other_structs(ll);
        o_world = o_struct.world_pos;
        o_dir = get_normalized_2D_vector(o_struct.direction);
       
        %get the angle between direction vectors of cur_struct(kl)  and o_struct(ll)
        v1 = cur_dir;
        v2 = o_dir;
        angle = atan2(v1(1)*v2(2)-v2(1)*v1(2),v1(1)*v2(1)+v1(2)*v2(2));
        angle = mod(-180/pi * angle, 360);        

        %angle is always the clockwise angle from cur_dir to o_dir
        %so if angle > 180, then o_dir can be reached with a ccw rotation of 360-angle
        if(angle > 180)
          %o_dir can be reached by this counter-clockwise rotataion
          angle = 360- angle;
          %if this is the smallest ccw rotation we have seen so far, update variables
          if(angle < ccw_angle)
            ccw_angle = angle;
            ccw_name = o_struct.image_name;
          end
        else%o_dir is clockwise
          %if this is the smallest cw rotation we have seen so far, update variables
          if(angle < cw_angle)
            cw_angle = angle;
            cw_name = o_struct.image_name;
          end
        end%if angle > 180
      end%for ll, each other point in cluster
     
      %update pointers in struct, and save struct 
      cur_struct.rotate_ccw = ccw_name;
      cur_struct.rotate_cw = cw_name;
      image_structs_map(cur_struct.image_name) = cur_struct;
    end%for kl, each point
  end%for jl, each cluster
 
  %save all the updated structs 
  image_structs = cell2mat(image_structs_map.values);
  save(fullfile(meta_path, RECONSTRUCTION_RESULTS, ...
                'colmap_results', model_number,  IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE);
end%for il,  each scene



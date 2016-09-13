%assigns points in each image struct to the image structs that clockwise and counter clockwise 
%to it. This represents a rotation in the scene. Only structs from the same cluster 
% are considered

clearvars;

%initialize contants, paths and file names, etc. 
init;


%TODO - test


%% USER OPTIONS

scene_name = 'Kitchen_Living_08_1'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'Kitchen_05_1','Office_01_1'};%populate this 

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




%% MAIN LOOP

for i=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{i};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


  %load image_structs for all images
  image_structs_file =  load(fullfile(meta_path, 'reconstruction_results', ...
                                group_name, 'colmap_results', ...
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
  for j=0:max_cluster_id

    cur_cluster = image_structs(find([image_structs.cluster_id] == j));
   
    %for each image in the cluster 
    for k=1:length(cur_cluster)
      cur_struct = cur_cluster(k);
      
      cur_world = cur_struct.world_pos;
      cur_dir = get_normalized_2D_vector(cur_struct.direction);
      
      if(strcmp(cur_struct.image_name, '0000010101.jpg'))
        breakp = 1;
      end
      
      
      other_structs = cur_cluster;
      other_structs(k) = [];
      
      ccw_name = -1;
      cw_name = -1;
      ccw_angle = 360;
      cw_angle = 360;
      for l=1:length(other_structs)
        o_struct = other_structs(l);
        o_world = o_struct.world_pos;
        o_dir = get_normalized_2D_vector(o_struct.direction);
        
        dotp = dot(cur_dir,o_dir);
        
        angle = acosd(dotp);
        v1 = cur_dir;
        v2 = o_dir;
        ang = atan2(v1(1)*v2(2)-v2(1)*v1(2),v1(1)*v2(1)+v1(2)*v2(2));
        ang = mod(-180/pi * ang, 360);        


%         if(~left(cur_world, cur_dir, o_dir))
%            if(angle < cw_angle)
%              cw_angle = angle;
%              cw_name = o_struct.image_name;
%            end
%         else
%            if(angle < ccw_angle)
%              ccw_angle = angle;
%              ccw_name = o_struct.image_name;
%            end
%         end% if dotp
          if(ang > 180)
            ang = 360- ang;
            if(ang < ccw_angle)
              ccw_angle = angle;
              ccw_name = o_struct.image_name;
            end
          else
            if(ang < cw_angle)
              cw_angle = angle;
              cw_name = o_struct.image_name;
            end
          end
      end%for l, each other point in cluster
      
      cur_struct.rotate_ccw = ccw_name;
      cur_struct.rotate_cw = cw_name;
      
      image_structs_map(cur_struct.image_name) = cur_struct;
        
    end%for k, each point
  end%for j, each cluster
  
  image_structs = cell2mat(image_structs_map.values);
  
  save(fullfile(meta_path, 'reconstruction_results', group_name, ...
                'colmap_results', model_number,  IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE);

end%for each scene



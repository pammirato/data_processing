%assigns points in each image struct to the image structs that clockwise and counter clockwise 
%to it. This represents a rotation in the scene. Only structs from the same cluster 
% are considered



%initialize contants, paths and file names, etc. 
init;


%TODO - test


%% USER OPTIONS

scene_name = 'Room14'; %make this = 'all' to run all scenes
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




%% MAIN LOOP

for i=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{i};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
 

  %load image_structs for all images
  image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;

  %make this for easy access to data 
  mat_image_structs = cell2mat(image_structs); 
  
  %make a map from image_name to image struct for easy saving later
  img_structs_map = containers.Map({mat_image_structs.image_name}, image_structs);
  
  %find max number of clusters 
  max_cluster_id = max([mat_image_structs.cluster_id]);


  %make a map from image_name to image struct for easy saving later
  image_structs_map = containers.Map({mat_image_structs.image_name}, image_structs);


  %for each cluster, assign the pointers to each image
  for j=1:max_cluster_id

    cur_cluster = mat_image_structs(find([mat_image_structs.cluster_id] == j));
   
    %for each image in the cluster 
    for k=1:length(cur_cluster)
      cur_struct = cur_cluster(k);
      
      cur_world = cur_struct.world_pos;
      cur_dir = get_normalized_2D_vector(cur_struct.direction);
      
      
      other_structs = cur_cluster;
      other_structs(k) = [];
      
      ccw_name = '';
      cw_name = '';
      ccw_angle = 360;
      cw_angle = 360;
      for l=1:length(other_structs)
        o_struct = other_structs(l);
        o_world = o_struct.world_pos;
        o_dir = get_normalized_2D_vector(o_struct.direction);
        
        dotp = dot(cur_dir,o_dir);
        
        angle = acosd(dotp);
        if(dotp > 0)
           if(angle < cw_angle)
             cw_angle = angle;
             cw_name = o_struct.image_name;
           end
        elseif(dotp < 0)
           if(angle < ccw_angle)
             ccw_angle = angle;
             ccw_name = o_struct.image_name;
           end
        end% if dotp
      end%for l, each other point in cluster
      
      cur_struct.rotate_ccw = ccw_name;
      cur_struct.rotate_cw = cw_name;
      
      image_structs_map(cur_struct.image_name) = cur_struct;
        
    end%for k, each point
  end%for j, each cluster
  
  image_structs = image_structs_map.values;
  
  save(fullfile(scene_path, IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE);

end%for each scene



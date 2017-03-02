%assigns pointers in each image sturct to the image structs that are in front and behind it, 
%representing forward or backward movements. Takes into account  direction of camera for each
%image, and does not assign pointers within a cluster

clearvars;

%initialize contants, paths and file names, etc. 
init;


%TODO  - test
%      - remove dependancy on cluster_ids(min dist apart)







%% USER OPTIONS

scene_name = 'Kitchen_05_1'; %make this = 'all' to run all scenes
group_name = 'all';
%group_name = 'all_minus_boring';
model_number = '0';
use_custom_scenes = 1;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'Kitchen_Living_02_1','Kitchen_Living_08_1','Bedroom_01_1','Office_01_1'} ;%populate this 
%custom_scenes_list = {'Kitchen_Living_01_1','Kitchen_Living_03_1','Kitchen_Living_03_2','Kitchen_Living_04_2','Kitchen_Living_06'};%populate this 


%whether to threshold on distance, then find the smallest angle, or 
%           threshold on angle, then find the smallest distance
threshold_on_distance = 0;


dir_angle_thresh = 10; %difference between direction of camera at images
move_angle_thresh = 10; %maximum allowed difference between point angle and direction angle
point_angle_thresh = 30;%angle between camera direction of org and vector from org to other point
dist_thresh = 1000;%distance threshold in mm, (must be closer than this)


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
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', group_name, ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;


  [image_structs.translate_right] = deal(-1);
  [image_structs.translate_left] = deal(-1);


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
  
  
  
  %for each cluster, assign pointers for all points in that cluster
  for j=0:max_cluster_id

    disp(['Cluster:  ' num2str(j)]);

    %get structs for this cluster 
    cur_cluster = image_structs(find([image_structs.cluster_id] == j));
   
    %get structs from all other clusters 
    other_structs = image_structs(find([image_structs.cluster_id] ~= j));
  
    %for each image in this cluster
    for k=1:length(cur_cluster)
      cur_struct = cur_cluster(k);


      if(strcmp(cur_struct.image_name,'0000010101.png'))
        breakp =1;
      end

     
      %get this image's world position and direciton 
      cur_world = cur_struct.world_pos*scale;
      cur_world = [cur_world(1), cur_world(3)];
      cur_dir = get_normalized_2D_vector(cur_struct.direction);
     

      %variables for comparisions, keeping track of best option so far             
      forward_angle = 0+move_angle_thresh;%angle between direction and point vectors
      forward_name = -1;%name of forward struct
      forward_dist = dist_thresh; %distance bewteen structs
      backward_angle = 180-move_angle_thresh;
      backward_name = -1;
      backward_dist = dist_thresh;
      left_angle = 90;%angle between direction and point vectors
      left_name = -1;%name of forward struct
      left_dist = dist_thresh; %distance bewteen structs
      right_angle = 90;
      right_name = -1;
      right_dist = dist_thresh;



      %for each image not in the current cluster
      for l=1:length(other_structs)

        %get world position/direction for other image
        o_struct = other_structs(l);
        o_world = o_struct.world_pos * scale;
        o_world = [o_world(1) o_world(3)];
        o_dir = get_normalized_2D_vector(o_struct.direction);
       
        %calculate angle between directions
        dir_angle = acosd(dot(cur_dir,o_dir));
        
        %get direction from current point to 'other' point 
        point_vec =o_world - cur_world;
        point_vec = point_vec/norm(point_vec);

        %calculate angle between cur_direction and point direction
        point_angle = acosd(dot(cur_dir,point_vec));
       
        %calculate distance between cur point and 'other' point 
        distance = sqrt( sum((o_world - cur_world).^2) );
        
        is_left= left(cur_world, (cur_world+cur_dir'), o_world); 
 
        %if we are thresholding on distance 
        if(threshold_on_distance)
          %if we are in the distance threshold
          if(dir_angle < dir_angle_thresh && distance<dist_thresh)
            %if this point angle is smaller than the best seen so far
            if(point_angle < forward_angle)
              forward_angle = point_angle;
              forward_name = o_struct.image_name;
            end
            %for backward pointer, point angle should approach 180 degrees
            if(point_angle > backward_angle)
              backward_angle = point_angle;
              backward_name = o_struct.image_name;
            end

            if(is_left)
              if(abs(point_angle-90) < left_angle)
                left_angle = abs(point_angle - 90);
                left_name = o_struct.image_name;
              end
            else
              if(abs(point_angle-90) < right_angle)
                right_angle = abs(point_angle - 90);
                right_name = o_struct.image_name;
              end
            end

          end
        else%if we are thresholding on the direction angle
          if(dir_angle < dir_angle_thresh) 
            %point angle determines forward or backward.
            %a point_angle near 0 means forward, near 180 means backward


            %want the closest point to current point that passes thresholds
            if(distance < forward_dist && point_angle < point_angle_thresh)
              forward_dist = distance;
              forward_name = o_struct.image_name;
            end
            %if 'other' point is behind current point, distance will be negative,
            %and so closest point will be the least negative, or largest
            if(distance < backward_dist && point_angle > (180-point_angle_thresh))
              backward_dist = distance;
              backward_name = o_struct.image_name;
            end
            if(is_left)
              if(distance < left_dist && abs(point_angle-90) < point_angle_thresh)
                left_dist = distance;
                left_name = o_struct.image_name;
              end
            else
              if(distance < right_dist && abs(point_angle-90) < point_angle_thresh)
                right_dist = distance;
                right_name = o_struct.image_name;
              end
            end
%          elseif(abs(dir_angle-90) < dir_angle_thresh)
%
%            if(is_left)
%              if(distance < left_dist && abs(point_angle-90) < point_angle_thresh)
%                left_dist = distance;
%                left_name = o_struct.image_name;
%              end
%            else
%              if(distance < right_dist && abs(point_angle-90) < point_angle_thresh)
%                right_dist = distance;
%                right_name = o_struct.image_name;
%              end
%            end
          end%if dir angle < thresh
        end %else, threshold on angel
      end%for l, each other point in cluster
      
      
      cur_struct.translate_forward = forward_name;
      cur_struct.translate_backward = backward_name;
      cur_struct.translate_left = left_name;
      cur_struct.translate_right = right_name;

      
      image_structs_map(cur_struct.image_name) = cur_struct;
        
    end%for k, each point
    
    %structs(find([structs.cluster_id] == j)) = cur_cluster;
  end%for j, each cluster
  
      
  image_structs = cell2mat(image_structs_map.values);
  
  save(fullfile(meta_path, 'reconstruction_results', group_name, ...
                'colmap_results', model_number,  IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE);

end%for each scene


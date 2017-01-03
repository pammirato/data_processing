function [] = assign_cluster_id(scene_name, cluster_size)
% Assign cluster id to each image struct. 
%
% A cluster is a set of images where the only movement action needed to visit any
% image in the cluster from any other image in the cluster is rotation. In other
% words a cluster is all the images at a point where the robot rotated during capture.
%
% Cluster ids are assigned simply by giving id=1 to the first 'cluster_size' images,
% id=2 to the next 'cluster_size' images, and so on. Images are sorted by index(name)
%
%
%INPUTS:
%         scene_name: char array of single scene name, 'all' for all scenes, 
%                     or a cell array of char arrays, one for each desired scene
%         cluster_size: OPTIONAL int, 12(default),
%                         the number of images that should be in a cluster


%TODO  

%CLEANED - yes 
%TESTED - no

%clearvars;

%initialize contants, paths and file names, etc. 
init;


%% USER OPTIONS


%scene_name = 'Kitchen_Living_08_1'; %make this = 'all' to run all scenes
model_number = '0';
%use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
%custom_scenes_list = {};%populate this 


method = 2; %  0 - by hand, get user to draw a box around each cluster
            %  1 - image index,  just assign cluster_id = image_index
            %  2 - by cluster size, assign cluter_id = image_index mod cluster size
if(~exist('cluster_size', 'var'))
  cluster_size = 12;
end

%% SET UP GLOBAL DATA STRUCTURES

%get the names of all the scenes
d = dir(ROHIT_BASE_PATH);
d = d(3:end);
all_scenes = {d.name};


%determine which scenes are to be processed 
if(iscell(scene_name))
  %if we are using the custom list of scenes
  all_scenes = custom_scenes_list;
elseif(~strcmp(scene_name, 'all'))
  %if not using custom, or all scenes, use the one specified
  all_scenes = {scene_name};
end


%% MAIN LOOP

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
  scale  = image_structs_file.scale;%just keep track of this to save later


  %choose a method
  if(method == 0) % by hand

    %get the world positions of all images
    world_positions = [image_structs.scaled_world_pos];

    %plot the 2D positions 
    plot(world_positions(1,:),world_positions(3,:),'r.');
    axis equal;

    %% get user to 'draw' bounding box around each cluster, by clicking twice

    but = 1;%what mouse button was pressed
    boxes = cell(0); %holds all the drawn boxes
    while(but ==1)     

      %get two mouse clicks
      [xi, yi, but] = ginput(2);
       
      %make sure both clicks were left click
      if(sum(but) ~= 2)
          break;
      end

      %add the box
      boxes{end+1} = [xi(1), yi(1), xi(2), yi(2)];
    end%while but == left click


    %for visualization of results
    colors = zeros(3,length(boxes));
    for j=1:length(boxes)

        colors(:,j) = rand(3,1);
    end%for j


    %% ASSIGN CLUSTER TO EACH IMAGE STRUCT

    hold on;

    %for each struct, see what box it is inside, and assign the apporpriate cluster
    for jl=1:length(image_structs)

       %get the cur struct and its 2D position
       cur_struct = image_structs(jl);
       cur_point = cur_struct.scaled_world_pos;
       cp = [cur_point(1),cur_point(3)];

       cluster_id = -1;
       %check every box to see if this point is in one of them
       counter = 1;
       while(cluster_id==-1 && counter <= length(boxes))
           cb = boxes{counter};

           %see if the point is in the box
           if(cp(1) > cb(1) && cp(1) < cb(3))
               if(cp(2)>cb(4) && cp(2) < cb(2))
                   cluster_id = counter;
               end
           end
           counter = counter +1;
       end%while

      %assign the found cluster,
       if(cluster_id ~= -1)
           %color it for visualizaiton 
           plot(cp(1),cp(2),'.','Color',colors(:,cluster_id));

           cur_struct.cluster_id = cluster_id;
           image_structs(jl) = cur_struct;
       end
    end %for j

    %allow for new plot
    hold off;


  elseif(method == 1) % image index


    for jl=1:length(image_structs)
      cur_struct = image_structs(jl);
     
      %get the name and index of the current iamge 
      cur_image_name = cur_struct.image_name;
      cur_image_index =  str2num(cur_image_name(1:6));
   
      %assign the index to the cluster id 
      cur_struct.cluster_id = cur_image_index;
      image_structs(jl) = cur_struct;
    end%for j, each image_struct

  elseif(method == 2) %cluster size 


    for jl=1:length(image_structs)
      cur_struct = image_structs(jl);
     
      %get the name and index of the current iamge 
      cur_image_name = cur_struct.image_name;
      cur_image_index =  str2num(cur_image_name(1:6));
   
      %assign the index to the cluster id 
      cur_struct.cluster_id = floor((cur_image_index-1)/cluster_size);
      image_structs(jl) = cur_struct;
    end%for j, each image_struct




  else %not supported
    display('method not supported');
  end




  %% display the assign clusters

  %get all the clusters and give a random color to each cluster
  cluster_ids = [image_structs.cluster_id];
  colors = rand(3, max(cluster_ids)+1);
 
  %get all the camera positions 
  world_poses = [image_structs.world_pos];

  %plot  
  figure;
  hold on;
  for jl=1:length(world_poses)
    color = colors( :,image_structs(jl).cluster_id + 1);
    pos = image_structs(jl).world_pos;
    plot(pos(1), pos(3),'.', 'Color', color);  
  end
  hold off;


  %save the update image structs  
  save(fullfile(meta_path, RECONSTRUCTION_RESULTS, 'colmap_results', ...
                model_number,  IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE);
end%for il,  each scene

end

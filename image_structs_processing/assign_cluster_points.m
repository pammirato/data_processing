% allows HAND LABELING of cluster ids by showing a 2D plot of camera positions and 
% having a user draw a box(using 2 clicks, top left and bottom right) around each cluster 

%initialize contants, paths and file names, etc. 
init;


%TODO  - add automatic option using output from collection programs


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

  %get the world positions of all images
  temp = cell2mat(image_structs);
  world_positions = [temp.scaled_world_pos];

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
  for j=1:length(image_structs)

     %get the cur struct and its 2D position
     cur_struct = image_structs{j};
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
         image_structs{j} = cur_struct;
     end
  end %for j

  %allow for new plot
  hold off;
   
  %save the update image structs  
  save(fullfile(scene_path,IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE);
  
end%for i,  each scene


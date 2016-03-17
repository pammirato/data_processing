%scale the camera positions of the reconstruction to be in milimeters
%uses depth images with the reconstructed points to determine scale 


%TODO  - what to add next

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'SN208_Density_1by1'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


num_images_thresh = 100;%how many images must have 'seen' a 3d point
error_thresh = 1; %max error for a reconstructs(3d) point



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



  %%%%%%%%%%%%%%%%%%% DENSITY STUFF %%%%%%%%%%%%%%%%%%%%%%%%%%%      
  image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  image_structs = cell2mat(image_structs_file.(IMAGE_STRUCTS));
  scale  = image_structs_file.scale;

  image_names = {image_structs.image_name};
  structs_map = containers.Map({image_structs.image_name},image_structs_file.(IMAGE_STRUCTS));


  cluster_ids= [image_structs.cluster_id];
  first_col = image_structs(cluster_ids < 11);
  
  
  dists = zeros(1,9);
  
  
  prev_pos = first_col(1).world_pos;
  
  for j=2:size(first_col,2)
      
      cur_pos = first_col(j).world_pos;
      
      dists(j-1) = cur_pos(3) - prev_pos(3);
      
      prev_pos = cur_pos;
      
  end%for j, each position in first col
  
  
  mean_dist = mean(dists);
  
  scale = 100/mean_dist; 
  
  
  
  
  
  
  
  %% apply scale
  
%  for j=1:length(image_names)
%      cur_name = image_names{j};
%      
%      cur_struct = structs_map(cur_name);
%      
%      cur_struct.scaled_world_pos = cur_struct.world_pos * scale;
%      
%      structs_map(cur_name) = cur_struct;
%      
%  end
      
        
        

  %%%%%%%%%%%%%%%%%%% DENSITY STUFF %%%%%%%%%%%%%%%%%%%%%%%%%%%      
    
    
    
    
    
    
    
    
    
    



  %get the image structs and make a map
  image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);

  temp = cell2mat(image_structs);
  image_ids = {temp.image_id};
  image_id_to_struct_map = containers.Map(image_ids,image_structs);


  %get the point2D structs and make a map
  point2D_structs_file = load(fullfile(meta_path,RECONSTRUCTION_DIR,'point_2d_structs.mat'));
  point2D_structs = cell2mat(point2D_structs_file.point_2d_structs);

  image_names = {point2D_structs.image_name};
  p2d = {point2D_structs.points_2d};
  image_name_to_p2d_map = containers.Map(image_names,p2d);


  %get the 3d reconstructed points
  points3D = load(fullfile(scene_path,RECONSTRUCTION_DIR,'points3D.mat'));
  points3d = points3D.points3d;
  %sort the points in descending order based on error
  points3D  = nestedSortStruct(points3d,'error');



   %find the reconstructed point that has been seen by the largest number of images
   % while having error below the error_thresh
   points3D_with_low_error = points3d(find([points3D.error] < error_thresh)); 





 

   cur_error = 0;
   prev_point = -1;
   point = -1;
   while(cur_error < error_thresh)


    p3index = [points3D.num_image_ids];
    b = find(p3index > num_images_thresh);
    seen_points = points3D(b);
    if(length(seen_points) < 1)
        break;
    end

    prev_point = point;
    point = seen_points(1);

    cur_error = point.error;
    num_images_thresh = num_images_thresh + 100;
   end


    image_ids = point.image_ids;
    point2_ids = point.point2_ids;



    depths = -ones(1,length(image_ids));
    dists = -ones(1,length(image_ids));
    ydists = -ones(1,length(image_ids));

    for j=1:length(image_ids)

        cur_image_id = image_ids(j);
        cur_p2_id = point2_ids(j);
        image_struct = image_id_to_struct_map(num2str(cur_image_id));
        p2d = image_name_to_p2d_map(image_struct.image_name);

        xs = p2d(1:3:end);
        ys = p2d(2:3:end);
        p3ids = p2d(3:3:end);


        p3index = find(p3ids == point.id);
        p3index = p3index(1);
        p3id=  p3ids(p3index);

        x = max(1,floor(xs(p3index)));
        y = max(1,floor(ys(p3index)));

        depth_img = imread(fullfile(scene_path,'raw_depth', ...
                        strcat(image_struct.image_name(1:8),'03.png')));


        depths(j) = depth_img(y,x);


        cam_pos = image_struct.world_pos;

        dists(j) = sqrt( (cam_pos(1)-point.x)^2 + (cam_pos(2)-point.y)^2 + (cam_pos(3)-point.z)^2 );

        ydists(j) = point.y- cam_pos(2);
    end


    scales = depths./dists;
    temp = find(scales);
    scales = scales(temp);

    scale = mean(scales);


    for j=1:length(image_structs)
        cur_struct = image_structs{j};

        t = cur_struct.(TRANSLATION_VECTOR);
        R = cur_struct.(ROTATION_MATRIX);

        t = t*scale;

        cur_struct.(SCALED_WORLD_POSITION) = (-R' *t);

        image_structs{j} = cur_struct;

    end%for j
    
    image_structs = structs_map.values;
    
    save(fullfile(scene_path, RECONSTRUCTION_DIR, IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE); 
end

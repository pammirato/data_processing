%scale the camera positions of the reconstruction to be in milimeters
%uses depth images with the reconstructed points to determine scale 


%TODO  -use multiple point3ds  

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'SN208_Density_1by1'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


num_images_thresh = 20;%how many images must have 'seen' a 3d point
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
  points3d_file = load(fullfile(meta_path,RECONSTRUCTION_DIR,'points3D.mat'));
  points3d = points3d_file.points3d;

  %find the reconstructed point that has been seen by the largest number of images
  % while having error below the error_thresh
 
  %first threshold on error 
  points3d = points3d([[points3d.error] < error_thresh]); 

  %get the point that has been seen by the most images
  [~,max_index] = max([points3d.num_image_ids]);
  point3d_to_use  = points3d(max_index); 


  %keep trying point3ds until one has enough data(depths > 0)
  point_is_good = 0;
  while(~point_is_good)


    %% now compare the depth of the point in each image to the 
    %  distance from the images postion and the 3D point

    %get all the image ids and point2d ids. 
    %point2d is the location in the image of the 3D point
    image_ids = point3d_to_use.image_ids;
    point2_ids = point3d_to_use.point2_ids;


    %store data
    depths = -ones(1,length(image_ids)); %depth in image
    dists = -ones(1,length(image_ids)); %3D distance
    ydists = -ones(1,length(image_ids)); %1D distance

    %for each image, get the depth and distance
    for j=1:length(image_ids)

      %get the image struct and p2d struct from the maps
      cur_image_id = image_ids(j);
      cur_p2_id = point2_ids(j);
      image_struct = image_id_to_struct_map(num2str(cur_image_id));
      p2d = image_name_to_p2d_map(image_struct.image_name);

      %% find the point2d in this image that matches the point3d 

      %get all the x,y,and p2d id values for this image
      xs = p2d(1:3:end);
      ys = p2d(2:3:end);
      p3ids = p2d(3:3:end);

      %find the index for the point 3d we are using
      p3index = find(p3ids == point3d_to_use.id);
      p3index = p3index(1);
      p3id=  p3ids(p3index);
    
      %get the x and y of in image coordinates
      x = max(1,floor(xs(p3index)));
      y = max(1,floor(ys(p3index)));

      %get the depth 
      depth_img = imread(fullfile(scene_path,HIGH_RES_DEPTH, ...
                      strcat(image_struct.image_name(1:8),'03.png')));

      depths(j) = depth_img(y,x);

      %get the 3D camera position for this image
      cam_pos = image_struct.world_pos;

      %find the 3D distance between the camera and the point3d
      dists(j) = sqrt( (cam_pos(1)-point3d_to_use.x)^2 + (cam_pos(2)-point3d_to_use.y)^2 + ...
                         (cam_pos(3)-point3d_to_use.z)^2 );
      %find the 1D distance between the camera and the point3d
      ydists(j) = point3d_to_use.y- cam_pos(2);
    end%for j, each image_id

    if(length(find(depths)) > num_images_thresh)
      point_is_good = 1;
    else%we need to get a new point
      %delete the point that was jsut used
      points3d(max_index) = [];      

      if(isempty(points3d))
        disp('could not find a good point3d');
        return;%end script
      end
      %get the point that has been seen by the most images
      [~,max_index] = max([points3d.num_image_ids]);
      point3d_to_use  = points3d(max_index); 
    end%if we had enough valid depths
  end%while point 

    %calculate the scale for each image
    scales = depths./dists;
    %get rid of 0 entries(depth was 0)
    scales = scales(scales ~= 0);

    %get the average scale
    scale = mean(scales);

    %% apply the scale
    for j=1:length(image_structs)
        cur_struct = image_structs{j};
        cur_struct.(SCALED_WORLD_POSITION) = cur_struct.world_pos * scale;
        image_structs{j} = cur_struct;
    end%for j
  
    %save the new data 
    save(fullfile(scene_path, IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE); 
end%for i, each scene

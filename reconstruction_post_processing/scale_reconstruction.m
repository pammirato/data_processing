%scale the camera positions of the reconstruction to be in milimeters
%uses depth images with the reconstructed points to determine scale 
%
% GIVES A POOR ESTIMATE:  NEEDS TO BE REFINED
%


%TODO  -do better than picking average
%       -check if scale is no already zero

%CLEANED - ish 
%TESTED - yes 


%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Office_03_1'; %make this = 'all' to run all scenes
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 

num_images_thresh = 20;%how many images must have 'seen' a 3d point
error_thresh = 1; %max error for a reconstructed(3d) point
num_3d_points_to_check = 5;


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

for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %get total number of images in the scene
  num_rgb_images = length(get_scenes_rgb_names(scene_path));

  %get the image structs and make a map
  image_structs_file =  load(fullfile(meta_path,RECONSTRUCTION_RESULTS, ...
                              'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);

  %get all the image ids, and make a map from image id to image struct
  image_ids = {image_structs.image_id};
  image_id_to_struct_map = containers.Map(image_ids,cell(1,length(image_ids)));
  for jl=1:length(image_ids)
    image_id_to_struct_map(image_ids{jl}) = image_structs(jl);
  end 


  %get the point2D structs and make a map
  point2D_structs_file = load(fullfile(meta_path,RECONSTRUCTION_RESULTS,...
                        'colmap_results', model_number,'point_2d_structs.mat'));
  point2D_structs =point2D_structs_file.point_2d_structs;

  image_names = {point2D_structs.image_name};
  p2d = {point2D_structs.points_2d};
  image_name_to_p2d_map = containers.Map(image_names,p2d);


  %get the 3d reconstructed points
  points3d_file = load(fullfile(meta_path,RECONSTRUCTION_RESULTS, 'colmap_results',...
                          model_number, 'points3D.mat'));
  points3d = points3d_file.points3d;

  %find the reconstructed point that has been seen by the largest number of images
  % while having error below the error_thresh
 
  %first threshold on error 
  points3d = points3d([[points3d.error] < error_thresh]); 

  %get the points that has been seen by the most images
  points3d = nestedSortStruct2(points3d, 'num_image_ids');
  most_seen_3d_points = points3d(end-num_3d_points_to_check:end);

    
  %keep track of the scale calulated for each 3d point 
  most_seen_scales = zeros(1,length(most_seen_3d_points));

  %keep track of scale calclulated for each image for each 3d point
  all_scales = cell(1,length(most_seen_scales));

  %for each 3d point,
  for jl=1:length(most_seen_3d_points)
    point3d_to_use = most_seen_3d_points(jl);

    %% now compare the depth of the point in each image to the 
    %  distance from the images postion and the 3D point

    %get all the image ids and point2d ids. 
    %point2d is the location in the image of the 3D point ********* read this
    p3_image_ids = point3d_to_use.image_ids;
    point2_ids = point3d_to_use.point2_ids;


    %store data
    depths = zeros(1,length(p3_image_ids)); %depth in image
    dists = zeros(1,length(p3_image_ids)); %3D distance
    ydists = zeros(1,length(p3_image_ids)); %1D distance

    %for each image, get the depth and distance
    for kl=1:length(p3_image_ids)

      %get the image struct and p2d struct from the maps
      cur_image_id = p3_image_ids(kl);
      if(cur_image_id > num_rgb_images) %this was a handscan image 
        continue;
      end


      cur_p2_id = point2_ids(kl);
      try
        image_struct = image_id_to_struct_map(num2str(cur_image_id));
      catch
        disp('error: no image struct');
        continue;
      end

      %% find the point2d in this image that matches the point3d 
      p2d = image_name_to_p2d_map(image_struct.image_name);

      %get all the x,y,and p2d id values for this image
      xs = p2d(1:3:end);
      ys = p2d(2:3:end);
      p3ids = p2d(3:3:end);

      %find the index for the point 3d we are using
      p3index = find(p3ids == point3d_to_use.id);
      p3index = p3index(1);
      p3id = p3ids(p3index);
    
      %get the x and y of in image coordinates
      x = max(1,floor(xs(p3index)));
      y = max(1,floor(ys(p3index)));

      %get the depth 
      depth_img = imread(fullfile(scene_path,HIGH_RES_DEPTH, ...
                      strcat(image_struct.image_name(1:8),'03.png')));

      depths(kl) = depth_img(y,x);

      %get the 3D camera position for this image
      cam_pos = image_struct.world_pos;
      cam_dir = image_struct.direction;
      assert(abs(1 - norm(cam_dir)) < .001);


      %find the 3D distance between the camera and the point3d
      %distance is between the 3D point and plane defined by camera pos and camera direction
      %dists(kl) = sqrt( (cam_pos(1)-point3d_to_use.x)^2 + (cam_pos(2)-point3d_to_use.y)^2 + ...
      %                   (cam_pos(3)-point3d_to_use.z)^2 );
      p3d_pos = [point3d_to_use.x; point3d_to_use.y; point3d_to_use.z];
      cam_point_vec = p3d_pos - cam_pos;
      dists(kl) = floor(cam_point_vec' * cam_dir); %make all dists integers

      %find the 1D distance between the camera and the point3d
      ydists(kl) = point3d_to_use.y- cam_pos(2);
    end%for kl, each image_id

    %calculate the scale for each image
    scales = depths./dists;
    %get rid of 0 entries(depth was 0)
    scales = scales(scales ~= 0);
    scales(isnan(scales)) = [];
    %get the average scale
    scale = median(scales);

    all_scales{jl} = scales;

    most_seen_scales(jl) = scale;
  end%for jl, each most seen point 

  scale = mean(most_seen_scales);
  %scale = mode(most_seen_scales);

  %% apply the scale
  for jl=1:length(image_structs)
      cur_struct = image_structs(jl);
      cur_struct.(SCALED_WORLD_POSITION) = cur_struct.world_pos * scale;
      image_structs(jl) = cur_struct;
  end%for jl

  %save the new data 
  save(fullfile(meta_path,RECONSTRUCTION_RESULTS,'colmap_results',model_number,... 
                   IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE); 
end%for il, each scene

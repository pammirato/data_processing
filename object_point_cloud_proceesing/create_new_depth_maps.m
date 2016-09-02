%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object

%TODO -get rid of image structs map. Just use indexes. (Make it sorted?)


%clearvars;

%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


debug =0;

kinect_to_use = 1;

%size of rgb image in pixels
kImageWidth = 1920;
kImageHeight = 1080;



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

  %:% get camera info
  fid_camera =  fopen(fullfile(meta_path,'reconstruction_results', group_name, ...
                                'colmap_results', model_number,'cameras.txt'));

  %the camera follows this camera model from opencv
  % http://docs.opencv.org/master/db/d58/group__calib3d__fisheye.html#gsc.tab=0 


  %skip the file header
  line = fgetl(fid_camera);
  line = fgetl(fid_camera);
  line = fgetl(fid_camera);
  line = fgetl(fid_camera);

  %split the line with the camera parameters
  line = strsplit(line);

  K = zeros(3); %camera intrinsic matrix
  distortion = zeros(1,4);%distortion parameters

  %set the camera intrinsic paramters from the file
  K(1,1) = str2double(line{5});
  K(1,3) = str2double(line{7});
  K(2,2) = str2double(line{6});
  K(2,3) = str2double(line{8});
  K(3,3) = 1;

  %set the camera distortion paramters from the file
  distortion(1) = str2double(line{9});
  distortion(2) = str2double(line{10});
  distortion(3) = str2double(line{11});
  distortion(4) = str2double(line{12});


  fclose(fid_camera);


  %% get info about camera position for each image
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', group_name, ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;

  %remove image structs that were not reconstructed. These will be hand labeled
  no_R_inds = cellfun('isempty', {image_structs.R});
  no_R_structs = image_structs(no_R_inds);
  image_structs = image_structs(~no_R_inds);

  %get a list of all the image file names
  image_names = {image_structs.(IMAGE_NAME)};

  %make a map from image name to image_struct
  image_structs_map = containers.Map(image_names,...
                                 cell(1,length(image_names)));
  %populate the map
  for jl=1:length(image_names)
    image_structs_map(image_names{jl}) = image_structs(jl);
  end

  cur_image_name = image_names{1};
  cur_image_struct = image_structs_map(cur_image_name);
  disp(cur_image_name);
  scaled_camera_pos = cur_image_struct.scaled_world_pos;
  %global_pc = pcread(fullfile(meta_path, 'point_clouds', strcat(cur_image_name(1:10), '.ply')));
  %global_pc = pcread('~/br011_mod14_005_4500max.ply');
  %global_pc = pcread('~/br011_mod7.ply');
  
  %global_locs = global_pc.Location;
  %global_homog_points = [global_locs ones(length(global_locs),1)]';


  for jl= 1:length(image_names) 
    
    
    %% get the image name, position/direction info 
    cur_image_name = image_names{jl};
    cur_image_struct = image_structs_map(cur_image_name);
    disp(cur_image_name);
    depth_img = imread(fullfile(scene_path, 'high_res_depth', strcat(cur_image_name(1:8), ...
                          '03.png')));



    %% find images that see the same area approximately
    cam_poses = [image_structs.world_pos];    
    cam_dirs = [image_structs.direction];
    cam_poses = cam_poses([1 3], :); %reduce to 2d
    cam_dirs = cam_dirs([1 3], :) + cam_poses;

    %get equations of lines
    slopes = (cam_poses(2,:) - cam_dirs(2,:)) ./ (cam_poses(1,:) - cam_dirs(1,:));
    intercepts = cam_poses(2,:) - slopes.*cam_poses(1,:);

    cur_pos = cur_image_struct.world_pos;
    cur_dir = cur_image_struct.direction;
    cur_pos = cur_pos([1 3]);
    cur_dir = cur_dir([1 3]) + cur_pos;

    cur_slope = (cur_pos(2) - cur_dir(2)) / (cur_pos(1) - cur_dir(1));
    cur_intercept = cur_pos(2) - cur_slope*cur_pos(1);


    x_intersections = (intercepts - cur_intercept) ./ (slopes - cur_slope);
    y_intersections = cur_slope.*x_intersections + cur_intercept;

    if(cur_dir(1) > cur_pos(1))
      good_inds = find(x_intersections > cur_pos(1));
    else
      good_inds = find(x_intersections < cur_pos(1));
    end


    useful_structs = image_structs(good_inds);











    cur_global_locs = global_locs; 
    %% make the pc depth image  
    R = cur_image_struct.R;
    t = cur_image_struct.t;
    cam_pos = cur_image_struct.world_pos * 389;
    cam_dir = cur_image_struct.direction;
    
    assert(abs(norm(cam_dir) - 1) < .0001);
    

    P = [R t];
    oriented_points = P * global_homog_points;

    global_zs = oriented_points(3,:);
    global_bad_inds = find(global_zs < 0);
    cur_global_locs(global_bad_inds,:) = [];

    global_distorted_points = project_points_to_image(cur_global_locs, K, R, t, distortion);
   

    %% remove points outside image
    bad_inds=find(global_distorted_points(1,:)<1 | global_distorted_points(1,:)>kImageWidth);
    global_distorted_points(:, bad_inds) = [];
    cur_global_locs(bad_inds,:) = [];
    
    %check y values
    bad_inds=find(global_distorted_points(2,:)<1 | global_distorted_points(2,:)>kImageHeight);
    global_distorted_points(:, bad_inds) = [];
    cur_global_locs(bad_inds,:) = [];


    %create vector from camera center to each point
    cam_to_point_vecs = cur_global_locs*389 - repmat(cam_pos', size(cur_global_locs,1),1);
    global_dists = (cam_to_point_vecs * cam_dir)';
    
    

    %get distance from camera to each point
    %global_dists = pdist2(cam_pos', cur_global_locs*389);

    %sort the global points based on their distsance to the camera
    global_locs_and_dists = [cur_global_locs'; global_dists];
    [sorted_locs_and_dists, index] = sortrows(global_locs_and_dists',4);
    
    sorted_locs_and_dists = sorted_locs_and_dists';
    sorted_global_locs = sorted_locs_and_dists(1:3, :);
    sorted_global_dists = sorted_locs_and_dists(4,:);
    sorted_global_distorted_points = global_distorted_points(:, index);
    
    %keep only the closest point for each pixel. If two global points projected 
    %to the same pixel, keep only the point closest to the camera
    [unique_global_distorted_points, IA, IC] = ...
                           unique(sorted_global_distorted_points', 'rows', 'stable');

    unique_global_distorted_points = unique_global_distorted_points';
    unique_global_locs = sorted_global_locs(:, IA);
    unique_global_dists = sorted_global_dists(:,IA);


    %now make a depth image 
    pc_depth_img = zeros(kImageHeight, kImageWidth);
    pc_inds = sub2ind(size(pc_depth_img), unique_global_distorted_points(2,:), ...
                                          unique_global_distorted_points(1,:)); 
    pc_depth_img(pc_inds)  = double(unique_global_dists);


    good_depth_flags = (depth_img > 500) & (depth_img<5000);
   
    thresh_depth = double(depth_img) .* double(good_depth_flags);
    
    thresh_pc_depth = pc_depth_img .* double(~good_depth_flags);
    
    new_depth = uint16(thresh_depth + thresh_pc_depth);

    imwrite(new_depth, fullfile(meta_path, 'point_depths', ...
              strcat(cur_image_name(1:8), '05.png')));
  end%for jl, each image name

end%for i, each scene_name



%TODO -get rid of image structs map. Just use indexes. (Make it sorted?)


%clearvars;

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Kitchen_05_2'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 

similar_point_dist_thresh = .001;
slice_dists = [300:100:1000];
dir_angle_threshs = [30:30:90];
num_pcs_to_use = 24;
max_valid_depth = 7000;

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







s = 5;
f = floor(s/2);
ul_fil = zeros(s,s);
ul_fil(1:f,1:f) = 1;
ur_fil = zeros(s,s);
ur_fil(1:f,f:s) = 1;
dl_fil = zeros(s,s);
dl_fil(f:s,1:f) = 1;
dr_fil = zeros(s,s);
dr_fil(f:s,f:s) = 1;
count_fil = ones(s);
mean_fil = fspecial('average', s);





%% MAIN LOOP

for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

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


  depths_loaded = 0;
  load_depths = input('Load all depths?(y/n)' , 's');


  %load all the depths
  if((load_depths=='y'))

    %get names of all the rgb images in the scene
    %image_names = get_names_of_X_for_scene(scene_name,'rgb_images');

    %will hold all the depth images
    depth_images = cell(1,length(image_names));

    %for each rgb image, load a depth image
    for jl=1:length(image_names)
        rgb_name = image_names{jl};
        
        %depth_images{jl} = imread(fullfile(scene_path, 'filled_high_res_depth', ... 
        %         strcat(rgb_name(1:8),'04.png') ));
        depth_images{jl} = imread(fullfile(scene_path, 'high_res_depth', ... 
                 strcat(rgb_name(1:8),'03.png') ));
        %depth_images{jl} = imread(fullfile(meta_path, 'point_depths', ... 
        %               strcat(cur_image_name(1:8),'05.png') ));
    end% for i, each image name
    
    depth_img_map = containers.Map(image_names, depth_images);
    
    depths_loaded = 1;
  end%if we should load all the depths)


  %if we are told to not load the depths, see if they were already loaded
  if(load_depths == 'n')
    a = input('Are depths loaded?(y/n)' , 's');
    if(a=='y')
      depths_loaded = 1;
    end
  end








  %% load the sparse mesh
  %[mesh_vertices, mesh_faces] = read_ply(fullfile(meta_path, 'sparse_mesh.ply'));





  %% get camera info
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


  %% for reverse projecting depths to point clouds
  intrinsic = K;

  k1 = distortion(1);
  k2 = distortion(2);
  k3 = distortion(3);
  k4 = distortion(4);

  fx = intrinsic(1,1);
  fy = intrinsic(2,2);
  cx = intrinsic(1,3);
  cy = intrinsic(2,3);

  col_pos = repmat([1:1920], 1080,1);
  row_pos = repmat([1:1080]', 1, 1920);
  pixel_pos = zeros(1080,1920,2);
  pixel_pos(:,:,1) = row_pos;
  pixel_pos(:,:,2) = col_pos;
  pixel_pos = reshape(pixel_pos, 1080*1920,2);
  
  a = [-1:.001:1];
  b = [-1:.001:1];
  a(1001) = [];
  b(1001) = [];
 
  r = sqrt( (a).^2 + (b).^2);
  theta = atan(r);

  thetad = theta .* (1 + k1*(theta.^2) + k2*(theta.^4) + k3*(theta.^6) + k4*(theta.^8));

  xx = (thetad./r) .* a;
  yy = (thetad./r) .* b; 
  

  a_map = zeros(1,length(a));
  b_map = zeros(1,length(b));
  index_map_mult = 1000;
  index_map_add = 1000;
  a_map(floor(xx*index_map_mult + index_map_add)) = a;
  b_map(floor(yy*index_map_mult + index_map_add)) = b;
  q = find(a_map == 0);
  need_vals = q(27:end-28);
  for jl=1:length(need_vals)
    ind = need_vals(jl);
    a_map(ind) = .5*a_map(ind-1) + .5*a_map(ind+1);
    b_map(ind) = .5*b_map(ind-1) + .5*b_map(ind-1);
  end

  


  %%






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

  %image_names = {'0006460101.png', '0006810101.png'};
  %image_names = image_names(950:end);
  for jl= 1:length(image_names) 
    
    
    %% get the image name, position/direction info 
    cur_image_name = image_names{jl};
    cur_image_struct = image_structs_map(cur_image_name);
    R = cur_image_struct.R;
    t = cur_image_struct.t; 
    P = [R t];
    cam_pos = cur_image_struct.world_pos *scale;
    cam_dir = cur_image_struct.direction;
    disp(cur_image_name);
    %depth_img = imread(fullfile(scene_path, 'high_res_depth', strcat(cur_image_name(1:8), ...
    %                      '03.png')));
    if(depths_loaded)
      cur_depth_img = depth_img_map(cur_image_name);
    else
      cur_depth_img = imread(fullfile(scene_path, 'high_res_depth', strcat(cur_image_name(1:8), ...
                        '03.png')));
    end
    %cur_pc = pcread(fullfile(meta_path, 'point_clouds', strcat(cur_image_name(1:10), ...
    %                                  '.ply')));

    depth_img = cur_depth_img;



%     mesh_depth_img = zeros(size(depth_img));
%     temp_img = zeros(size(depth_img));
%     col_pos = repmat([1:1920], 1080,1);
%     row_pos = repmat([1:1080]', 1, 1920);
%     pixel_pos = zeros(1080,1920,2);
%     pixel_pos(:,:,1) = row_pos;
%     pixel_pos(:,:,2) = col_pos;
%     pixel_pos = reshape(pixel_pos, 1080*1920,2);
%     for kl=1:size(mesh_faces,1)
%       
%       kl_face = mesh_faces(kl,:);
%       vertices = mesh_vertices(kl_face,:);
% 
%       %project vertices into image
%       oriented_vertices = P * [vertices'; ones(1, length(vertices))];
%       if(min(oriented_vertices(3,:)) < 0)
%         continue;
%       end
%       image_locs = project_points_to_image(vertices, K,R,t,distortion);   
%       if(min(image_locs(1,:)) < 1 | max(image_locs(1,:)) > kImageWidth | ...
%          min(image_locs(2,:)) < 1 | max(image_locs(2,:)) > kImageHeight)
%         continue;
%       end
%        
%       %pixels_in_face = isPointInTriangle(pixel_pos, ...
%       %                                   image_locs(1,:), image_locs(2,:), image_locs(3,:)); 
%         
%       cam_to_point_vecs = vertices*scale - repmat(cam_pos', size(vertices,1),1);
%       vertex_dists = (cam_to_point_vecs * cam_dir)';
%       
%       %good_pixel_pos = pixel_pos(find(pixels_in_face), :);
%       %if(isempty(good_pixel_pos))
%       %  continue;
%       %end
% 
%       %mesh_depth_img(sub2ind(good_pixel_pos,2)) = vertex_dists(1); 
%       mesh_depth_img(sub2ind(size(mesh_depth_img), image_locs(2,:), image_locs(1,:))) = vertex_dists(1); 
%  
%       sr = min(image_locs(2,:));
%       er = max(image_locs(2,:));
%       sc = min(image_locs(1,:));
%       ec = max(image_locs(1,:));
%       
%       
%       %temp_img(sr:er,sc:ec) = mean(vertex_dists);
%       %occ_mask = mesh_depth_img < temp_img;
%       mesh_depth_img(sr:er,sc:ec) = mean(vertex_dists);
%       %mesh_depth_img = mesh_depth_img + (double(~occ_mask) .* temp_img);
%       %temp_img(sr:er,sc:ec) = 0;
%     end 
% 
% 
% 
% 
%     imagesc(mesh_depth_img);
% 
%     assert(0);






    %% get point clouds from depth image
   
    %col_pos = [300,300, 1000, 1500, 1500];% repmat([1:1920], 1080,1);
    %row_pos = [200, 800, 500, 200, 800]; % repmat([1:1080]', 1, 1920);
    col_pos = repmat([1:1920], 1080,1);
    row_pos = repmat([1:1080]', 1, 1920);
    pixel_pos = zeros(1080,1920,2);
    pixel_pos(:,:,1) = row_pos;
    pixel_pos(:,:,2) = col_pos;
   % pixel_pos(1:5,1,1) = row_pos;
    %pixel_pos(1:5,1,2) = col_pos;
    

    %depth_vals = double(reshape(depth_imgs{jl}, 1080*1920,1));
    depth_vals = double(reshape(depth_img, 1080*1920,1));
    pixel_pos = reshape(pixel_pos, 1080*1920,2);

    %remove bad depth values
    bad_inds = find(depth_vals == 0);
    bi2 = find(depth_vals > max_valid_depth);
    bad_inds = [bad_inds; bi2];
    depth_vals(bad_inds) = [];
    pixel_pos(bad_inds, :) = []; 
    %world_coords = zeros(size(depth_vals));

    v = pixel_pos(:,1);
    u = pixel_pos(:,2);
    xx = (u - cx)/fx;
    yy = (v - cy)/fy;
    
    
    bad_inds = find(abs(xx) > 1);
    depth_vals(bad_inds) = [];
    xx(bad_inds) = [];
    yy(bad_inds) = [];
    bad_inds = find(abs(yy) > 1);
    depth_vals(bad_inds) = [];
    xx(bad_inds) = [];
    yy(bad_inds) = [];
    
    
    
    a = a_map(floor(xx*index_map_mult + index_map_add));
    b = b_map(floor(yy*index_map_mult + index_map_add));
    xc3 = depth_vals / scale;
    %xc3 = depth_vals /389;
    xc1 = a' .* xc3;
    xc2 = b' .* xc3;
    cam_coords = [xc1 xc2 xc3]; 
    world_coords = R' * (cam_coords' - repmat(t, 1, length(cam_coords)));
    world_coords = world_coords';



    %get centroid of the current point cloud
    centroid = median(world_coords);
    %centroid = centroid([1 3]) ./ 389;
    centroid = centroid([1 3]);
    
    




    %% find images that see the same area approximately
    cam_poses = [image_structs.world_pos];    
    cam_dirs = [image_structs.direction];
    cam_poses = cam_poses([1 3], :); %reduce to 2d
    cam_dir_points = cam_dirs([1 3], :) + cam_poses;

    %get equations of lines
    slopes = (cam_poses(2,:) - cam_dir_points(2,:)) ./ (cam_poses(1,:) - cam_dir_points(1,:));
    intercepts = cam_poses(2,:) - slopes.*cam_poses(1,:);

    cur_pos = cur_image_struct.world_pos;
    cur_dir = cur_image_struct.direction;
    cur_pos = cur_pos([1 3]);
    cur_dir = cur_dir([1 3]) + cur_pos;
    

    cur_slope = (cur_pos(2) - cur_dir(2)) / (cur_pos(1) - cur_dir(1));
    cur_intercept = cur_pos(2) - cur_slope*cur_pos(1);


    x_intersections = (intercepts - cur_intercept) ./ (cur_slope - slopes);
    y_intersections = cur_slope.*x_intersections + cur_intercept;
    
    

    if(cur_dir(1) > cur_pos(1))
      good_inds = find(x_intersections > cur_pos(1));
    else
      good_inds = find(x_intersections < cur_pos(1));
    end

    
    
    %the intersection should be on the same side of the camera point as the
    %direction point. 
    inter_diffs = x_intersections - cam_poses(1,:);
    dir_diffs = cam_dir_points(1,:) - cam_poses(1,:);
    diff_flags = inter_diffs .* dir_diffs;
    good_inds2 = find(diff_flags > 0);
    
    good_inter_inds = intersect(good_inds, good_inds2);
    
    
    %only keep cameras with viewing angle < 90 different from reference cam
    sideAs = pdist2(cur_pos', cam_poses');
    sideBs = pdist2(cur_pos', [x_intersections; y_intersections]');
    sideCs = diag(pdist2(cam_poses', [x_intersections; y_intersections]'))';
    
    [angles, ~,~] = get_triangle_angles_from_sides(sideAs, sideBs, sideCs);
    %good_inds3 = find(angles < 90);
    good_inter_angle_inds = find(angles < 120);
%     good_angle_inds1 = find((angles <= 30));
%     good_angle_inds2 = find((angles > 30) & (angles <= 60));
%     good_angle_inds3 = find((angles > 60) & (angles <= 90));
%     
%     useful_struct1 = image_structs(intersect(good_inter_inds, good_angles_inds1));
%     useful_struct2 = image_structs(intersect(good_inter_inds, good_angles_inds2));
%     useful_struct3 = image_structs(intersect(good_inter_inds, good_angles_inds3));
    
    good_inds = intersect(good_inter_inds, good_inter_angle_inds);
    
    sideAs = pdist2(centroid, cam_dir_points');
    sideBs = pdist2(centroid, cam_poses');
    sideCs = diag(pdist2(cam_poses', cam_dir_points'))';
    
    [angles, ~,~] = get_triangle_angles_from_sides(sideAs, sideBs, sideCs);
    %good_centroid_inds = find(angles < 90);
    
    %good_angle_inds1 = find((angles <= 30));
    %good_angle_inds2 = find((angles > 30) & (angles <= 60));
    %good_angle_inds3 = find((angles > 60) & (angles <= 90));
    good_angle_inds1 = find((angles <= 30));
    good_angle_inds2 = find((angles > 30) & (angles <= 75));
    good_angle_inds3 = find((angles > 75) & (angles <= 120));
    useful_struct1 = image_structs(intersect(good_inds, good_angle_inds1));
    useful_struct2 = image_structs(intersect(good_inds, good_angle_inds2));
    useful_struct3 = image_structs(intersect(good_inds, good_angle_inds3));    
    rands1 = randperm(length(useful_struct1));
    rands2 = randperm(length(useful_struct2));
    rands3 = randperm(length(useful_struct3));
    num = ceil(num_pcs_to_use/3);
    num1 = min(num, length(useful_struct1));
    num2 = min(num, length(useful_struct2));
    num3 = min(num, length(useful_struct3));
    useful_structs = [useful_struct1(rands1(1:num1)) useful_struct2(rands2(1:num2)) useful_struct3(rands3(1:num3))];
    rands = 1:length(useful_structs);
    %good_inds = intersect(good_inds, good_centroid_inds);
    
    %useful_structs = image_structs(good_inds);
    
    %useful_structs = image_structs(intersect(intersect(intersect(good_inds, good_inds2), ...
    %                                    good_inds3),good_inds4));



    %pick random subset of the useful structs
    %rands = randperm(length(useful_structs));
    %rands = rands(1:num_pcs_to_use);
    
    %kl_index = rands(1);
    %kl_image_struct = useful_structs(kl_index);
    %kl_image_name = kl_image_struct.image_name;

    %kl_pc = pcread(fullfile(meta_path, 'point_clouds', strcat(kl_image_name(1:10), '.ply')));
      
    %global_pc = pointCloud(kl_pc.Location);
    global_locs = zeros(50000000,3);
    global_locs_counter = 1;
    for kl=1:length(rands)
      kl_index = rands(kl);
      kl_image_struct = useful_structs(kl_index);
      kl_image_name = kl_image_struct.image_name;
      R = kl_image_struct.R;
      t = kl_image_struct.t; 
      %kl_pc = pcread(fullfile(meta_path, 'point_clouds', strcat(kl_image_name(1:10), '.ply')));


      depth_img = depth_img_map(kl_image_name);

      %% get point clouds from depth image
     
      col_pos = repmat([1:1920], 1080,1);
      row_pos = repmat([1:1080]', 1, 1920);
      pixel_pos = zeros(1080,1920,2);
      pixel_pos(:,:,1) = row_pos;
      pixel_pos(:,:,2) = col_pos;
      

      %depth_vals = double(reshape(depth_imgs{jl}, 1080*1920,1));
      depth_vals = double(reshape(depth_img, 1080*1920,1));
      pixel_pos = reshape(pixel_pos, 1080*1920,2);

      %remove bad depth values
      bi1 = find(depth_vals == 0);
      bi2 = find(depth_vals > max_valid_depth);
      bad_inds = [bi1; bi2];
      depth_vals(bad_inds) = [];
      pixel_pos(bad_inds, :) = []; 
      %world_coords = zeros(size(depth_vals));

      v = pixel_pos(:,1);
      u = pixel_pos(:,2);
      xx = (u - cx)/fx;
      yy = (v - cy)/fy;
      
      
      bad_inds = find(abs(xx) > 1);
      depth_vals(bad_inds) = [];
      xx(bad_inds) = [];
      yy(bad_inds) = [];
      bad_inds = find(abs(yy) > 1);
      depth_vals(bad_inds) = [];
      xx(bad_inds) = [];
      yy(bad_inds) = [];
      
      
      
      a = a_map(floor(xx*index_map_mult + index_map_add));
      b = b_map(floor(yy*index_map_mult + index_map_add));
      xc3 = depth_vals / scale;
      %xc3 = depth_vals /389;
      xc1 = a' .* xc3;
      xc2 = b' .* xc3;
      cam_coords = [xc1 xc2 xc3]; 
      world_coords = R' * (cam_coords' - repmat(t, 1, length(cam_coords)));
      world_coords = world_coords';



      start_ind = global_locs_counter;
      end_ind = start_ind + size(world_coords,1) -1;
      global_locs(start_ind:end_ind,:) = world_coords;
      global_locs_counter = end_ind +1;
      %comb_locs = [global_pc.Location; kl_pc.Location];  
      %global_pc = pointCloud(comb_locs);
      %global_pc = pcdownsample(global_pc, 'gridAverage', similar_point_dist_thresh);

      
      
    end%for kl, each chosen point cloud

    %global_pc = pcdownsample(global_pc, 'gridAverage', similar_point_dist_thresh);
    
    global_locs(global_locs_counter:end,:) = [];
    
    %global_locs = global_pc.Location;
    %global_locs = comb_locs;
    global_homog_points = [global_locs'; ones(1,length(global_locs))];
    

    %% make the pc depth image  
    R = cur_image_struct.R;
    t = cur_image_struct.t;
    %cam_pos = cur_image_struct.world_pos * 389;
    cam_pos = cur_image_struct.world_pos * scale;
    cam_dir = cur_image_struct.direction;
    
    assert(abs(norm(cam_dir) - 1) < .0001);
    

    P = [R t];
    oriented_points = P * global_homog_points;

    global_zs = oriented_points(3,:);
    global_bad_inds = find(global_zs < 0);
    global_locs(global_bad_inds,:) = [];

    %global_distorted_points = project_points_to_image(global_locs, K, R, t, distortion);
    XC = R* global_locs' + repmat(t,1,size(global_locs',2));
    a = XC(1,:) ./ XC(3,:);
    b = XC(2,:) ./ XC(3,:);


    r = sqrt( (a).^2 + (b).^2);
    theta = atan(r);

    thetad = theta .* (1 + k1*(theta.^2) + k2*(theta.^4) + k3*(theta.^6) + k4*(theta.^8));

    xx = (thetad./r) .* a;
    yy = (thetad./r) .* b;


    u = fx*(xx + 0*yy) + cx; 
    v = fy*yy + cy; 


    global_distorted_points = round([u;v]);

    
    
    
    

    %% remove points outside image
    bad_inds=find(global_distorted_points(1,:)<1 | global_distorted_points(1,:)>kImageWidth);
    global_distorted_points(:, bad_inds) = [];
    global_locs(bad_inds,:) = [];
    
    %check y values
    bad_inds=find(global_distorted_points(2,:)<1 | global_distorted_points(2,:)>kImageHeight);
    global_distorted_points(:, bad_inds) = [];
    global_locs(bad_inds,:) = [];


    %create vector from camera center to each point
    %cam_to_point_vecs = global_locs*389 - repmat(cam_pos', size(global_locs,1),1);
    cam_to_point_vecs = global_locs*scale - repmat(cam_pos', size(global_locs,1),1);
    global_dists = (cam_to_point_vecs * cam_dir)';
    
    

    %get distance from camera to each point
    %global_dists = pdist2(cam_pos', cur_global_locs*389);

    %sort the global points based on their distsance to the camera
%     global_locs_and_dists = [global_locs'; global_dists];
%     [sorted_locs_and_dists, index] = sortrows(global_locs_and_dists',4);
%     
%     sorted_locs_and_dists = sorted_locs_and_dists';
%     sorted_global_locs = sorted_locs_and_dists(1:3, :);
%     sorted_global_dists = sorted_locs_and_dists(4,:);
%     sorted_global_distorted_points = global_distorted_points(:, index);
%     
%     %keep only the closest point for each pixel. If two global points projected 
%     %to the same pixel, keep only the point closest to the camera
%     [unique_global_distorted_points, IA, IC] = ...
%                            unique(sorted_global_distorted_points', 'rows', 'stable');
% 
%     unique_global_distorted_points = unique_global_distorted_points';
%     %unique_global_locs = sorted_global_locs(:, IA);
%     unique_global_dists = sorted_global_dists(:,IA);
% 
%     pc_depth_img = zeros(kImageHeight, kImageWidth);
%     pc_inds = sub2ind(size(pc_depth_img), unique_global_distorted_points(2,:), ...
%                                           unique_global_distorted_points(1,:)); 
%     pc_depth_img(pc_inds)  = double(unique_global_dists);


   
    [sorted_global_dists, index] = sort(global_dists, 'descend');
    sorted_global_distorted_points = global_distorted_points(:, index);
    
    %now make a depth image 
    pc_depth_img = zeros(kImageHeight, kImageWidth);
    pc_inds = sub2ind(size(pc_depth_img), sorted_global_distorted_points(2,:), ...
                                          sorted_global_distorted_points(1,:)); 
    pc_depth_img(pc_inds)  = double(sorted_global_dists);

    
    
    
    
    
    
    
    slice_img = zeros(size(pc_depth_img));

    for kl=1:length(slice_dists)
      kl_dist = slice_dists(kl);

      temp_img = pc_depth_img;
      temp_img(temp_img > kl_dist) = 0;
      %temp_mask = temp_img == 0;
      temp_mask = slice_img == 0;
      %temp_img = temp_img + (temp_mask .* slice_img);   
      temp_img = (temp_img.*temp_mask) + slice_img; 
 
      cul = imfilter(temp_img,ul_fil);
      cur = imfilter(temp_img,ur_fil);
      cdl = imfilter(temp_img,dl_fil);
      cdr = imfilter(temp_img,dr_fil);


      to_interp = (((cul>0) + (cdr>0)) >1) | (((cdl>0) +(cur>0)) > 1);
      to_interp = to_interp & (temp_img == 0);

      slice_img = regionfill(temp_img, to_interp);
      
      a = slice_img .* to_interp;
      b = a-to_interp;
      to_interp2 = b == -1;
      
      num_zeros = imfilter(double(slice_img==0), count_fil);
      avg_with_zeros = imfilter(slice_img, mean_fil);
      
      avg = (avg_with_zeros*(s^2)) ./ ((s^2)-num_zeros);
      avg(isnan(avg)) = 0;
      avg = avg.*to_interp2;
      slice_img = slice_img + avg;
      

    end%for kl
  
%    pc_depth_org1 = pc_depth_img; 
    slice_mask = slice_img == 0;
    pc_depth_img = (pc_depth_img .* slice_mask) + slice_img;
    
%        slice_img = zeros(size(pc_depth_img));
%
%    for kl=1:length(slice_dists)
%      kl_dist = slice_dists(kl);
%
%      temp_img = pc_depth_img;
%      temp_img(temp_img > kl_dist) = 0;
%      temp_mask = temp_img == 0;
%      temp_img = temp_img + (temp_mask .* slice_img);     
% 
%      cul = imfilter(temp_img,ul_fil);
%      cur = imfilter(temp_img,ur_fil);
%      cdl = imfilter(temp_img,dl_fil);
%      cdr = imfilter(temp_img,dr_fil);
%
%
%      to_interp = (((cul>0) + (cdr>0)) >1) | (((cdl>0) +(cur>0)) > 1);
%      to_interp = to_interp & (temp_img == 0);
%
%      slice_img = regionfill(temp_img, to_interp);
%
%    end%for kl
  
%    pc_depth_org = pc_depth_img; 
%    slice_mask = slice_img == 0;
%    pc_depth_img = (pc_depth_img .* slice_mask) + slice_img;


    depth_img = cur_depth_img;

    %% TODO  - keep depth image values that are less than point cloud values
      %good_depth_flags = (depth_img>0) & ((depth_img<pc_depth_img) | (depth_img<2000));
      good_depth_flags = (depth_img>0) & (depth_img<pc_depth_img);
      thresh_depth = double(depth_img) .* double(good_depth_flags);
      thresh_pc_depth = pc_depth_img .* double(~good_depth_flags);
      new_depth = uint16(thresh_depth + thresh_pc_depth);
      new_depth = regionfill(new_depth, (new_depth == 0));
%    if(1)
%      good_depth_flags = (depth_img > 0) & (depth_img<4500);
%      thresh_depth = double(depth_img) .* double(good_depth_flags);
%      thresh_pc_depth = pc_depth_img .* double(~good_depth_flags);
%      new_depth = uint16(thresh_depth + thresh_pc_depth);
%    else
%      good_pc_depth_flags = (pc_depth_img > 0);
%      thresh_pc_depth = double(pc_depth_img) .* double(good_pc_depth_flags);
%      thresh_depth = double(depth_img) .* double(~good_pc_depth_flags);
%      new_depth = uint16(thresh_depth + thresh_pc_depth);
%    end


    imwrite(new_depth, fullfile(meta_path, 'improved_depths', ...
              strcat(cur_image_name(1:8), '05.png')));
  end%for jl, each image name

end%for i, each scene_name


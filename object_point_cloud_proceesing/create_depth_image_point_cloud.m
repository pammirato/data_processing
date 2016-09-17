%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object

%TODO -get rid of image structs map. Just use indexes. (Make it sorted?)


clearvars;

%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

scene_name = 'Den_den4'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


label_to_process = 'all'; %make 'all' for every label
label_names = {label_to_process};



do_occlusion_filtering = 1;
occlusion_threshold = 100;  %make > 12000 to remove occlusion thresholding 

use_global_pc = 0;
use_color_check = 1;


count = 0;

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

  %get the names of all the labels
  if(strcmp(label_to_process, 'all'))
    label_names = get_names_of_X_for_scene(scene_name, 'instance_labels');
  end




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


  %get mapping from disorted pixel coords to undistorted pixel coords
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


  %% make struct for holding the labels (bounding boxes) for each label in each image

  %make a blank struct with an empty box for each label
  %the field is the label name, the value for that field is the box
  blank_struct = struct();
  blank_struct.image_name = '';
  for jl=1:length(label_names)
    blank_struct.(label_names{jl}) = []; 
  end

  %make a struct array of the empty label struct made above. One struct per image in this scene
  label_structs = repmat(blank_struct, length(image_structs), 1);



  ref_struct = image_structs_map(image_names{1});
  ref_dir = ref_struct.direction; 
  ref_dir = ref_dir([1 3]);

  image_names = {'0000300101.png', '0000750101.png'};
  %image_names = {'0009640101.png'};
  %image_names = image_names(1:20);
  %all_pcs = cell(1,length(image_names));

  %image_names = image_names(1:2);
  for jl= 1:length(image_names) 

    
    %% get the image name, position/direction info 
    cur_image_name = image_names{jl};
    %cur_image_name = '0001050101.png';
    cur_image_struct = image_structs_map(cur_image_name);



    disp(cur_image_name);
    %just to see how much progress is being made
    %if(mod(jl,50) == 0)
    %  disp(cur_image_name);
    %end

    R = cur_image_struct.R;
    t = cur_image_struct.t;
    %camera_pos = cur_image_struct.world_pos;
    %scaled_camera_pos = cur_image_struct.scaled_world_pos;

    %M = K * [R t];
    %MI = pinv(M);
    
    %rgb_img = rgb_images{jl};
    %depth_image = depth_images{jl};%reshape(depth_images{jl}, 1080*1920,1);
    rgb_img = imread(fullfile(scene_path, 'rgb',cur_image_name)); 
    depth_image = imread(fullfile(scene_path, 'high_res_depth', ...
                            strcat(cur_image_name(1:8), '03.png')));


    col_pos = repmat([1:1920], 1080,1);
    row_pos = repmat([1:1080]', 1, 1920);
    pixel_pos = zeros(1080,1920,2);
    pixel_pos(:,:,1) = row_pos;
    pixel_pos(:,:,2) = col_pos;
    

    %depth_vals = double(reshape(depth_images{jl}, 1080*1920,1));
    depth_vals = double(reshape(depth_image, 1080*1920,1));
    rgb_vals = reshape(rgb_img, 1080*1920,3);
    pixel_pos = reshape(pixel_pos, 1080*1920,2);

    %remove bad depth values
    bad_inds = find(depth_vals == 0);
    bi2 = find(depth_vals > 4500);
    bad_inds = [bad_inds; bi2];
    depth_vals(bad_inds) = [];
    rgb_vals(bad_inds, :) = []; 
    pixel_pos(bad_inds, :) = []; 
    world_coords = zeros(size(rgb_vals));

    v = pixel_pos(:,1);
    u = pixel_pos(:,2);
    xx = (u - cx)/fx;
    yy = (v - cy)/fy;
    
    
    bad_inds = find(abs(xx) > 1);
    depth_vals(bad_inds) = [];
    rgb_vals(bad_inds, :) = []; 
    xx(bad_inds) = [];
    yy(bad_inds) = [];
    bad_inds = find(abs(yy) > 1);
    depth_vals(bad_inds) = [];
    rgb_vals(bad_inds, :) = []; 
    xx(bad_inds) = [];
    yy(bad_inds) = [];
    
    
    
    a = a_map(floor(xx*index_map_mult + index_map_add));
    b = b_map(floor(yy*index_map_mult + index_map_add));
    xc3 = depth_vals / scale;
    %xc3 = depth_vals /389;
    xc1 = a' .* xc3;
    xc2 = b' .* xc3;
    %xc1 = xx .* xc3;
    %xc2 = yy .* xc3;
    cam_coords = [xc1 xc2 xc3]; 
    world_coords = R' * (cam_coords' - repmat(t, 1, length(cam_coords)));
    world_coords = world_coords';

    cur_pc = pointCloud(world_coords, 'Color',rgb_vals );
    
    pcwrite(cur_pc, fullfile(meta_path, 'point_clouds', strcat(cur_image_name(1:10), '.ply')));
    
    breakp = 1;
  end%for jl, each image name
end%for i, each scene_name


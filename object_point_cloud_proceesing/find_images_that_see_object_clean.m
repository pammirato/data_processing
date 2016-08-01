%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object


%clearvars;

%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

scene_name = 'Kitchen_Living_03_1'; %make this = 'all' to run all scenes
group_name = 'all_minus_boring';
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


label_to_process = 'chair3'; %make 'all' for every label
label_names = {label_to_process};



do_occlusion_filtering = 1;
occlusion_threshold = 200;  %make > 12000 to remove occlusion thresholding 

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

for i=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{i};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %get the names of all the labels
  if(strcmp(label_to_process, 'all'))
    label_names = get_names_of_X_for_scene(scene_name, 'instance_labels');
  end




  % get camera info
  fid_camera =  fopen(fullfile(meta_path,'reconstruction_results', group_name, ...
                                'colmap_results', model_number,'cameras.txt'));

  %skip the file header
  line = fgetl(fid_camera);
  line = fgetl(fid_camera);
  line = fgetl(fid_camera);
  line = fgetl(fid_camera);

  %split the line with the camera parameters
  line = strsplit(line);

  K = zeros(3); %camera intrinsic matrix
  distortion = zeros(1,4);%distortion parameters

  K(1,1) = str2double(line{5});
  K(1,3) = str2double(line{7});
  K(2,2) = str2double(line{6});
  K(2,3) = str2double(line{8});
  K(3,3) = 1;

  distortion(1) = str2double(line{9});
  distortion(2) = str2double(line{10});
  distortion(3) = str2double(line{11});
  distortion(4) = str2double(line{12});


  fclose(fid_camera);


  %get info about camera position for each image
  %image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', group_name, ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;



  blank_struct = struct();
  blank_struct.image_name = '';
  for jl=1:length(label_names)
    blank_struct.(label_names{jl}) = []; 
  end


  label_structs = repmat(blank_struct, length(image_structs), 1);


  %get a list of all the image file names
  %temp = cell2mat(image_structs);
  %image_names = {temp.(IMAGE_NAME)};
  image_names = {image_structs.(IMAGE_NAME)};

  %make a map from image name to image_struct
  %image_structs_map = containers.Map(image_names, image_structs);


  image_structs_map = containers.Map(image_names,...
                                 cell(1,length(image_names)));

  for jl=1:length(image_names)
    image_structs_map(image_names{jl}) = image_structs(jl);
  end

  %get camera parameters for each kinect
  %[intrinsic, distortion, rotation, projection] = get_kinect_parameters(kinect_to_use);    


  %this will store the final  result
  pclabel_to_images_that_see_it_map = containers.Map();




  if(do_occlusion_filtering)
    %prompt user to load all the depth images for this scene ahead of time
    %(a good idea if they have not been loaded and more than one instance is to be processed) 
    load_depths = input('Load all depths?(y/n)' , 's');

    %whether the depths get loaded or not
    depths_loaded = 0;

    %load all the depths
    if((load_depths=='y'))

      %get names of all the rgb images in the scene
      %image_names = get_names_of_X_for_scene(scene_name,'rgb_images');

      %will hold all the depth images
      depth_images = cell(1,length(image_names));

      %for each rgb image, load a depth image
      for j=1:length(image_names)
          rgb_name = image_names{j};

          depth_images{j} = imread(fullfile(scene_path, 'filled_high_res_depth', ... 
                   strcat(rgb_name(1:8),'04.png') ));
          %depth_images{j} = imread(fullfile(scene_path, 'high_res_depth', ... 
          %         strcat(rgb_name(1:8),'03.png') ));
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
  end%if do_occlusion_filtering



  %load the full point cloud for the entire scene
  global_pc = pcread(fullfile(meta_path,'reconstruction_results', group_name, ...
                       'undistorted_images','pmvs', 'annotated_models','merged_mesh.ply'));


  %% MAIN LOOP

  %for each point cloud
  for jl=1:length(label_names)
    

    cur_label_name = label_names{jl};
    
%     if(~strcmp(cur_label_name, 'honey_bunches_of_oats_with_almonds'))
%       continue;
%     end

    disp(cur_label_name);

    %cur_pc = pcread(fullfile(meta_path, LABELING_DIR, OBJECT_POINT_CLOUDS, ...
    %                   ORIGINAL_POINT_CLOUDS, strcat(cur_label_name, '.ply')));
    cur_pc = pcread(fullfile(meta_path,'labels', ...
                       'object_point_clouds', strcat(cur_label_name, '.ply')));
 
   
    cur_world_locs = cur_pc.Location;
    cur_color = cur_pc.Color;
%    cur_world_locs = cur_world_locs / scale;
%    scale = 1 ;
    %cur_world_locs = cur_world_locs * scale; 


    found_image_names = cell(1,length(image_names));

    %for each image, determine if it 'sees' this object(point cloud) 
    for kl = 1:length(image_names) 


    


      cur_image_name = image_names{kl};
      cur_image_struct = image_structs_map(cur_image_name);
      cur_world_locs = cur_pc.Location;
      cur_color = cur_pc.Color;
      
      if(strcmp(cur_image_name, '0000110101.png'))
        breakp=1;
      end
    
      global_world_locs = global_pc.Location;
      global_color = global_pc.Color;

  
%        if(strcmp(cur_label_name, 'honey_bunches_of_oats_with_almonds') && ...
%           strcmp(cur_image_name, '0000350101.png'))
%         breakp =1;
%       end

      %all the points from the points cloud, in homogenous coordinates
      cur_homog_points = [cur_world_locs ones(length(cur_world_locs), 1)]';

    
      global_homog_points = [global_world_locs, ones(length(global_world_locs),1)]';
 
      %get parameters for this image 
      %K = intrinsic; 
      %K = [1049.52, 0, 927.269; 0, 1050.65, 545.76; 0 0 1]; 
      R = cur_image_struct.(ROTATION_MATRIX);
      t = cur_image_struct.(TRANSLATION_VECTOR);


      %re-orient the point to see if it is viewable by this camera
      P = [R t];
      oriented_points = P * cur_homog_points;

      global_oriented_points = P * global_homog_points;


      %make sure z is positive, if it is negative the point is 'behind' the image
      all_zs = oriented_points(3, :);
      bad_inds = find(all_zs < 0);%find the z values that are negative
      cur_homog_points(:, bad_inds) = []; %remove those points
    
      cur_world_locs(bad_inds, :) = [];
      cur_color(bad_inds, :) = [];

      global_zs = global_oriented_points(3,:);
      global_bad_inds = find(global_zs < 0);
      global_homog_points(:,global_bad_inds) = [];
      global_world_locs(global_bad_inds,:) = [];
      global_color(global_bad_inds,:) = [];

      if(isempty(cur_homog_points))
        %fprintf('Empty orientation, %s\n', cur_image_name);
        %count = count+1;
        continue;
      end

      %not sure about what is happening herer
      if(length(cur_homog_points) ~= length(oriented_points))
        %fprintf('Not all points oriented???? %s\n', cur_image_name);
      end


      %project the world point onto this image
      %M = K * [R t];
      %cur_image_points = M * cur_homog_points;

      %%acccount for homogenous coords
      %cur_image_points = cur_image_points ./ repmat(cur_image_points(3,:),3,1);
      %cur_image_points = cur_image_points([1,2], :);
      %cur_image_points =floor(cur_image_points);





      %k1 = .381593;
      %k2 = .1077399;
      %k3 = 0;
      %p1 = .00280506;
      %p2 = -0.00120267;

      k1 = distortion(1);
      k2 = distortion(2);
      p1 = distortion(3);
      p2 = distortion(4);

      %fx = 1049.04;
      fx = K(1,1);
      %fy = 1066.29;
      fy = K(2,2);
      %cx = 927.269;
      cx = K(1,3);
      %cy = 545.76;
      cy = K(2,3);


      %distort point cloud points
    
      %new disotortion model
      % http://docs.opencv.org/master/db/d58/group__calib3d__fisheye.html#gsc.tab=0 
   
     % a = cur_image_points(1,:);
     % b = cur_image_points(2,:);
      XC = R* cur_world_locs' + repmat(t,1,size(cur_world_locs',2));
      a = XC(1,:) ./ XC(3,:);
      b = XC(2,:) ./ XC(3,:);
      

      r = sqrt( (a).^2 + (b).^2);
      theta = atan(r);

      thetad = theta .* (1 + k1*(theta.^2) + k2*(theta.^4) + p1*(theta.^6) + p2*(theta.^8));

      xx = (thetad./r) .* a;
      yy = (thetad./r) .* b;


      u = fx*(xx + 0*yy) + cx;
      v = fy*yy + cy;


      distorted_points = round([u;v]);
      scaled_world_locs = cur_world_locs'*scale;


      bad_inds =  find(distorted_points(1,:) < 1 | distorted_points(1,:) > kImageWidth);
      distorted_points(:, bad_inds) = [];
      cur_world_locs(bad_inds,:) = [];
      scaled_world_locs(:, bad_inds) = [];
      cur_color(bad_inds, :) = [];
      %check y values
      bad_inds =  find(distorted_points(2,:) < 1 | distorted_points(2,:) > kImageHeight);
      distorted_points(:, bad_inds) = [];
      cur_world_locs(bad_inds,:) = [];
      scaled_world_locs(:, bad_inds) = [];
      cur_color(bad_inds, :) = [];



      %%  GLOBAL COPIED STUFFFFFFFFFFFFFFFFFf   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      XC = R* global_world_locs' + repmat(t,1,size(global_world_locs',2));
      a = XC(1,:) ./ XC(3,:);
      b = XC(2,:) ./ XC(3,:);
      

      r = sqrt( (a).^2 + (b).^2);
      theta = atan(r);

      thetad = theta .* (1 + k1*(theta.^2) + k2*(theta.^4) + p1*(theta.^6) + p2*(theta.^8));

      xx = (thetad./r) .* a;
      yy = (thetad./r) .* b;


      u = fx*(xx + 0*yy) + cx;
      v = fy*yy + cy;


      global_distorted_points = round([u;v]);
      global_scaled_world_locs = global_world_locs'*scale;


      bad_inds=find(global_distorted_points(1,:)<1 | global_distorted_points(1,:) > kImageWidth);
      global_distorted_points(:, bad_inds) = [];
      global_world_locs(bad_inds,:) = [];
      global_scaled_world_locs(:, bad_inds) = [];
      global_color(bad_inds,:) = [];
      
      %check y values
      bad_inds=find(global_distorted_points(2,:)<1 | global_distorted_points(2,:) > kImageHeight);
      global_distorted_points(:, bad_inds) = [];
      global_world_locs(bad_inds,:) = [];
      global_scaled_world_locs(:, bad_inds) = [];
      global_color(bad_inds,:) = [];


      %%  GLOBAL COPIED STUFFFFFFFFFFFFFFFFFf   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%






      %make sure each point is in the image
      
      %check x values
      %bad_inds =  find(cur_image_points(1,:) < 1 | cur_image_points(1,:) > kImageWidth);
      %cur_image_points(:, bad_inds) = [];
      %%check y values
      %bad_inds =  find(cur_image_points(2,:) < 1 | cur_image_points(2,:) > kImageHeight);
      %cur_image_points(:, bad_inds) = [];

   
      %if(isempty(cur_image_points))
      %  fprintf('All points outside image, %s\n', cur_image_name);
      %  continue;
      %end

      if(isempty(distorted_points))
        %fprintf('All points outside image, %s\n', cur_image_name);
        continue;
      end


      %%OCCULSION FILTERING
      %attempt to filter out images where the labeled instance is occuled
      %at the labeled point. 



      camera_pos = cur_image_struct.(WORLD_POSITION);
      if(size(camera_pos,2) == 1)
        camera_pos = camera_pos';
      end

      global_world_locs = global_world_locs';
      global_dists = pdist2(camera_pos, double(global_world_locs)');
      global_locs_and_dists = [global_world_locs; global_dists];
      [sorted_locs_and_dists, index] = sortrows(global_locs_and_dists',4);
      sorted_locs_and_dists = sorted_locs_and_dists';

      sorted_global_locs = sorted_locs_and_dists(1:3, :);
      sorted_global_dists = sorted_locs_and_dists(4,:);
      sorted_global_distorted_points = global_distorted_points(:, index);
      sorted_global_color = global_color(index,:);
      

      [unique_global_distorted_points, IA, IC] = ...
                             unique(sorted_global_distorted_points', 'rows', 'stable');

      unique_global_distorted_points = unique_global_distorted_points';
      unique_global_locs = sorted_global_locs(:, IA);
      unique_global_dists = sorted_global_dists(:,IA);
      unique_global_color = sorted_global_color(IA,:);


      %now make a 'depth' image 
      pc_depth_img = zeros(kImageHeight, kImageWidth);
      pc_inds = sub2ind(size(pc_depth_img), unique_global_distorted_points(2,:), ...
                                            unique_global_distorted_points(1,:)); 
      pc_depth_img(pc_inds)  = double(unique_global_dists);





      cur_world_locs = cur_world_locs';
      cur_dists = pdist2(camera_pos, double(cur_world_locs)');
      cur_locs_and_dists = [cur_world_locs; cur_dists];
      [sorted_locs_and_dists, index] = sortrows(cur_locs_and_dists',4);
      sorted_locs_and_dists = sorted_locs_and_dists';

      sorted_cur_locs = sorted_locs_and_dists(1:3, :);
      sorted_cur_dists = sorted_locs_and_dists(4,:);
      sorted_cur_distorted_points = distorted_points(:, index);
      sorted_cur_color = cur_color(index,:); 

      [unique_cur_distorted_points, IA, IC] = ...
                             unique(sorted_cur_distorted_points', 'rows', 'stable');

      unique_cur_distorted_points = unique_cur_distorted_points';
      unique_cur_locs = sorted_cur_locs(:, IA);
      unique_cur_dists = sorted_cur_dists(:,IA);


      cur_dists = unique_cur_dists;
      distorted_points = unique_cur_distorted_points;
      cur_world_locs = unique_cur_locs;
      cur_color = sorted_cur_color(IA,:);



      depths = pc_depth_img(sub2ind(size(pc_depth_img), ...
                             distorted_points(2,:), distorted_points(1,:)));
      dist_flags = abs(double(unique_cur_dists) - double(depths)) < .00001;


      good_inds = find(dist_flags == 1);

      %if(length(good_inds)/length(distorted_points) < .25)
      %  continue;
      %end
    
      distorted_points = distorted_points(:,good_inds);
      cur_color = cur_color(good_inds,:);
      cur_world_locs = cur_world_locs(:,good_inds);




    %% NOW CHECK COLOR

     img = imread(fullfile(scene_path, 'rgb', cur_image_name));

     %convert to Lab colorspace
     % cform = makecform('srgb2lab');
     % lab_img =  applycform(im2double(img), cform);

     % lab_points = applycform(double(cur_color), cform);
     % lin_inds = sub2ind(size(lab_img), ...
     %                        distorted_points(2,:), distorted_points(1,:));
     %                      
     % img_l = lab_img(:,:,1);
     % img_a = lab_img(:,:,2);
     % img_b = lab_img(:,:,3);
     %
     % lab_img_points = zeros(length(lab_points),3);
     % lab_img_points(:,1) = img_l(lin_inds);
     % lab_img_points(:,2) = img_a(lin_inds);
     % lab_img_points(:,3) = img_b(lin_inds);

     % lab_dists = diag(pdist2(lab_points,lab_img_points));
     
      lin_inds = sub2ind(size(img), ...
                             distorted_points(2,:), distorted_points(1,:));
     

      img_r = img(:,:,1);
      img_g = img(:,:,2);
      img_b = img(:,:,3);
      rgb_img_points = zeros(size(cur_color,1),3);
      rgb_img_points(:,1) = img_r(lin_inds);
      rgb_img_points(:,2) = img_b(lin_inds);
      rgb_img_points(:,3) = img_b(lin_inds);
     
     
      black_thresholds  = double(cur_color) ./ 2;
      white_thresholds  = double(cur_color) + -.5 * (double(cur_color) - 255);

      black_subs = rgb_img_points - black_thresholds;
      white_subs = white_thresholds - rgb_img_points; 

      black_flags = sum((black_subs > 0), 2);
      white_flags = sum((white_subs > 0), 2); 

      bad_inds = unique([find(black_flags < 2); find(white_flags < 2)]);

      distorted_points(:,bad_inds) = [];
      cur_world_locs(:,bad_inds) = [];
      cur_color(bad_inds,:) = [];      
      rgb_img_points(bad_inds,:) = [];



     
      rgb_dists = diag(pdist2(double(cur_color),double(rgb_img_points)));
     
      good_inds = find(rgb_dists < 50);
      
      
      distorted_points = distorted_points(:,good_inds); 
      cur_world_locs = cur_world_locs(:,good_inds);



      if(isempty(distorted_points))
        continue;
      end



      if(length(distorted_points) < 30)
        disp(['too few points ' , num2str(length(distorted_points))]);
        continue;
      end





      %make sure distance from camera to world_coords is similar to depth of
      %projected point in the depth image

      bad_inds = zeros(1,size(distorted_points,2));
      counter = 1;





      num_points_before_occlusion = length(distorted_points);


      if(do_occlusion_filtering)
        %get the depth image
        if(~depths_loaded)
          %depth_image = imread(fullfile(scene_path, 'filled_high_res_depth', ... 
           %              strcat(cur_image_name(1:8),'04.png') ));
          disp('reading depth image...');
          depth_image = imread(fullfile(scene_path, 'high_res_depth', ... 
                         strcat(cur_image_name(1:8),'03.png') ));
        else
          depth_image = depth_img_map(cur_image_name);
        end


        %depths = diag(depth_image(distorted_points(2,:), distorted_points(1,:))); 
        depths = depth_image(sub2ind(size(depth_image), ...
                               distorted_points(2,:), distorted_points(1,:)));

        zero_inds = find(depths == 0);

        %if(length(zero_inds)/length(depths) > .80)
        %  continue;
        %end 


        %clean_depths = depths;
        %clean_depths(zero_inds) = [];

        camera_pos = cur_image_struct.(SCALED_WORLD_POSITION);
        if(size(camera_pos,2) == 1)
          camera_pos = camera_pos';
        end

        scaled_world_locs = cur_world_locs.*scale;
        
        world_dists = pdist2(camera_pos, double(scaled_world_locs)');

        %world_dists(zero_inds)= [];

        %good_dists = abs(double(world_dists) - double(clean_depths)) < occlusion_threshold;
        %dist_flags = abs(double(world_dists) - double(depths)) < occlusion_threshold;
        %only remove point if depth is less than distance, to be robuts to
        %depth noise
        dist_flags = double(world_dists) - double(depths) < occlusion_threshold;

        good_inds = find(dist_flags == 1);
        
        depth_flags = dist_flags | (depths == 0);
        
        bad_inds = find(depth_flags == 0);
        

        %if(length(good_inds)/length(distorted_points) < .25)
        %  continue;
        %end
      
        %distorted_points = distorted_points(:,good_inds);
        distorted_points(:,bad_inds) = [];

       % for ll=1:size(distorted_points,2)
       %   cur_point = distorted_points(:,ll);

       %   %get the depth of the projected point
       %   cur_depth =double(depth_image(floor(cur_point(2)), floor(cur_point(1))));

       %   %get the distance from the camera to the labeled point in 3D
       %   camera_pos = cur_image_struct.(SCALED_WORLD_POSITION);
       %   world_dist = pdist2(camera_pos', double(scaled_world_locs(:,ll)'));



       %   %if the depth == 0, then keep this image as we can't tell
       %   %otherwise see if the difference in depth vs. distance is greater than the threshold
       %   if(cur_depth<world_dist && ...
       %           abs(world_dist - cur_depth) > occlusion_threshold  && cur_depth >0)
       %   %if(cur_depth<world_dist && ...
       %   %        abs(world_dist - cur_depth) > occlusion_threshold  || cur_depth >0)
       %     %continue
       %     bad_inds(counter) =ll;
       %     counter = counter +1;
       %   end
       % end%for ll, each distorted point

       % bad_inds(counter:end) = [];

       % distorted_points(:,bad_inds) = [];
     end%if do occlusion


    %num_points_after_occlusion = length(distorted_points);






    %% JUST FOR RIC

     %if(num_points_after_occlusion < .90*num_points_before_occlusion)
     %  fprintf(' ccluded: %s\n', cur_image_name);
     %  continue;
     %end

    
     %num_points_seen = length(distorted_points);
     %num_total_points = length(cur_world_locs);

    
     % if(num_points_seen < .25*num_total_points)
     %   continue;
     % end   



      if(length(distorted_points) < 30)
        disp(['too few points final: ' , num2str(length(distorted_points))]);
        continue;
      end


      found_image_names{kl} = cur_image_name;


      minx = min(distorted_points(1,:));
      miny = min(distorted_points(2,:));
      maxx = max(distorted_points(1,:));
      maxy = max(distorted_points(2,:));
      
      %if(minx == maxx || miny==maxy || minx == 1 && maxy == 1)
      %  fprintf('bad box skip %s\n', cur_image_name);
      %  continue;
      %end

      cur_struct = label_structs(kl); 

      if(~strcmp(cur_struct.image_name, ''))
        assert(strcmp(cur_struct.image_name, cur_image_name));
      else
        cur_struct.image_name = cur_image_name;
      end

      cur_struct.(cur_label_name) = [minx, miny, maxx, maxy];
      
      label_structs(kl) = cur_struct;

      %show some visualization of the found points if debug option is set 
      if(debug)  
        %read in the rgb image
        img = imread(fullfile(scene_path, 'rgb', cur_image_name));
        %img = imread(fullfile(scene_path, 'undistorted_images', '00000187.jpg'));

        %make an image with the object points = 1, everything else =0
        %obj_img = zeros(size(img,1), size(img,2));
        %object_inds = sub2ind(size(obj_img), cur_image_points(2,:), cur_image_points(1,:)); 
        %obj_img(object_inds)  = 1;


        dobj_img = zeros(size(img,1), size(img,2));
        dobject_inds = sub2ind(size(dobj_img), distorted_points(2,:), distorted_points(1,:)); 
        dobj_img(dobject_inds)  = 1;

       % uminx = min(undistorted_points(1,:));
       % uminy = min(undistorted_points(2,:));
       % umaxx = max(undistorted_points(1,:));
       % umaxy = max(undistorted_points(2,:));

        bbox = [minx miny maxx maxy];
       % ubbox = [uminx uminy umaxx umaxy];

        %display the image with the object superimposed
        imshow(img);
        hold on;
        %h = imagesc(uobj_img); %plot object
        %set(h,'AlphaData', .5); %make object transparent
        h = imagesc(dobj_img); %plot object
        set(h,'AlphaData', .5); %make object transparent
        %h = imagesc(obj_img); %plot object
        %set(h,'AlphaData', .5); %make object transparent
       
        %p_x = mean(cur_image_points(1,:));
        %p_y = mean(cur_image_points(2,:)); 
        %plot(p_x, p_y, 'r.', 'MarkerSize', 20);

        %draw bounding box
        %rectangle('Position',[ubbox(1) ubbox(2) (ubbox(3)-ubbox(1)) (ubbox(4)-ubbox(2))], ...
        %             'LineWidth',2, 'EdgeColor','b');
        rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], ...
                     'LineWidth',2, 'EdgeColor','r');
                   
        title(num2str(mean(rgb_dists)));
        hold off;
       
        %title(num2str(max(max(abs(distorted_points - cur_image_points)))));
   
        if(0 && do_occlusion_filtering)
          figure;
          imshow(img);
          hold on;
          h = imagesc(depth_image);
          set(h,'AlphaData',.5);
          hold off;
        end
        %ginput(1);
        
        
        breakp= 1;
        %close all; 
      end % if debug
    end%for k, each image name

    %remove empty values from cell array
    found_image_names  =  found_image_names(~cellfun('isempty', found_image_names));

   end%f r jl, each point cloud 



   for jl=1:length(label_structs)
     cur_struct = label_structs(jl);

     if(strcmp(cur_struct.image_name, ''))
       cur_struct.image_name = image_names{jl};
     end

     cur_image_name = cur_struct.image_name;
     cur_struct = rmfield(cur_struct,'image_name');

     save(fullfile(meta_path, 'labels', 'instance_label_structs', ...
                    strcat(cur_image_name(1:10), '.mat')), '-struct', 'cur_struct'); 

   end%for jl, each label struct

end%for i, each scene_name


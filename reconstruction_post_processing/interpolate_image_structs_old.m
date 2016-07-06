%saves a camera poistions and orientations from text file outputted from reconstruction
%saves a cell array of these 'image structs', and also saves the scale 
%also saves a list of reconstructed 3d points seen by each image


%TODO - better name, processing for points2d

clearvars;

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Bedroom11'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 

cluster_size = 12;%how many images are in each cluster

debug = 0;

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




for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il}
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);



  blank_struct = struct(IMAGE_NAME, '', TRANSLATION_VECTOR, [], ...
                       ROTATION_MATRIX, [], WORLD_POSITION, [], ...
                       DIRECTION, [], QUATERNION, [], ...
                       SCALED_WORLD_POSITION, [0,0,0], IMAGE_ID,'',...
                       CAMERA_ID, '', 'cluster_id', -1, 'rotate_cw', -1, ...
                       'rotate_ccw',-1, 'translate_forward',-1,'translate_backward',-1);



  %save everything
  recon_struct_file = load(fullfile(meta_path,RECONSTRUCTION_DIR,...
                        'reconstructed_image_structs.mat'));
   
  image_structs = recon_struct_file.image_structs;
  scale = recon_struct_file.scale;


  %now make the image structs just for the main rgb images. 
  %Main rgb images are all the images that are given to move around the scene, not the hand
  %scan. Not all of these were reconstructed, so we need to remove the hand scan, and 
  %interpolate to add the not reconstructed main images

  %get how many main rgb images there are
  num_main_rgb_images = length(dir(fullfile(scene_path, 'rgb')));

  %% first remove the hand scan images
  inds_to_remove = []; 
  
  for jl =1:length(image_structs)
 
    cur_image_struct = image_structs(jl);
    cur_image_name = cur_image_struct.image_name; 

    image_index = str2double(cur_image_name(1:6)); 
    
    if(image_index > num_main_rgb_images)
      inds_to_remove(end+1) = jl;
    end
    
  end%for jl, each image struct


  image_structs(inds_to_remove) = [];


  %% now make sure there is an image struct for each image
  image_names_with_struct = {image_structs.image_name};

  name_to_image_struct_map = containers.Map(image_names_with_struct,...
                                 cell(1,length(image_names_with_struct)));

  for jl=1:length(image_names_with_struct)
    name_to_image_struct_map(image_names_with_struct{jl}) = image_structs(jl);
  end
 

  %get the names of all the images, and make a blank struct array for them all 
  temp = dir(fullfile(scene_path, 'rgb', '*.png'));
  all_image_names = {temp.name};
  all_image_structs = repmat(blank_struct, 1, length(all_image_names));


  new_image_structs = repmat(blank_struct, 1, length(all_image_names) - length(image_structs));
  num_made_image_structs = 0;



  
  for jl=1:(length(all_image_names)/cluster_size)

    %store the 3 structs that will define the circle for this cluster 
    counter = 1; 
    %cur_cluster_structs = repmat(blank_struct, 1, cluster_size);
    defining_structs = repmat(blank_struct, 1, 3);%need 3 points to define a circle

    %for each image in the cluster see if it was reconstructed
    for kl=1:cluster_size
      cur_image_name = all_image_names{(jl-1)*cluster_size + kl}; 

      try
        cur_image_struct = name_to_image_struct_map(cur_image_name);
        defining_structs(counter) = cur_image_struct;
        counter = counter +1;
      catch
      end
  
      %once we get 3 image structs, we have enough to define the circle, so stop
      if(counter > 3)
        break;
      end
    end%for kl 
  

    %%  get radius and center of circle defined by the three points

    p1 =  defining_structs(1).world_pos;
    p1 =  p1([1 3]);
    p2 =  defining_structs(2).world_pos;
    p2 =  p2([1 3]);
    p3 =  defining_structs(3).world_pos;
    p3 =  p3([1 3]);


    %following this tutorial to get center and radius of circle from 3 points
    %http://www.regentsprep.org/regents/math/geometry/gcg6/RCir.htm
    mr = (p2(2) - p1(2)) / (p2(1) - p1(1));
    mt = (p3(2) - p2(2)) / (p3(1) - p2(1));


    center_x = mr*mt*(p3(2)-p1(2)) + mr*(p2(1)+p3(1)) - mt*(p1(1)+p2(1));
    center_x = center_x / (2*(mr-mt));

    center_y = -1/mr * (center_x - ((p1(1)+p2(1))/2)) + ((p1(2)+p2(2))/2);

    radius = sqrt((center_x - p1(1))^2 + (center_y - p1(2))^2);
 
    if(debug)

      plot(p1(1), p1(2), 'r.');
      hold on;
      plot(p2(1), p2(2), 'r.');
      plot(p3(1), p3(2), 'r.');

      plot(center_x, center_y, 'b.');
      axis equal;

      title(num2str(radius));
    end%if debug



    %% now do the interpolation
    ref_struct_name = defining_structs(1).image_name;
    ref_struct_index = str2double(ref_struct_name(1:6));

    p = defining_structs(1).world_pos;
    px = p(1);
    py = p(3);

    cx = center_x;
    cy = center_y;
    syms x y; 


    for kl=1:cluster_size
      cur_image_name = all_image_names{(jl-1)*cluster_size + kl}; 

      %see if this image already has a struct 
      try
        cur_image_struct = name_to_image_struct_map(cur_image_name);
      catch
        %otherwise interplotate to make a new struct
        cur_index = str2double(cur_image_name(1:6));
        assert(cur_index ==  (jl-1)*cluster_size + kl);

        angle = 30*abs(cur_index - ref_struct_index);

        side_length = 2*(radius^2) - 2*(radius^2)*cos(angle);

        d = side_length;

        solution = solve([(cx-x)^2 + (cy-y)^2 == radius^2, (px-x)^2 + (py-y)^2 == d^2], [x,y]);

        new_x1 = eval(solution.x(1));
        new_x2 = eval(solution.x(2));
        new_y1 = eval(solution.y(1));
        new_y2 = eval(solution.y(2));

        %assert(new_y1 == new_y2);


        new_y = new_y1;
        new_x = new_x1;

        if(cur_index < ref_struct_index)
          new_x = new_x2;
        end 

        new_image_struct = new_image_structs(num_made_image_structs+1);
        
        new_image_struct.image_name = cur_image_name;
        new_image_struct.world_pos = [new_x; p(2); new_y];

        new_image_structs(num_made_image_structs+1) = new_image_struct ;
        num_made_image_structs= num_made_image_structs+1;
      end%try catch
    end%for kl
  end%for jl, each cluster
 

  recon_pos = [image_structs.world_pos];

  new_pos = [new_image_structs.world_pos];


  plot(recon_pos(1,:), recon_pos(3,:), 'r.');
  hold on;
  plot(new_pos(1,:), new_pos(3,:), 'k.');
 
end%for i, each scene





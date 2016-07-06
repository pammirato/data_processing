%saves a camera poistions and orientations from text file outputted from reconstruction
%saves a cell array of these 'image structs', and also saves the scale 
%also saves a list of reconstructed 3d points seen by each image


%TODO - better name, processing for points2d

clearvars;

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Kitchen_Living_02_2'; %make this = 'all' to run all scenes
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


  %place holder struct for struct array
  blank_struct = struct(IMAGE_NAME, '', TRANSLATION_VECTOR, [], ...
                       ROTATION_MATRIX, [], WORLD_POSITION, [], ...
                       DIRECTION, [], QUATERNION, [], ...
                       SCALED_WORLD_POSITION, [0,0,0], IMAGE_ID,'',...
                       CAMERA_ID, '', 'cluster_id', -1, 'rotate_cw', -1, ...
                       'rotate_ccw',-1, 'translate_forward',-1,'translate_backward',-1);



  %load the structs 
  recon_struct_file = load(fullfile(meta_path,RECONSTRUCTION_DIR,'group1', 'colmap_results',...
                       '0', 'image_structs.mat'));
   
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


  %make a map from image name to image struct
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
%       if(counter > 3)
%         break;
%       end
    end%for kl 
    
    defining_structs = nestedSortStruct2(defining_structs, 'image_name');   



 
    pts = [defining_structs.t];

    pts(2,:) = [];    
 
    [center_x, center_y, radius, equation] = circfit(pts(1,:), pts(2,:)); 


 
    if(debug)

      hold off
     
      dirs = [defining_structs.direction];
      %world = [defining_structs.world_pos]
 
      %ts = [defining_structs.t];
      %rs = [defining_structs.R];

      %for ll=1:length(defining_structs)

      %  w = -rs(ll) * ts(ll);
 
      %  plot(w(1), w(3), 'r.', 'MarkerSize', 20);
      %  %plot(pts(1,:), pts(2,:), 'r.', 'MarkerSize', 20);
      %  hold on;
      %  %plot_circle(center_x, center_y,radius,'b');

      %  quiver(w(1),w(3), ...
      %           dirs(1,ll),dirs(3,ll), ...
      %            'ShowArrowHead','on','Color' ,'b');


      %  names = {defining_structs.image_name};


      %  text(w(1), w(3), names{ll});
      %  %text(pts(1,:), pts(2,:), names);
      %end
      %plot(world(1,:), world(3,:), 'r.', 'MarkerSize', 20);
      plot(pts(1,:), pts(2,:), 'r.', 'MarkerSize', 20);
      hold on;
      %plot_circle(center_x, center_y,radius,'b');

      quiver(pts(1,:),pts(2,:), ...
               dirs(1,:),dirs(3,:), ...
                'ShowArrowHead','on','Color' ,'b');


      names = {defining_structs.image_name};


      %text(world(1,:), world(3,:), names);
      text(pts(1,:), pts(2,:), names);
      axis equal;

 
      title(num2str(jl));
%      hold off;
%       ginput(1);
    end%if debug
 
 
 
     %% now do the interpolation
     
    for kl=1:cluster_size
      cur_image_name = all_image_names{(jl-1)*cluster_size + kl}; 

      %see if this image already has a struct 
      try
        cur_image_struct = name_to_image_struct_map(cur_image_name);
      catch
        %otherwise interplotate to make a new struct
        cur_index = str2double(cur_image_name(1:6));
        assert(cur_index ==  (jl-1)*cluster_size + kl);

        %find the closest structs to this one, clockwise and ccw
        ccw_struct = [];
        cw_struct = [];
        ccw_index_dist = 0;
        cw_index_dist = 0;

        for ll=length(defining_structs):-1:1
          cur_def_struct = defining_structs(ll);

          cur_def_index = str2double(cur_def_struct.image_name(1:6));

          if(cur_def_index < cur_index)
            ccw_struct = cur_def_struct;
            ccw_index_dist = abs(cur_def_index - cur_index);
            break;
          end              
        end 
  
        if(isempty(ccw_struct))
          ccw_struct = defining_structs(end);
          cur_def_index = str2double(ccw_struct.image_name(1:6));
          ccw_index_dist = abs((12-cur_def_index) + cur_index);
        end 


        for ll=1:length(defining_structs)
          cur_def_struct = defining_structs(ll);

          cur_def_index = str2double(cur_def_struct.image_name(1:6));

          if(cur_def_index > cur_index)
            cw_struct = cur_def_struct;
            cw_index_dist = abs(cur_def_index - cur_index);
            break;
          end              
        end 
  
        if(isempty(cw_struct))
          cw_struct = defining_structs(1);
          cur_def_index = str2double(cw_struct.image_name(1:6));
          cw_index_dist = abs((12-cur_index) + cur_def_index);
        end 



        pointA = [];
        angle = 0;        


        %if(ccw_index_dist < cw_index_dist)
        %  pointA = ccw_struct.t;
        %  angle = 30 * ccw_index_dist;
        %else
          pointA = cw_struct.t;
          angle = 30 * cw_index_dist;
       % end


        angle_rad = angle*pi/180;

        pointA(2) = [];
        pointC = [center_x; center_y];

        %law of cosines
        sideAB = sqrt(radius^2 + radius^2 - 2*radius*radius*cosd(angle));


        a = (sideAB^2 - radius^2 + radius^2) / (2*radius);
        %a = sideAB*cos(angle_rad);
        h = sideAB*sind((180-angle)/2);
       % h = radius*sind(180 - 2*angle);

        P2 = pointA + a*(pointC - pointA)/radius;

        p31 = P2 +  h*(pointC([2,1]) - pointA([2,1]))/radius; 
        p32 = P2 -  h*(pointC([2,1]) - pointA([2,1]))/radius; 

        x31 = P2(1) + h*(pointC(2) - pointA(2))/radius;
        x32 = P2(1) - h*(pointC(2) - pointA(2))/radius;
        y31 = P2(2) + h*(pointC(1) - pointA(1))/radius;
        y32 = P2(2) - h*(pointC(1) - pointA(1))/radius;
       



        if(debug)
          plot(x31, y32, 'k.', 'MarkerSize', 20); 
         % %plot(x32, y31, 'g.', 'MarkerSize', 20); 
         % plot(pointA(1), pointA(2), 'm.', 'MarkerSize', 20); 
         % plot(pointC(1), pointC(2), 'm.', 'MarkerSize', 20); 
         % plot(P2(1), P2(2), 'c.', 'MarkerSize', 20); 
          text(x31, y32, cur_image_name); 
          %hold off;
          %ginput(1);
        end


        new_t = [x31; cw_struct.t(2)  ;y32];

        %% now get new R

        ccw_quat= ccw_struct.quat;
        cw_quat = cw_struct.quat;

        %ccw_quat_n = quatnormalize(ccw_quat);
        %cw_quat_n = quatnormalize(cw_quat);
  
        f = ccw_index_dist / (ccw_index_dist + cw_index_dist);

        %new_quat = quatinterp(ccw_quat_n, cw_quat_n, frac, 'slerp');


        new_quat = ccw_quat;


        new_quat = slerp(ccw_quat, cw_quat, f, 10*eps);


        new_R = quat2rotm(new_quat');


        new_world_pos = -new_R' * new_t;


        vec1 = [0;0;1;1];
        vec2 = [0;0;0;1];
        proj = [-new_R' new_world_pos];
        cur_vec = (proj * vec1) - (proj*vec2);

        new_direction = -cur_vec;



        new_struct = blank_struct;
        new_struct.image_name = cur_image_name;
        new_struct.t = new_t;
        new_struct.R = new_R;
        new_struct.direction = new_direction;
        new_struct.quat = new_quat;
        new_struct.world_pos = -new_R' * new_t;


        if(debug)
          quiver(x31,y32, ...
             new_direction(1),new_direction(3), ...
             'ShowArrowHead','on','Color' ,'b');
          ginput(1);
        end

        new_image_structs(num_made_image_structs+1) = new_struct;
        num_made_image_structs= num_made_image_structs+1;
      end%try catch
    end%for kl
  end%for jl, each cluster
 

   recon_pos = [image_structs.t];
   new_pos = [new_image_structs.t];
   recon_pos = [image_structs.world_pos];
   new_pos = [new_image_structs.world_pos];
 
 
   plot(recon_pos(1,:), recon_pos(3,:), 'r.');
   hold on;
   plot(new_pos(1,:), new_pos(3,:), 'k.');
 
end%for i, each scene





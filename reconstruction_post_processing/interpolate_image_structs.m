%Interpolates a position and orientation of the images that were not reconstructed.

%TODO - finish testing of new direction computation 
%     - dont check which images were reconstructed twice
%     - do we need cw_Struct and ccw_struct or just one?


%CLEANED - ish 
%TESTED - ish  -does new angle work for angle > 90?  > 180?
clearvars;

%initialize contants, paths and file names, etc. 
init;

%% USER OPTIONS

scene_name = 'Home_16_1'; %make this = 'all' to run all scenes
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'Kitchen_05_1', 'Office_01_1'};%populate this 

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

%% MAIN LOOP
for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il}
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %load the structs for the reconstructed images and make a map
  recon_struct_file = load(fullfile(meta_path,RECONSTRUCTION_RESULTS, 'colmap_results',...
                       model_number, 'image_structs.mat'));
   
  image_structs = recon_struct_file.image_structs;
  scale = recon_struct_file.scale;

  image_structs_map = make_image_structs_map(image_structs); 


  %get the names of all rgb images for this scene 
  image_names = get_scenes_rgb_names(scene_path);

  %get a sample struct with all the fields we need. Remove values from all vields
  sample_struct = image_structs(1);
  fields = fieldnames(sample_struct);
  for jl=1:length(fields)
    sample_struct.(fields{jl}) = [];
  end
 
  %make a struct array to hold the new structs for all images that were not reconstructed 
  new_image_structs = repmat(sample_struct, 1, length(image_names)-length(image_structs)); 
  new_structs_made = 0;


  %get the names of all the images, and make a blank struct array for them all 
  temp = dir(fullfile(scene_path, 'rgb', '*.png'));
  all_image_names = {temp.name};



  %for each cluster of images, process all images in that cluster
  %assumes image name index is correct indicator of cluster
  for jl=1:(length(all_image_names)/cluster_size)

    %store the structs that were reconstructed in this cluster 
    counter = 1; 
    defining_structs = repmat(sample_struct, 1, cluster_size);

    %for each image in the cluster see if it was reconstructed
    for kl=1:cluster_size
      cur_image_name = all_image_names{(jl-1)*cluster_size + kl}; 

      try
        cur_image_struct = image_structs_map(cur_image_name(1:10));
        defining_structs(counter) = cur_image_struct;
        counter = counter +1;
      catch
      end
  
    end%for kl 
   
    %remove empty structs from array 
    defining_structs(counter:end) = [];
    
    assert(~isempty(defining_structs));


    %debug option, plots the defining structs for this cluster
    if(debug)
      hold off
      dirs = [defining_structs.direction];
      world = [defining_structs.world_pos];
      plot(world(1,:), world(3,:), 'k.', 'MarkerSize', 20);
      hold on;
      quiver(world(1,:),world(3,:), ...
               dirs(1,:),dirs(3,:), ...
                'ShowArrowHead','on','Color' ,'b');
      names = {defining_structs.image_name};
      text(world(1,:), world(3,:), names);
      axis equal;
      title(num2str(jl));
    end%if debug
 
 
    %% now do the interpolation
    % for each image in the cluster, if it was not reconstructed, interpolate
    % position and direction
    for kl=1:cluster_size
      cur_image_name = all_image_names{(jl-1)*cluster_size + kl}; 

      %see if this image already has a struct 
      try
        cur_image_struct = image_structs_map(cur_image_name(1:10));
      catch
        %otherwise interplotate to make a new struct
        cur_index = str2double(cur_image_name(1:6));
        assert(cur_index ==  (jl-1)*cluster_size + kl);

        %find the closest structs to this one,
        %so that moving from the defined struct to the new struct is a 
        %counter clockwise or clockwise move
        ccw_struct = [];
        cw_struct = [];
        ccw_index_dist = 0;
        cw_index_dist = 0;


        %moving counter clockwise increases index, so find the defined struct
        %with the closest, smaller index
        for ll=length(defining_structs):-1:1
          cur_def_struct = defining_structs(ll);
          cur_def_index = str2double(cur_def_struct.image_name(1:6));

          if(cur_def_index < cur_index)
            ccw_struct = cur_def_struct;
            ccw_index_dist = abs(cur_def_index - cur_index);
            break;
          end              
        end 
 
        %if the ccw index is around the start of the circle 
        if(isempty(ccw_struct))
          ccw_struct = defining_structs(end);
          cur_def_index = str2double(ccw_struct.image_name(1:6));
          ccw_index_dist = abs((12-cur_def_index) + cur_index);
        end 


        %moving clockwise decreases index, so find hte defined struct with
        %the closest, larger index
        for ll=1:length(defining_structs)
          cur_def_struct = defining_structs(ll);
          cur_def_index = str2double(cur_def_struct.image_name(1:6));

          if(cur_def_index > cur_index)
            cw_struct = cur_def_struct;
            cw_index_dist = abs(cur_def_index - cur_index);
            break;
          end              
        end 
  
        %if the cw index is around the start of the circle 
        if(isempty(cw_struct))
          cw_struct = defining_structs(1);
          cur_def_index = str2double(cw_struct.image_name(1:6));
          cw_index_dist = abs((12-cur_index) + cur_def_index);
        end 

        %make new image struct for this image
        new_struct = sample_struct;
       
        %set the new position to be the average of all the other positions in this cluster 
        defined_worlds = [defining_structs.world_pos];
        new_struct.world_pos = mean(defined_worlds,2);

        %rotate the ccw_struct's direction vector by the given angle
        angle = 30 * ccw_index_dist;
        ccw_dir = ccw_struct.direction;
        new_dir = ccw_dir;

        %https://www.siggraph.org/education/materials/HyperGraph/modeling/mod_tran/2drota.htm
        new_dir(1) = ccw_dir(1)*cosd(angle) - ccw_dir(3)*sind(angle); 
        new_dir(3) = ccw_dir(3)*cosd(angle) + ccw_dir(1)*sind(angle); 
        
        %update new structs fields   
        new_struct.direction = new_dir;
        new_struct.image_name = cur_image_name;
        new_struct.scaled_world_pos = new_struct.world_pos * scale; 

        if(debug)
          plot(new_struct.world_pos(1), new_struct.world_pos(3), 'r.', 'MarkerSize', 20);
          text(new_struct.world_pos(1), new_struct.world_pos(3), cur_image_name);

          quiver(new_struct.world_pos(1), new_struct.world_pos(3), ...
            new_struct.direction(1)/30,new_struct.direction(3)/30, ...
            'ShowArrowHead','on','Color' ,'b');
          %ginput(1);
          breakp=1;
        end%debug

        %put the newly made struct into the new structs array 
        new_image_structs(new_structs_made+1) = new_struct;
        new_structs_made= new_structs_made+1;
      end%try catch
    end%for kl
  end%for jl, each cluster
 

  if(debug)
    recon_pos = [image_structs.t];
    new_pos = [new_image_structs.t];
    recon_pos = [image_structs.world_pos];
    new_pos = [new_image_structs.world_pos];


    plot(recon_pos(1,:), recon_pos(3,:), 'r.');
    hold on;
    plot(new_pos(1,:), new_pos(3,:), 'k.');
  end%debug


  %% add the newly made structs into the image structs array, sort and save them
  image_structs = [image_structs new_image_structs];
  image_structs = nestedSortStruct2(image_structs, 'image_name');

  %make sure all structs were made 
  assert(new_structs_made == (length(new_image_structs)));
 
  save(fullfile(meta_path,RECONSTRUCTION_RESULTS, 'colmap_results',...
                       model_number, 'image_structs.mat'), 'image_structs', 'scale');
end%for il, each scene





%saves a camera poistions and orientations from text file outputted from reconstruction
%saves a cell array of these 'image structs', and also saves the scale 
%also saves a list of reconstructed 3d points seen by each image


%TODO - better name, processing for points2d

clearvars;

%initialize contants, paths and file names, etc. 
init;


%% USER OPTIONS

scene_name = 'Kitchen_Living_02_2'; %make this = 'all' to run all scenes
ref_group = 'group1'
trans_group = 'group2';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 

cluster_size = 12;%how many images are in each cluster

debug = 1;

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


  all_image_names = get_names_of_X_for_scene(scene_name, 'rgb_images');


  %place holder for struct arrays
  blank_struct = struct(IMAGE_NAME, '', TRANSLATION_VECTOR, [], ...
                       ROTATION_MATRIX, [], WORLD_POSITION, [], ...
                       DIRECTION, [], QUATERNION, [], ...
                       SCALED_WORLD_POSITION, [0,0,0], IMAGE_ID,'',...
                       CAMERA_ID, '', 'cluster_id', -1, 'rotate_cw', -1, ...
                       'rotate_ccw',-1, 'translate_forward',-1,'translate_backward',-1);


  %load the image structs for each reconstruction
  recon_struct_file = load(fullfile(meta_path,RECONSTRUCTION_DIR,ref_group,'colmap_results',...
                        '0', 'image_structs.mat'));
   
  ref_image_structs = recon_struct_file.image_structs;
  scale = recon_struct_file.scale;

  recon_struct_file = load(fullfile(meta_path,RECONSTRUCTION_DIR,trans_group,'colmap_results',...
                        '0','image_structs.mat'));
  trans_image_structs = recon_struct_file.image_structs;



  %% make a map from image name to image_struct for both reconstructions
  ref_image_structs_names = {ref_image_structs.image_name};
  ref_image_structs_map = containers.Map(ref_image_structs_names,...
                                 cell(1,length(ref_image_structs_names)));

  for jl=1:length(ref_image_structs_names)
    ref_image_structs_map(ref_image_structs_names{jl}) = ref_image_structs(jl);
  end


  trans_image_structs_names = {trans_image_structs.image_name};
  trans_image_structs_map = containers.Map(trans_image_structs_names,...
                                 cell(1,length(trans_image_structs_names)));

  for jl=1:length(trans_image_structs_names)
    trans_image_structs_map(trans_image_structs_names{jl}) = trans_image_structs(jl);
  end






  all_image_structs = repmat(blank_struct, 1, length(all_image_names));
  image_structs_added_counter = 0;
 
  scale2=  .7;

  %for each cluster 
  for jl=1:cluster_size:length(all_image_names)

    start_ind = jl;% (jl-1)*(cluster_size) + 1;
    end_ind = start_ind +(cluster_size-1);

    shared_structs_ref = blank_struct;
    shared_structs_trans = blank_struct;
    unique_ref_structs = blank_struct;
    unique_trans_structs = blank_struct;

    for kl=start_ind:end_ind
      ref_flag  = 0;
      trans_flag = 0;

      cur_image_name = all_image_names{kl}

      %see if this image is in the reference reconstruction
      try
        ref_struct = ref_image_structs_map(cur_image_name);
        ref_flag = 1;
      catch
      end

      %see if this image is in the reconstruction to be transformed
      try
        trans_struct = trans_image_structs_map(cur_image_name);
        trans_flag = 1;
      catch
      end
      
      %based on which reconstructions this image is in, 
      %modify the apporpriate data structtures
      if(ref_flag && trans_flag)
        shared_structs_ref(end+1) = ref_struct;
        shared_structs_trans(end+1) = trans_struct;
  
      elseif(ref_flag)
        unique_ref_structs(end+1) = ref_struct;
      
      elseif(trans_flag)
        unique_trans_structs(end+1) = trans_struct; 
      end
    end%for kl

    %get rid of blank struct
    shared_structs_ref(1) = [];
    shared_structs_trans(1) = [];
    unique_ref_structs(1)= [];
    unique_trans_structs(1) = [];
    


    transforms = zeros(4,4,length(shared_structs_ref));

   
    %now find the transform between each iamge that is in both reconstructions
    for kl=1:length(shared_structs_ref)
      ref_struct = shared_structs_ref(kl);
      trans_struct = shared_structs_trans(kl);

      ref_p = [ref_struct.R ref_struct.t; 0 0 0 1]; 
      trans_p = [trans_struct.R trans_struct.t*scale2; 0 0 0 1]; 
 
      transforms(:,:,kl) = pinv(ref_p) * trans_p;
    end%kl

    avg_trans = sum(transforms, 3) / size(transforms,3);


    transformed_trans_structs = unique_trans_structs;

    for kl=1:length(unique_trans_structs)
      trans_struct = unique_trans_structs(kl);

      trans_p = [trans_struct.R trans_struct.t*scale2; 0 0 0 1]; 

      new_trans_p = trans_p * avg_trans;

      trans_struct.R = new_trans_p(1:3,1:3);
      trans_struct.t = new_trans_p(1:3, 4);
      trans_struct.world_pos = -(trans_struct.R)' * trans_struct.t;
      trans_struct.quat = rotm2quat(trans_struct.R);

      transformed_trans_structs(kl) = trans_struct;

    end%for kl

    %now put the structs into the global array to hold all structs for the scene
    cluster_structs = [shared_structs_ref unique_ref_structs transformed_trans_structs];

    start_ind = image_structs_added_counter +1;
    end_ind = start_ind + length(cluster_structs) -1;
    all_image_structs(start_ind:end_ind) = cluster_structs;
    image_structs_added_counter = image_structs_added_counter + length(cluster_structs);



    if(debug)
      wp = [cluster_structs.world_pos];
  
      plot(wp(1,:), wp(3,:), 'r.');
      ginput(1);
    end%if debug

  end%for jl, each cluster in all_image_names
end%for i, each scene




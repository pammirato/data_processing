function [] = remove_image_cluster(scene_name)
% removes a cluster from scene
%
 
%TODO  - allow multiple clusters
%        - check for directory existence before renaming

%CLEANED - no
%TESTED - no

%clearvars;

%initialize contants, paths and file names, etc. 
init;


%% USER OPTIONS


%scene_name = 'Home_00_1'; %make this = 'all' to run all scenes
model_number = '0';
%use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
%custom_scenes_list = {};%populate this 



cluster_size = 12;

%% SET UP GLOBAL DATA STRUCTURES

%get the names of all the scenes
d = dir(ROHIT_BASE_PATH);
d = d(3:end);
all_scenes = {d.name};


%determine which scenes are to be processed 
if(iscell(scene_name))
  %if we are using the custom list of scenes
  all_scenes = scene_name;
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


  %get new 5 digit index to add append as prefix to all image names
  split_name = strsplit(scene_name,'_');
  if(strcmp('Home',split_name{1}))
    scene_type = 0;
  else
    scene_type = 1;
  end

  scene_prefix = strcat(num2str(scene_type),'0',...
                  split_name{2},split_name{3});

  
 



  %load image_structs for all images
  image_structs_file =  load(fullfile(meta_path, RECONSTRUCTION_RESULTS, ...
                                'colmap_results', ...
                                model_number, IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;%just keep track of this to save later



  point2ds_file =  load(fullfile(meta_path, RECONSTRUCTION_RESULTS, ...
                                'colmap_results', ...
                                model_number, POINT_2D_STRUCTS_FILE));

  p2d_structs = point2ds_file.point_2d_structs;


  %make new names
  org_image_names = {image_structs.image_name};
  temp = cell2mat(org_image_names');
  org_image_indexes = temp(:,1:6);
  new_image_names = cell(1,length(org_image_names));

  org_to_new_index_map = containers.Map();

  for jl=1:length(org_image_names)

    old_index = org_image_indexes(jl,:);
    new_index_s = strcat(scene_prefix,old_index);

    org_to_new_index_map(org_image_indexes(jl,:)) = new_index_s;
  end%for jl, each original image name


  %rename all directories
  disp('Renaming rgb ...');
  rename_directory(RGB,fullfile(meta_path,'raw_data'),org_to_new_index_map);
  
  disp('Renaming jpg_rgb ...');
  rename_directory(JPG_RGB,scene_path,org_to_new_index_map);
  
  disp('Renaming raw_depth ...');
  rename_directory(RAW_DEPTH,fullfile(meta_path,'raw_data'),org_to_new_index_map);

  try
    disp('Renaming high res depth ...');
    rename_directory(HIGH_RES_DEPTH,scene_path,org_to_new_index_map);
  catch
    disp('no high res depth!');
    
  end

  try
    disp('Renaming improved depth ...');
    rename_directory(IMPROVED_DEPTH,meta_path,org_to_new_index_map);
  catch
    disp('no improved depths');
  end
  
  disp('Renaming raw_labels ...');
  rename_directory(BBOXES_BY_IMAGE_INSTANCE,fullfile(meta_path, LABELING_DIR,...
                 'raw_labels'),org_to_new_index_map);
  disp('Renaming verified labels ...');
  rename_directory( BBOXES_BY_IMAGE_INSTANCE,fullfile(meta_path, LABELING_DIR,...
                 'verified_labels'),org_to_new_index_map);

  disp('Converting Boxes ...');             
  %convert_boxes_by_image_instance_to_instance(scene_name, 'raw_labels');
  convert_boxes_by_image_instance_to_instance(scene_name, 'verified_labels');

  disp('Renaming  image_structs ...');
  %update image structs, points2d,3d
  for jl=1:length(image_structs)
    cur_struct = image_structs(jl);
    cur_name = cur_struct.image_name;
    new_index_s = org_to_new_index_map(cur_name(1:6));
    new_name = strcat(new_index_s, cur_name(7:end));
    cur_struct.image_name = new_name;
    image_structs(jl) = cur_struct; 
  end%for jl, each image_struct  

  disp('Renaming point 2d structs ...');
  bad_inds = [];
  %update points2d
  for jl=1:length(p2d_structs)
    cur_struct = p2d_structs(jl);
    cur_name = cur_struct.image_name;
    try
      new_index_s = org_to_new_index_map(cur_name(1:6));
    catch
      bad_inds(end+1) = jl;
      continue;
    end
    new_name = strcat(new_index_s, cur_name(7:end));
    cur_struct.image_name = new_name;
    p2d_structs(jl) = cur_struct; 
  end%for jl, each image_struct 

  %remove structs from the deletec cluster
  p2d_structs(bad_inds) = [];
  
  point_2d_structs = p2d_structs;

  %save the update image structs  
  save(fullfile(meta_path, RECONSTRUCTION_RESULTS, 'colmap_results', ...
                model_number,  IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE);
  
  save(fullfile(meta_path, RECONSTRUCTION_RESULTS,'colmap_results',...
               model_number, POINT_2D_STRUCTS_FILE), POINT_2D_STRUCTS);

  disp('Assigning movement pointers ...');
  assign_rotate_pointers(scene_name);
  assign_forward_back_left_right(scene_name);
  
  disp('Writing json ...');
  write_annotations_to_json(scene_name);

end%for il,  each scene

%end%function

%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object

%TODO -get rid of image structs map. Just use indexes. (Make it sorted?)


clearvars;

%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

scene_name = 'Home_14_1'; %make this = 'all' to run all scenes
group_name = 'all';
%group_name = 'all_minus_boring';
model_number = '0';
use_custom_scenes = 1;%whether or not to run for the scenes in the custom list
custom_scenes_list  = {'Home_01_1', 'Home_01_2', 'Home_02_1', 'Home_03_1', 'Home_03_2', 'Home_04_1', 'Home_04_2', 'Home_05_1', 'Home_05_2', 'Home_06_1', 'Home_08_1', 'Home_14_1', 'Home_14_2', 'Office_01_1'};
 
%custom_scenes_list = {'Kitchen_Living_01_1','Kitchen_Living_03_1','Kitchen_Living_03_2','Kitchen_Living_04_2','Kitchen_Living_06'};%populate this 



label_to_process = 'all'; %make 'all' for every label
label_names = {label_to_process};



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





%load mapping from bigbird name ot category id
obj_cat_map = containers.Map();
fid_bb_map = fopen('/playpen/ammirato/Data/RohitMetaMetaData/big_bird_cat_map.txt', 'rt');

line = fgetl(fid_bb_map);
while(ischar(line))
  line = strsplit(line);
  obj_cat_map(line{1}) = str2double(line{2}); 
  line = fgetl(fid_bb_map);
end
fclose(fid_bb_map);








%% MAIN LOOP

for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);
  disp(scene_name);


  save_base_path = fullfile('/playpen/ammirato/Data/Eunbyung_Data/', scene_name);
  if(~exist(save_base_path, 'dir'))
    mkdir(save_base_path);
  end
  move_save_path = fullfile(save_base_path, 'moves');
  if(~exist(move_save_path, 'dir'))
    mkdir(move_save_path);
  end

  %load image_structs for all images
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results',...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;

  %get a list of all the image file names
  image_names = {image_structs.(IMAGE_NAME)};

  %make a map from image name to image_struct
  image_structs_map = containers.Map(image_names,...
                                 cell(1,length(image_names)));


  %populate the map
  for jl=1:length(image_names)
    image_structs_map(image_names{jl}) = image_structs(jl);
  end

  %% MAIN LOOP  for each label find its bounding box in each image

  %for each point cloud
%  image_names = image_names(640:end);
  for jl=1:length(image_names)
    
    cur_image_name = image_names{jl};

    cur_struct = image_structs_map(cur_image_name);
   % cur_image_index = str2double(cur_image_name(1:6)); 

    f_name = cur_struct.translate_forward;
    b_name = cur_struct.translate_backward;
    l_name = cur_struct.translate_left;
    r_name = cur_struct.translate_right;
    cw_name = cur_struct.rotate_cw;
    ccw_name = cur_struct.rotate_ccw;


    ann_fid = fopen(fullfile(move_save_path, strcat(cur_image_name(1:15), '_moves.txt')), 'wt');

    if(f_name == -1)
      fprintf(ann_fid,'%d %d\n', 1, -1);
    else
      fprintf(ann_fid,'%d %d\n', 1, str2double(f_name(6:11)));
    end 
    if(b_name == -1)
      fprintf(ann_fid,'%d %d\n', 2, -1);
    else
      fprintf(ann_fid,'%d %d\n', 2, str2double(b_name(6:11)));
    end 
    if(l_name == -1)
      fprintf(ann_fid,'%d %d\n', 3, -1);
    else
      fprintf(ann_fid,'%d %d\n', 3, str2double(l_name(6:11)));
    end 
    if(r_name == -1)
      fprintf(ann_fid,'%d %d\n', 4, -1);
    else
      fprintf(ann_fid,'%d %d\n', 4, str2double(r_name(6:11)));
    end 
    if(cw_name == -1)
      fprintf(ann_fid,'%d %d\n', 5, -1);
    else
      fprintf(ann_fid,'%d %d\n', 5, str2double(cw_name(6:11)));
    end 
    if(ccw_name == -1)
      fprintf(ann_fid,'%d %d\n', 6, -1);
    else
      fprintf(ann_fid,'%d %d\n', 6, str2double(ccw_name(6:11)));
    end 


    fclose(ann_fid);

  end%for jl, each image
end%for i, each scene_name


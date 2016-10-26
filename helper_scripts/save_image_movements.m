% Writes movement pointers to text file. One file per image, one line per action.
% Each line has action_id image_name
% Where action_id is a numeric id of the possible actions (forward, left, rotate, etc)
% Image_name is the name of the image that the robot would see if it takes the action
% If there is no image corresponding to the action, image_name is -1


%CLEANED - yes 
%TESTED - no


%TODO - load file to map from action name to action id
%     - make loop instead of rewriting print over and over


clearvars;

%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

scene_name = 'Kitchen_Living_08_1'; %make this = 'all' to run all scenes
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


%where to save the .txt files
save_base_path = fullfile('/playpen/ammirato/Data/Eunbyung_Data/');

%whether to write full image name, or just index(first 6 chars)
write_just_image_index = 0;


debug =0;


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

  save_path = fullfile(save_base_path, scene_name);

  if(~exist(save_path, 'dir'))
    mkdir(save_path);
  end
  move_save_path = fullfile(save_path, 'moves');
  if(~exist(move_save_path, 'dir'))
    mkdir(move_save_path);
  end

  %load image_structs for all images
  image_structs_file =  load(fullfile(meta_path,RECONSTRUCTION_RESULTS, ...
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


  
  %% for each image, write out its pointers
  for jl=1:length(image_names)
   
    %get the current image name and image struct
    cur_image_name = image_names{jl};
    cur_struct = image_structs_map(cur_image_name);

    %get all the movement pointers
    f_name = cur_struct.translate_forward;
    b_name = cur_struct.translate_backward;
    l_name = cur_struct.translate_left;
    r_name = cur_struct.translate_right;
    cw_name = cur_struct.rotate_cw;
    ccw_name = cur_struct.rotate_ccw;


    %open the output text file
    out_fid = fopen(fullfile(move_save_path, strcat(cur_image_name(1:10), '_moves.txt')), 'wt');


    %write out the pointers: action_id image_name
    if(f_name == -1)
      %if there is no image corresponding to this action
      fprintf(out_fid,'%d %d\n', 1, -1);
    else
      if(write_just_image_index)
        %write just first 6 chars
        fprintf(out_fid,'%d %d\n', 1, str2double(f_name(1:6)));
      else
        %write entire image_name
        fprintf(out_fid,'%d %d\n', 1, str2double(f_name));
      end
    end 

    if(b_name == -1)
      fprintf(out_fid,'%d %d\n', 2, -1);
    else
      if(write_just_image_index)
        fprintf(out_fid,'%d %d\n', 2, str2double(b_name(1:6)));
      else
        fprintf(out_fid,'%d %d\n', 2, str2double(b_name));
      end
    end 

    if(l_name == -1)
      fprintf(out_fid,'%d %d\n', 3, -1);
    else
      if(write_just_image_index)
        fprintf(out_fid,'%d %d\n', 3, str2double(l_name(1:6)));
      else
        fprintf(out_fid,'%d %d\n', 3, str2double(l_name));
      end
    end 

    if(r_name == -1)
      fprintf(out_fid,'%d %d\n', 4, -1);
    else
      if(write_just_image_index)
        fprintf(out_fid,'%d %d\n', 4, str2double(r_name(1:6)));
      else
        fprintf(out_fid,'%d %d\n', 4, str2double(r_name));
      end
    end 

    if(cw_name == -1)
      fprintf(out_fid,'%d %d\n', 5, -1);
    else
      if(write_just_image_index)
        fprintf(out_fid,'%d %d\n', 5, str2double(cw_name(1:6)));
      else
        fprintf(out_fid,'%d %d\n', 5, str2double(cw_name));
      end
    end 

    if(ccw_name == -1)
      fprintf(out_fid,'%d %d\n', 6, -1);
    else
      if(write_just_image_index)
        fprintf(out_fid,'%d %d\n', 6, str2double(ccw_name(1:6)));
      else
        fprintf(out_fid,'%d %d\n', 6, str2double(ccw_name));
      end
    end 


    %close the file
    fclose(out_fid);
  end%for jl, each image
end%for i, each scene_name


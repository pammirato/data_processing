function [] = write_movement_pointers_to_text(scene_name)
%Writes the image structs movement pointers to text files.
%One file per image
%
%INPUTS:
%         scene_name: char array of single scene name, 'all' for all scenes, 
%                     or a cell array of char arrays, one for each desired scene


%TODO  

%CLEANED - yes 
%TESTED - no

%clearvars;

%initialize contants, paths and file names, etc. 
init;


%% USER OPTIONS


%scene_name = 'Kitchen_Living_08_1'; %make this = 'all' to run all scenes
model_number = '0';


%% SET UP GLOBAL DATA STRUCTURES

%get the names of all the scenes
d = dir(ROHIT_BASE_PATH);
d = d(3:end);
all_scenes = {d.name};


%determine which scenes are to be processed 
if(iscell(scene_name))
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


  %load image_structs for all images
  image_structs_file =  load(fullfile(meta_path, RECONSTRUCTION_RESULTS, ...
                                'colmap_results', ...
                                model_number, IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;%just keep track of this to save later

  save_path = fullfile(scene_path,'labels','text_labels','movement_pointers');
  if(~exist(save_path,'dir'))
    mkdir(save_path);
  end

  format_file = fullfile(scene_path,'labels','text_labels', 'movement_format.txt');
  format_fid = fopen(format_file, 'wt');

  fprintf(format_fid, ['Format for movement pointers.\n' ...
                      'One file per image, one line per movement with' ...
                      'name of image of view that move results in:\n' ...
                      '(A blank line indicates the move is not available)\n\n' ...
                      'rotate counter clockwise\n' ... 
                      'rotate clockwise\n' ... 
                      'translate forward\n' ... 
                      'translate backward\n' ... 
                      'translate left\n' ... 
                      'translate right\n']);

  fclose(format_fid);


  for jl=1:length(image_structs)

    cur_struct = image_structs(jl);
    image_name = cur_struct.image_name;
    file_name = strcat(image_name(1:10),'.txt');
    
    fid = fopen(fullfile(save_path,file_name), 'wt');

%     if(cur_struct.translate_right == -1)
%       cur_struct.translate_right = '';
%     end

    fprintf(fid,'%s\n%s\n%s\n%s\n%s\n%s', cur_struct.rotate_ccw, ...
                                          cur_struct.rotate_cw, ...
                                          cur_struct.translate_forward, ...
                                          cur_struct.translate_backward, ...
                                          cur_struct.translate_left, ...
                                          cur_struct.translate_right);
    
    if(cur_struct.translate_right == -1)
      fprintf(fid,'\n');
    end
                                        
    fclose(fid);
  end%for jl, each image struct

end%for il,  each scene

end

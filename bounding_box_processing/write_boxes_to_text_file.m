function write_boxes_to_text_file(scene_name,  label_type)
%converts bounding box labels by image instance in .mat files to .txt files
%
%INPUTS:
%         scene_name: char array of single scene name, 'all' for all scenes, 
%                     or a cell array of char arrays, one for each desired scene
%         label_type: OPTIONAL 'verified_labels'(default) or 'raw_labels'
%
%
%



%CLEANED - no
%TESTED - no

%TODO  - write all boxes at once for each image (get rid of kl loop)
%      - give option for boxes by image instance or by instance

%clearvars;

%initialize contants, paths and file names, etc. 

init;



%% USER OPTIONS

%where to save the .txt files

%scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 

label_to_process = 'all'; %make 'all' for every label
label_names = {label_to_process};



if(nargin < 2)
  label_type = 'verified_labels';  %raw_labels - automatically generated labels
                            %verified_labels - boxes looked over by human
end

debug =0;

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
  scene_name = all_scenes{il}
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  % make the directory to save the text files if it does not exist
  save_path = fullfile(scene_path,'labels','text_labels', BBOXES_BY_IMAGE_INSTANCE);
  if(~exist(save_path, 'dir'))
    mkdir(save_path);
  end

  %write format file
  format_file = fullfile(scene_path,'labels','text_labels', 'format.txt');
  if(~exist(format_file,'file'))
    format_fid = fopen(format_file,'wt');
    
    fprintf(format_fid, ['Boxes by image instance format:\n' ...
                        'One File per image, one line per bounding box:\n' ...
                        'xmin ymin xmax ymax instance_id difficulty']);
    fprintf(format_fid, ['\n\nBoxes by instance format:\n' ...
                        'One File per instance, one line per bounding box:\n' ...
                        'image_name xmin ymin xmax ymax instance_id difficulty']);
    fclose(format_fid);
  end

  %get the path were the .mat files are, and all the file names
  load_path = fullfile(meta_path, LABELING_DIR, label_type, BBOXES_BY_IMAGE_INSTANCE);
  file_names = dir(fullfile(load_path,'*.mat'));
  file_names = {file_names.name};

  for jl=1:length(file_names)
    cur_file_name = file_names{jl};
    mat_labels = load(fullfile(load_path,cur_file_name));
    

    %create/open text file for writing
    %cur_fid = fopen(fullfile(save_path,strcat(cur_file_name(1:10),'.txt')), 'wt');
    text_file_name = fullfile(save_path,strcat(cur_file_name(1:10),'.txt'));
    dlmwrite(text_file_name,mat_labels.boxes, ' '); 

    %write the labels to the file
    %fprintf( 

    %fclose(cur_fid);
  end 


end%for i, each scene_name

end

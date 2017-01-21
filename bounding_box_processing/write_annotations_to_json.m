function write_annotations_to_json(scene_name)
%converts bounding box labels by image instance in .mat files to .txt files
%
%INPUTS:
%         scene_name: char array of single scene name, 'all' for all scenes, 
%                     or a cell array of char arrays, one for each desired scene
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

model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 

label_to_process = 'all'; %make 'all' for every label
label_names = {label_to_process};



label_type = 'verified_labels';  %raw_labels - automatically generated labels

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


  %load image_structs for all images
  image_structs_file =  load(fullfile(meta_path, RECONSTRUCTION_RESULTS, ...
                                'colmap_results', ...
                                model_number, IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  image_names = {image_structs.image_name};


  % make the directory to save the text files if it does not exist
  save_path = fullfile(scene_path);
  if(~exist(save_path, 'dir'))
    mkdir(save_path);
  end

  %write format file
  format_file = fullfile(save_path,'annotations_format.txt');
  if(1) %(~exist(format_file,'file'))
    format_fid = fopen(format_file,'wt');
   
        
 
    fprintf(format_fid, ['JSON file has bounding boxes, and movement pointers:\n' ...
                        'One object image, each box has six numbers:\n' ...
                        '(See webpage for description of difficulty calculation)\n\n'...
                        'xmin ymin xmax ymax instance_id difficulty']);




    fprintf(format_fid, ['\n\n\nFormat for movement pointers.\n' ...
                      'Name of image that move results in:\n' ...
                      '(An empty string indicates the move is not available)\n\n' ...
                      'rotate_ccw: rotate counter clockwise\n' ... 
                      'rotate_ccw: rotate clockwise\n' ... 
                      'forward: translate forward\n' ... 
                      'backward: translate backward\n' ... 
                      'left: translate left\n' ... 
                      'right: translate right\n']);

    fclose(format_fid);
  end

  %get the path were the .mat files are, and all the file names
  load_path = fullfile(meta_path, LABELING_DIR, label_type, BBOXES_BY_IMAGE_INSTANCE);

  json_fid = fopen(fullfile(save_path, 'annotations.json'), 'wt');
  %print start
  fprintf(json_fid, '{\n');


%  image_names = image_names(1:3);
  for jl=1:length(image_names)
    cur_image_name = image_names{jl};
    cur_struct = image_structs(jl);

    box_labels = load(fullfile(load_path,...
                              strcat(cur_image_name(1:10), '.mat')));
    box_labels = box_labels.boxes;
   
    fprintf(json_fid,'\t"%s":{\n', cur_image_name);

      %write bounding boxes
      fprintf(json_fid,'\t\t"bounding_boxes":[\n');
      for kl=1:size(box_labels,1)
        box = box_labels(kl,:);
        fprintf(json_fid,'\t\t\t[%d,%d,%d,%d,%d,%d]', box(1), box(2), ...
                              box(3), box(4), box(5), box(6));
        if(kl < size(box_labels,1))
          fprintf(json_fid,',\n');
        else
          fprintf(json_fid,'\n');
        end
      end%for kl
      fprintf(json_fid,'\t\t],\n');

    %write movement pointers
    fprintf(json_fid, '\t\t"rotate_ccw":"%s",\n', cur_struct.rotate_ccw);
    fprintf(json_fid, '\t\t"rotate_cw":"%s",\n', cur_struct.rotate_cw);
    fprintf(json_fid, '\t\t"forward":"%s",\n', cur_struct.translate_forward);
    fprintf(json_fid, '\t\t"backward":"%s",\n', cur_struct.translate_backward);
    fprintf(json_fid, '\t\t"left":"%s",\n', cur_struct.translate_left);
    fprintf(json_fid, '\t\t"right":"%s"\n', cur_struct.translate_right);


    if(jl<length(image_names))
      fprintf(json_fid,'\t},\n'); 
    else
      fprintf(json_fid,'\t}\n'); 
    end
  end 
  fprintf(json_fid, '}');
  fclose(json_fid);


end%for i, each scene_name

end

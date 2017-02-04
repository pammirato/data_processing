function write_annotations_to_json(scene_name, train)
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

base_path = '/playpen/ammirato/Data/Rohit_COCO_format';
if(train)
  fid = fopen(fullfile(base_path,'train.txt'),'wt');
else
  fid = fopen(fullfile(base_path,'test.txt'),'wt');
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
  
  label_save_path = fullfile(base_path, 'Annotations');
  image_save_path = fullfile(base_path, 'Images');
  if(train)
    label_save_path = strcat(label_save_path,'/train');
    image_save_path = strcat(image_save_path,'/train');
  else
    label_save_path = strcat(label_save_path,'/test');
    image_save_path = strcat(image_save_path,'/test');
  end

  if(~exist(label_save_path, 'dir'))
    mkdir(label_save_path);
  end

  if(~exist(image_save_path, 'dir'))
    mkdir(image_save_path);
  end
  
  %get the path were the .mat files are, and all the file names
  load_path = fullfile(meta_path, LABELING_DIR, label_type, BBOXES_BY_IMAGE_INSTANCE);



%  image_names = image_names(1:3);
  for jl=1:length(image_names)
    cur_image_name = image_names{jl};
    cur_struct = image_structs(jl);
    scene_index = scene_name(end-4:end);
    new_name = strcat(scene_index(2:3), scene_index(end),cur_image_name);
    json_fid = fopen(fullfile(label_save_path, strcat(new_name(1:end-4), '.json')), 'wt');

    box_labels = load(fullfile(load_path,...
                              strcat(cur_image_name(1:10), '.mat')));
    box_labels = box_labels.boxes;
   
    %print start
    fprintf(json_fid, '{\n');
    
    fprintf(json_fid,'\t"%s":[\n', 'annotation');

    bad_inds = find(box_labels(:,5) > 27);
    box_labels(bad_inds,:) = [];
    bad_inds = find(box_labels(:,6) > 3);
    box_labels(bad_inds,:) = [];

    %write bounding boxes
    for kl=1:size(box_labels,1)
      box = box_labels(kl,:);

      fprintf(json_fid,'\t\t{\n');
      fprintf(json_fid,'\t\t\t"bbox": [\n');
      fprintf(json_fid,'\t\t\t\t%d,%d,%d,%d\n\t\t],\n', box(1), box(2), ...
                            box(3)-box(1), box(4)-box(2));
      fprintf(json_fid,'\t\t\t"category_id": %d,\n', box(5));
      fprintf(json_fid,'\t\t\t"is_crowd": %d\n', 0);
      fprintf(json_fid,'\t\t}');
     

      if(kl < size(box_labels,1))
        fprintf(json_fid,',\n');
      else
        fprintf(json_fid,'\n');
      end
    end%for kl

    fprintf(json_fid,'\t],\n');

    
    fprintf(json_fid,'\t"image": {\n');
    fprintf(json_fid,'\t\t"file_name": "%s",\n', new_name);
    fprintf(json_fid,'\t\t"height": "%d",\n', 1080);
    fprintf(json_fid,'\t\t"width": "%d"\n', 1920);

    fprintf(json_fid, '\t}\n');

    fprintf(json_fid, '}');
    fclose(json_fid);

    if(train)  
      fprintf(fid, ['Images/train/' new_name '\n' ...
                    ' ' ...
                    'Annotations/train/' strcat(new_name(1:end-4), '.json')]);

    else
      fprintf(fid, ['Images/test/' new_name '\n' ...
                    ' ' ...
                    'Annotations/test/' strcat(new_name(1:end-4), '.json')]);
    end
  
    copyfile(fullfile(scene_path,'jpg_rgb',cur_image_name), ...
          fullfile(image_save_path,new_name));
  end%for jl, each image


end%for i, each scene_name

fclose(fid);

end

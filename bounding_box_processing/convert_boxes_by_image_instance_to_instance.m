% converts bounding box labels that are organized in a fashion that has one file 
% per image to a format that has one file per instance. It is assummed each file
% for each image has instance labels, not class level labels
%
% It assumed boxes follow the following format:
%
%   [xmin ymin xmax ymax cat_id hardness ...]
%
%   where the first 4 numbers are the coordinates of the box in the image
%   cat_id is the integer ID of the category(instance or class level)
%   hardness is some measure of difficult for detection
%   ... and possible other numbers


%TODO  - is it dumb to reread boxes by image files over and over?

%CLEANED - ish 
%TESTED - ish

clearvars;

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Kitchen_Living_01_2'; %make this = 'all' to run all scenes
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 

label_type = 'verified_labels';  %raw_labels - automatically generated labels
                            %verified_labels - boxes looked over by human
label_loc = 'meta';  %where are the labels located?
                     %meta - in the meta_path
                     %scene - in the scene path


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

%for each scene, do the conversion
for il=1:length(all_scenes)

  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %determine where to look for/save the labels
  label_path = '';
  if(strcmp(label_loc, 'meta'))
    label_path = meta_path;
  else
    label_path = scene_path;
  end

  %where to save the boxes by instance files
  save_path = fullfile(label_path, LABELING_DIR, label_type,...
                         BBOXES_BY_INSTANCE);
  if(~exist(save_path,'dir'))
   mkdir(save_path);
  end

  %get the names of all the instance labels for this scene
  instance_name_to_id_map = get_instance_name_to_id_map();
  instance_names = keys(instance_name_to_id_map);


  %get the names of all the images that have a file for boxes
  labeled_image_names = dir(fullfile(label_path,LABELING_DIR,label_type, ...
                             BBOXES_BY_IMAGE_INSTANCE,'*.mat'));
  labeled_image_names = {labeled_image_names.name};

 
  %store all the labels for each image in cell array 
  image_labels = cell(1,length(labeled_image_names));

  %for each image, load the bounding box labels for that image
  for jl=1:length(labeled_image_names)

    cur_image_name = labeled_image_names{jl};
    cur_file = load(fullfile(label_path, LABELING_DIR, label_type,...
                      BBOXES_BY_IMAGE_INSTANCE, ...
                      strcat(cur_image_name(1:10), '.mat'))); 

    boxes = cur_file.boxes;
    %add the image index to the box for now
    boxes = [boxes repmat(jl, size(boxes,1), 1)];
    image_labels{jl} = boxes;
  end%for jl, each labeled image name

  %remove empty cells(image had no labels)
  image_labels = image_labels(~cellfun('isempty',image_labels)); 

  image_labels = cell2mat(image_labels');

  %for each instance name, get all boxes for the instance and save them
  for jl=1:length(instance_names)

    %get the current intance name and id    
    cur_instance_name = instance_names{jl};
    cur_instance_id = instance_name_to_id_map(cur_instance_name);
    disp(cur_instance_name);%display progress



    %get the boxes and image names for just this instance
    cur_inds = find(image_labels(:,5) == cur_instance_id);
    boxes = image_labels(cur_inds,:);
    image_inds = boxes(:,end);
    boxes = boxes(:,1:end-1); %remove image index
    image_names = cell2mat(labeled_image_names(image_inds)');
    image_names(:,11:end) = repmat('.png', size(image_names,1),1);
    image_names = mat2cell(image_names, repmat(1,1,size(image_names,1)), size(image_names,2));

    if(isempty(image_names))
      continue; %dont save anything if the object is not present in this scene
    end

    %save the newly formatted boxes 
    save(fullfile(save_path, strcat(cur_instance_name,'.mat')), 'image_names', 'boxes');
   end%for jl, each instance name 
end%for i, each scene_name

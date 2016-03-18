%puts one image per instance in a common folder. Purpose is the be the 'reference image'
%for the gather images script. this is a sort of training image for vatic workers  



%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'SN208_Density_1by1'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 

label_box_size = 10;


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

for i=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{i};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);
  
  %make the path for the reference images
  mkdir(fullfile(meta_path,LABELING_DIR,REFERENCE_IMAGES_DIR));

  %holds all image and label names, and label positions in image(preallocate)
  image_names = cell(1,100);
  label_names = cell(1,100);
  label_positions = cell(1,100);
  counter  = 1;

  %get file with all sparse labels 
  fid_sparse = fopen(fullfile(meta_path,LABELING_DIR,DATA_FOR_LABELING_DIR,...
                              ALL_LABELED_POINTS_FILE));
  %make sure file opened
  if(fid_sparse == -1)
    disp(strcat('could not open file for ', scene_name));
  end

  %get header
  fgetl(fid_sparse);  
  fgetl(fid_sparse);  
  fgetl(fid_sparse);  


  %get first line
  line = fgetl(fid_sparse);

  while(ischar(line))
  
    %split into IMAGE_NAME, X, Y, Depth
    line = strsplit(line);

    %store name and poisition
    image_names{counter} = line{1};
    label_positions{counter} = [str2num(line{2}), str2num(line{3})];



    %get the label_name
    line = fgetl(fid_sparse);
    label_names{counter} = line;

    


    counter = counter+1;

    %get the next point
    line = fgetl(fid_sparse);
  end%while ischar line

  %remove empty cells
  image_names = image_names(~cellfun('isempty',image_names));
  label_names = label_names(~cellfun('isempty',label_names));
  label_positions = label_positions(~cellfun('isempty',label_positions));

  %only need one image per label
  %get indices of first occurence of each unique label
  [~,unique_indices,~] = unique(label_names,'first');

  label_names = label_names(unique_indices);
  image_names = image_names(unique_indices);
  label_positions = label_positions(unique_indices);

  %for each label, draw the label dot, and save the reference image
  for j=1:length(label_names)
  
    cur_label_name  = label_names{j};
    cur_image_name = image_names{j};
    cur_label_position = label_positions{j};

    %get jpg name
    cur_image_name = strcat(cur_image_name(1:10), '.jpg');

    %load the jpg image and draw the label dot 
    img = imread(fullfile(scene_path,JPG_RGB,cur_image_name));


      
    %% draw the label dot
    x_dot_min = max(1,floor(cur_label_position(1) - label_box_size/2));
    x_dot_max = min(size(img,2),floor(cur_label_position(1) + label_box_size/2));
    y_dot_min = max(1,floor(cur_label_position(2) - label_box_size/2));
    y_dot_max = min(size(img,1),floor(cur_label_position(2) + label_box_size/2));

    temp =  img(y_dot_min:y_dot_max,x_dot_min:x_dot_max,1);
    img(y_dot_min:y_dot_max,x_dot_min:x_dot_max,1) = 255*ones(size(temp));
    img(y_dot_min:y_dot_max,x_dot_min:x_dot_max,2) = zeros(size(temp));
    img(y_dot_min:y_dot_max,x_dot_min:x_dot_max,3) = zeros(size(temp));



    %% save the img in the reference directory
    imwrite(img,  fullfile(meta_path,LABELING_DIR,REFERENCE_IMAGES_DIR, ...
                            strcat(cur_label_name,'.jpg')));

    end%for j, each unqiue label
end%for each scene



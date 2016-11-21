



%TODO -  %save boxes by instance too?
%       - double  check to see if image already has labels


%CLEANED - no 
%TESTED - no
clearvars;

%initialize contants, paths and file names, etc. 
init;

%% USER OPTIONS

scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 



method = 1;  % 0 - non reconstructed images
             % 1 -  missing boxes check


label_type = 'verified_labels';

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
  scene_name = all_scenes{il}
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  instance_name_to_id_map = get_instance_name_to_id_map();

  if(method == 0)
    %get text file with all non reconstructed names
    fid_names = fopen(fullfile(meta_path, LABELING_DIR, HAND_LABEL_NAMES), 'rt');
  elseif(method == 1)
    fid_names = fopen(fullfile(meta_path, LABELING_DIR, MISSING_BOXES_NAMES), 'rt');
  end%if method

  %get all the non reconstructed, non labeled names
  line = fgetl(fid_names);
  image_names = cell(1,1000);
  counter = 1;
  while(ischar(line))

    image_names{counter} = line;
    counter = counter +1;
    line = fgetl(fid_names); 
  end%while there is another line
  fclose(fid_names);%close file
  %lose empty cells 
  image_names(counter:end) = [];

  %now hand label each image, and save after image is labeled
  for jl=1:length(image_names)

    cur_img_name = image_names{jl};

    rgb_img = imread(fullfile(scene_path, JPG_RGB, strcat(cur_img_name(1:10), '.jpg')));

    hold off;
    imshow(rgb_img); 
    hold on;
    title(cur_img_name);

    if(method == 0)
      cur_boxes = [];  
    elseif(method == 1)
      cur_boxes = load(fullfile(meta_path,LABELING_DIR,label_type, BBOXES_BY_IMAGE_INSTANCE, ...
                       strcat(cur_img_name(1:10),'.mat')));
      cur_boxes = cur_boxes.boxes;

      for kl=1:size(cur_boxes,1)
        bbox = cur_boxes(kl,:);
        rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], ...
                  'LineWidth',4, 'EdgeColor','g');
   
      end%for kl
    end%if method

    but = [1 1];
    
    %keep getting boxes until the user indicates they are done with the image
    %(via two right clicks)
    while(sum(but) == 2)

      %get two mouse clicks for top left and bottom right of box
      [x, y, but] = ginput(2);
      
      if(sum(but)~=2)
        continue;
      end

      %show inputted rectangle on image
      drawn_rect = rectangle('Position',[x(1) y(1) (x(2)-x(1)) (y(2)-y(1))], ...
                  'LineWidth',3, 'EdgeColor','r');
      drawnow;

      inserted_label_name = input('Enter label: ', 's');
      
      valid_input = 0;
      while(~valid_input)
        %allow user to recover from mistake
        if(inserted_label_name == 'q')
          valid_input = 1;
          continue;
        end

        try
          inst_id = instance_name_to_id_map(inserted_label_name);
          valid_input = 1;
          continue;
        catch
          disp('invalid label name');
          inserted_label_name = input('Enter label: ', 's');
          continue;
        end 
        
      end%while valid input

      %skip this box (user made a mistake)
      if(inserted_label_name == 'q')
        delete(drawn_rect)
        continue;
      end
 
      %make sure box coordinates are within image 
      x = floor(x);
      y = floor(y);

      x(1) = max(1,x(1));
      x(2) = min(size(rgb_img,2),x(2));
      y(1) = max(1,y(1));
      y(2) = min(size(rgb_img,1),y(2));
    
      %xmin ymin xmax ymax cat_id hardness
      bbox = [x(1), y(1), x(2), y(2) inst_id 0];

      cur_boxes(end+1,:) = bbox;
    end%while but 
   

    %now save the new annotations 
      %attempt to load the instance label file
      %instance_annotations_file = load(fullfile(scene_path, LABELING_DIR, ...
      %                                 BBOXES_BY_INSTANCE_DIR, ...
      %                                  strcat(inserted_label_name, '.mat')));         
      %                                       'bbox',  bbox)];

    boxes = cur_boxes;
    %save boxes by image instance
    save(fullfile(meta_path,LABELING_DIR,label_type, BBOXES_BY_IMAGE_INSTANCE, ...
                       strcat(cur_img_name(1:10),'.mat')), 'boxes');



    %% overwrite the text file holding images to be labeled, 
    %   effectively removing the image that was just labeled
    if(method == 0)
      fid_names = fopen(fullfile(meta_path, LABELING_DIR, HAND_LABEL_NAMES), 'wt');
    elseif(method == 1)
      fid_names = fopen(fullfile(meta_path, LABELING_DIR, MISSING_BOXES_NAMES), 'wt');
    end 
    for kl=(jl+1):length(image_names)
      fprintf(fid_names, '%s\n', image_names{kl});
    end
    fclose(fid_names);%close file
    
  end%for jl, each image to be labeled 


end%for il, each scene





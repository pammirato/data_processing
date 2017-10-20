function hand_label_images(scene_name, method, label_type)
% allows hand labeling of images in the given scene,
% bounding box labels are created from two mouse clicks, and 
% a label is typed. The images to be and labeled are read from a 
% text file, specificed by method. After each image is labeled,
% it is removed from the list and a new list is written to file.
%
% 
%
%INPUTS:
%         scene_name: char array of single scene name, 'all' for all scenes, 
%                     or a cell array of char arrays, one for each desired scene
%          
%         method: OPTIONAL  0 - use the list of non recontructed images
%                           1(default) - use list of all images(check for missing boxes)
%         label_type: OPTIONAL 'raw_labels'(default) or 'verified_labels'
%
%
%
%
%USAGE:
%    (1) Left-click twice to make a bounding box(top left corner, bottom right corner) Go to (4)
%    (2) If double right click, you are done with this image. Go to (6)
%    (3) If double mouse wheel click, you will be asked to confirm deletetion of
%         any boxes that contain the clicked point. After input, Go to (1)
%    (4) Type a label name to the console. If it is a valid name, the box is recorded. 
%        If it is not a valid name, you be asked to re-enter. 
%        To delete the hand drawn box, Go to (5). If valid name is entered, Go to (1)
%    (5) Enter 'q' as the label name to delete the last hand drawn box. Go to (1)
%    (6) All boxes for this image are saved to file. Load next image, Go to (1)
%    (7) After all boxes are labeled they are converted from image instance to instance
      










%TODO -  %save boxes by instance too?
%       - double  check to see if image already has labels
%       - change click pattern

%CLEANED - no 
%TESTED - ish 

%initialize contants, paths and file names, etc. 
init;

%% USER OPTIONS

%scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


clear_all = 'clear_all';


if(~exist('method','var'))
  method =1;
end
%method = 1;  % 0 - non reconstructed images
             % 1 -  missing boxes check - for checking all images at the end to 
             %improve recall

if(nargin < 3)
  label_type = 'raw_labels';
end
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
 
try%make sure last line is execuuted

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
      try
      cur_boxes = load(fullfile(meta_path,LABELING_DIR,label_type, BBOXES_BY_IMAGE_INSTANCE, ...
                       strcat(cur_img_name(1:10),'.mat')));
      cur_boxes = cur_boxes.boxes;
      drawn_rects = cell(1,size(cur_boxes,1));
      for kl=1:size(cur_boxes,1)
        bbox = cur_boxes(kl,:);
        drawn_rects{kl} = rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], ...
                  'LineWidth',2, 'EdgeColor','g');

        %t = text(bbox(1), bbox(2)-20,num2str(bbox(5)),  ...
        %                            'FontSize',20, 'Color','white');
        %t.BackgroundColor = 'red';
  
      end%for kl
      catch
        cur_boxes = [];
      end
    end%if method

    but = [1 1];
    %keep getting boxes until the user indicates they are done with the image
    %(via two right clicks)
    while(sum(but) == 2)
      %get two mouse clicks for top left and bottom right of box
      [x, y, but] = ginput(2);
      
      if(sum(but) == 3)
        confirm = input('Delete?(y/n): ', 's');
        if(confirm=='y')
          bad_inds = [];
          for ll=1:size(cur_boxes,1)
            if(is_point_in_box(cur_boxes(ll,:),[x(1),y(1)]))
              bad_inds(end+1) = ll;
            end
          end%for ll
          cur_boxes(bad_inds,:) = [];
          rect = drawn_rects{bad_inds};
          delete(rect);
          drawn_rects(bad_inds) = [];
        end%if confirm
        but = [1 1];%so we stay on this image
        continue;
      elseif(sum(but)~=2)
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
        if(all(inserted_label_name == 'q') || strcmp(inserted_label_name,clear_all))
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
      elseif(strcmp(inserted_label_name,clear_all))
        cur_boxes = []; 
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
    
    %convert_boxes_by_image_instance_to_instance(scene_name,label_type);
  end%for jl, each image to be labeled 


  convert_boxes_by_image_instance_to_instance(scene_name,label_type);
  catch
  end
  convert_boxes_by_image_instance_to_instance(scene_name,label_type);

end%for il, each scene


end %function

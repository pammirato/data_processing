%shows bounding boxes by image, with many options.  Can view vatic outputted boxes,
%results from a recognition system, or both. Also allows changing of vatic boxes. 

%TODO  - add scores to rec bboxes
%      - add labels to rec bboxes
%      - move picking labels to show outside of loop
%      - add ability to hand alter vatic output

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'SN208_Density_2by2_same_chair'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


show_vatic_output = 1;
vatic_label_to_show = 'all'; 
use_custom_vatic_labels = 0;
custom_vatic_labels = {};


show_recognition_output = 0;
recognition_system_to_show = 'results_fast_rcnn';
recognition_label_to_show = 'chair';
use_custom_recognition_labels = 0;
custom_recognition_labels = {};
score_threshold = .1;




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


  %get the image structs and make a map
  image_structs_file = load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.image_structs;
  temp = cell2mat(image_structs);
  structs_names = {temp.image_name}; 
  image_structs_map = containers.Map(structs_names, image_structs);


  %get all image names
  image_names = get_names_of_X_for_scene(scene_name,'rgb_images'); 

  %requires  image sturcts map - image name to image struct
  %          image_names  - cell array of all image names

  cur_image_index = 1;
  cur_image_name  = image_names{cur_image_index};
  cur_image_struct =  image_structs_map(cur_image_name);
  move_command = 'w';

  while(cur_image_index <= length(image_names)) 


    %display stuff
    hold off;
    rgb_image = imread(fullfile(scene_path,RGB,cur_image_name));
    imshow(rgb_image);
    hold on;
    
    %draw vatic bounding boxes
    if(show_vatic_output)

      vatic_bboxes = load(fullfile(scene_path,LABELING_DIR, ...
                          BBOXES_BY_IMAGE_INSTANCE_DIR, strcat(cur_image_name(1:10),'.mat')));



      %decide which instances to show
      if(use_custom_vatic_labels && ~isempty(custom_vatic_labels))
        labels_to_show = custom_vatic_labels;
      elseif(strcmp(vatic_label_to_show,'all'))
        labels_to_show = fields(vatic_bboxes);
      else
        labels_to_show = {vatic_label_to_show};
      end%decide which instances to show

      for k=1:length(labels_to_show)
        bbox = vatic_bboxes.(labels_to_show{k});
  
        rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], ...
                     'LineWidth',2, 'EdgeColor','r');
      end%for k, each label to show
    end%if show vatic output



    %now draw recognition boxes
    if(show_recognition_output)

      recognition_bboxes = load(fullfile(meta_path,RECOGNITION_DIR, ...
                                        recognition_system_to_show , ...
                                 strcat(cur_image_name(1:10), '.mat')));

      recognition_bboxes = recognition_bboxes.dets;

      if(use_custom_recognition_labels && ~isempty(custom_recognition_labels))
        labels_to_show = custom_recognition_labels;
      elseif(strcmp(vatic_label_to_show,'all'))
        labels_to_show = fields(recognition_bboxes);
      else
        lables_to_show = recgontion_label_to_show;
      end 


      for k=1:length(labels_to_show)
        bboxes = recognition_bboxes.(labels_to_show{k});
        bboxes = bboxes(bboxes(:,5) > score_threshold,:);

        for l=1:size(bboxes,1)
          bbox = bboxes(l,:);
          rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], ...
                     'LineWidth',1, 'EdgeColor','b');
        end%for l, each bbox
     
      end%for k, each label to show 
    end%if show recognition_output








    %get user input
    move_command = input('Enter move command: ', 's');

    if(move_command == 'q')
        disp('quiting...');
        break;

    elseif(move_command =='w')
        %move forward 
        next_image_name = cur_struct.translate_forward;
        cur_image_index = str2num(next_image_name(1:6));

    elseif(move_command =='s')
        %move backward 
        next_image_name = cur_struct.translate_backward;
        cur_image_index = str2num(next_image_name(1:6));
    
    elseif(move_command =='d')
        %rotate clockwise
        next_image_name = cur_struct.rotate_cw;
        cur_image_index = str2num(next_image_name(1:6));
    elseif(move_command =='a')
        %rotate counter clockwise 
        next_image_name = cur_struct.rotate_ccw;
        cur_image_index = str2num(next_image_name(1:6));

    elseif(move_command =='n')
        %go forward one image 
        cur_image_index = cur_image_index+1;  
   
    elseif(move_command =='p')
        %go backward one image 
        cur_image_index = cur_image_index-1;

    elseif(move_command =='m')
        %let the user decide how much to go(forward or back) 
        num_to_move = input('How many images to move: ', 's');
        num_to_move = str2num(num_to_move);
        
        cur_image_index = cur_image_index + num_to_move;
    elseif(move_command =='f')
        %move forward 50 iamges
        cur_image_index = cur_image_index + 50;
    elseif(move_command =='g')
        %move forward 100 images
        cur_image_index = cur_image_index + 100;
    elseif(move_command =='h')
      disp('help: ');

      disp('	q  - to quit and save labels so far ');
      disp('	w  - move forward ');
      disp('	s  - move backward ');
      disp('	d  - rotate clockwise');
      disp('	a  - roatate counter clockwise ');
      disp('	n  - go to the next image ');
      disp('	p  - go to the previous image  ');
      disp('	m  - move some number of images,  ');
      disp('		enter the number of images after typing m  and hitting enter once ');
      disp('	f  - move foward 50 images ');
      disp('	g  - move forward 100 images ');
    end    


    if(cur_image_index < 1)
      cur_image_index = 1;
    elseif(cur_image_index > length(image_names))
      cur_image_index = length(image_names);
    end

    cur_image_name = image_names{cur_image_index};
    cur_image_struct = image_structs_map(cur_image_name);

  end %while cur_image_index < 







end%for each scene



%shows bounding boxes by image, with many options.  Can view vatic outputted boxes,
%results from a recognition system, or both. Also allows changing of vatic boxes. 

%TODO  - add scores to rec bboxes
%      - add labels to rec bboxes
%      - move picking labels to show outside of loop

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Home_14_1'; %make this = 'all' to run all scenes

%group_name = 'all_minus_boring';
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


%OPTIONS for ground truth bounding boxes
show_vatic_output = 1; %
vatic_label_to_show = 'all'; 
use_custom_vatic_labels = 0;
custom_vatic_labels = {'chair1','chair2','chair3','chair4','chair5','chair6'};


%options for FAST-RCNN bounding boxes
show_recognition_output = 0;
recognition_system_name = 'ssd_bigBIRD';
show_instance_not_class = 1;
recognition_label_to_show = 'crystal_hot_sauce';
use_custom_recognition_labels = 0;
custom_recognition_labels = {};
score_threshold = .1;
show_scores_of_boxes = 1;
show_class_of_boxes = 0;
font_size = 10;
line_width = 2;


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
 % image_structs_file = load(fullfile(meta_path,IMAGE_STRUCTS_FILE));
 % image_structs = image_structs_file.image_structs;
 % temp = image_structs;
 % structs_names = {temp.image_name}; 
 % image_structs_map = containers.Map(structs_names, image_structs);

  image_structs_file =  load(fullfile(meta_path,'reconstruction_results',  ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  image_structs = nestedSortStruct2(image_structs, 'image_name');
  scale  = image_structs_file.scale;


  %get a list of all the image file names
  %temp = cell2mat(image_structs);
  %image_names = {temp.(IMAGE_NAME)};
  image_names = {image_structs.(IMAGE_NAME)};

  %make a map from image name to image_struct
  %image_structs_map = containers.Map(image_names, image_structs);


  image_structs_map = containers.Map(image_names,...
                                 cell(1,length(image_names)));

  for jl=1:length(image_names)
    image_structs_map(image_names{jl}) = image_structs(jl);
  end









  %get all image names
 % image_names = get_names_of_X_for_scene(scene_name,'rgb_images'); 

  %requires  image sturcts map - image name to image struct
  %          image_names  - cell array of all image names

  f = figure();
  cur_image_index = 1;
  cur_image_name  = image_names{cur_image_index};
  cur_image_struct =  image_structs_map(cur_image_name);
  %cur_image_struct =  image_structs_map(strcat(cur_image_name(1:10), '.jpg'));
  move_command = 'w';
  num_to_play = 0;%images to play in a movie
  while(cur_image_index <= length(image_names)) 

%display stuff
    hold off;
    rgb_image = imread(fullfile(scene_path,RGB,cur_image_name));
    imshow(rgb_image);
    hold on;
    try
      %depth_image = imread(fullfile(scene_path,'high_res_depth', ...
      %                      strcat(cur_image_name(1:8), '03.png')));
      depth_image = imread(fullfile(meta_path,'improved_depths', ...
                            strcat(cur_image_name(1:8), '05.png')));
      %h = imagesc(depth_image);
      %set(h,'AlphaData', .5);
    catch 
    end

    title(cur_image_name);
    
    %draw vatic bounding boxes
    if(show_vatic_output)

      
      try
      %vatic_bboxes = load(fullfile(scene_path,LABELING_DIR, ...
      %                    BBOXES_BY_IMAGE_INSTANCE_DIR, strcat(cur_image_name(1:10),'.mat')));
      %vatic_bboxes = load(fullfile(meta_path,LABELING_DIR, ...
      %                     'instance_label_structs', strcat(cur_image_name(1:10),'.mat')));
      vatic_bboxes = load(fullfile(meta_path,LABELING_DIR, ...
                           'verified_labels','bounding_boxes_by_image_instance', ...
                             strcat(cur_image_name(1:10),'.mat')));
      catch
        vatic_bboxes =struct();
      end

      if(~isempty(fields(vatic_bboxes)))

      %decide which instances to show
      if(use_custom_vatic_labels && ~isempty(custom_vatic_labels))
        labels_to_show = custom_vatic_labels;
      elseif(strcmp(vatic_label_to_show,'all'))
        labels_to_show = fields(vatic_bboxes);
      else
        labels_to_show = {vatic_label_to_show};
      end%decide which instances to show

      for k=1:length(labels_to_show)
        if(strcmp(labels_to_show{k}, 'image_name'))
          continue;
        end
        bbox = double(vatic_bboxes.(labels_to_show{k}));
        if(isempty(bbox))
          continue;
        end  
        rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], ...
                     'LineWidth',line_width, 'EdgeColor','r');
        %t = text(bbox(1), bbox(2)-font_size,labels_to_show{k},  ...
       %                             'FontSize',font_size, 'Color','white');
       % t.BackgroundColor = 'red';
      end%for k, each label to show
      end%if vatic is not empty
    end%if show vatic output


      %vatic_bbox = bbox;

    %now draw recognition boxes
    if(show_recognition_output)

      if(show_instance_not_class)
        try
        recognition_bboxes = load(fullfile(meta_path,RECOGNITION_DIR, ...
                                          recognition_system_name , ...
                                          BBOXES_BY_IMAGE_INSTANCE_DIR, ...
                                   strcat(cur_image_name(1:10), '.mat')));
        catch
          recognition_bboxes = struct();
        end
      else
        try
        recognition_bboxes = load(fullfile(meta_path,RECOGNITION_DIR, ...
                                          recognition_system_name , ...
                                          BBOXES_BY_IMAGE_CLASS_DIR, ...
                                    strcat(cur_image_name(1:10), '.mat')));
        catch
          recognition_bboxes = struct();
        end
       end


      if(use_custom_recognition_labels && ~isempty(custom_recognition_labels))
        labels_to_show = custom_recognition_labels;
      elseif(strcmp(recognition_label_to_show,'all'))
        labels_to_show = fields(recognition_bboxes);
      else
        labels_to_show = {recognition_label_to_show};
      end 


      for k=1:length(labels_to_show)
        if(isempty(fieldnames(recognition_bboxes)))
          continue;
        end
        bboxes = recognition_bboxes.(labels_to_show{k});

        %if thes are detections, threshold on score
        if(size(bboxes,2) > 4)
          bboxes = bboxes(bboxes(:,5) > score_threshold,:);
        end

        %ious = get_bboxes_iou(vatic_bbox, bboxes);
        %bboxes = bboxes(ious > .5, :);

        for l=1:size(bboxes,1)
          bbox =double(bboxes(l,:));
          if(isempty(bbox))
            continue;
          end  
          

          rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], ...
                     'LineWidth',line_width, 'EdgeColor','r');
          if(show_scores_of_boxes)
            t = text(bbox(1) - (bbox(3)-bbox(1)), bbox(2)-font_size,...
                                    sprintf('%1.3f', bbox(5)),  ...
                                    'FontSize',font_size, 'Color','black');

            t.BackgroundColor = 'red';
          end
          if(show_class_of_boxes)
            t = text(bbox(3)-20, bbox(2)+font_size,labels_to_show{k},  ...
                                    'FontSize',font_size, 'Color','black');

            t.BackgroundColor = 'red';
          end

        end%for l, each bbox
     
      end%for k, each label to show 
    end%if show recognition_output








    %get user input command if a video is not playing
    if((num_to_play == 0))
      move_command = input('Enter move command: ', 's');
    end

    if(move_command == 'q')
        disp('quiting...');
        break;

    elseif(move_command =='w')
        %move forward 
        next_image_name = cur_image_struct.translate_forward;
        if(next_image_name == -1)
          next_image_name = cur_image_name;
        end
        cur_image_index = str2num(next_image_name(1:6));
    elseif(move_command =='y')
        %move forward 
        next_image_name = cur_image_struct.translate_left;
        if(next_image_name == -1)
          next_image_name = cur_image_name;
        end
        cur_image_index = str2num(next_image_name(1:6));
    elseif(move_command =='u')
        %move forward 
        next_image_name = cur_image_struct.translate_right;
        if(next_image_name == -1)
          next_image_name = cur_image_name;
        end
        cur_image_index = str2num(next_image_name(1:6));

    elseif(move_command =='s')
        %move backward 
        next_image_name = cur_image_struct.translate_backward;
        cur_image_index = str2num(next_image_name(1:6));
        if(next_image_name == -1)
          next_image_name = cur_image_name;
        end
    
    elseif(move_command =='d')
        %rotate clockwise
        next_image_name = cur_image_struct.rotate_cw;
        cur_image_index = str2num(next_image_name(1:6));
        if(next_image_name == -1)
          next_image_name = cur_image_name;
        end
    elseif(move_command =='a')
        %rotate counter clockwise 
        next_image_name = cur_image_struct.rotate_ccw;
        cur_image_index = str2num(next_image_name(1:6));
        if(next_image_name == -1)
          next_image_name = cur_image_name;
        end

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
    elseif(move_command =='l')
        %move forward 100 images
        %saveas(f, fullfile('/playpen/ammirato/Pictures/icra_2016_figures/', ...
        %  strcat(cur_image_name(1:10), recognition_label_to_show, '.png'))); 
        set(gcf,'inverthardcopy','off');

        print(fullfile('/playpen/ammirato/Pictures/icra_2016_figures/images_to_agg', ...
          strcat(cur_image_name(1:10), recognition_label_to_show, '.png')), '-dpng'); 

    elseif(move_command =='v')
      %play a video of X images
      
      if(num_to_play == 0)%if we are not already playing a video
        num_to_play_s = input('How many images to play: ', 's');
        num_to_play = str2num(num_to_play_s);
      else
        num_to_play = num_to_play -1;
        cur_image_index = cur_image_index +1;
        pause(.1);
      end

    elseif(move_command =='i')
        %insert a new label or replace an old one

        %make sure ground truth boxes are being show
        if(~show_vatic_output)
          disp('must be showing vatic ouput to add or replace boxes')
          continue;
        end

        %get two mouse clicks for top left and bottom right of box
        [x, y, but] = ginput(2);

        inserted_label_name = input('Enter label: ', 's');
  
        %allow user to recover from mistake
        if(inserted_label_name == 'q')
          continue;
        end
     
        %make sure box coordinates are within image 
        x = floor(x);
        y = floor(y);

        x(1) = max(1,x(1));
        x(2) = min(size(rgb_image,2),x(2));
        y(1) = max(1,y(1));
        y(2) = min(size(rgb_image,1),y(2));

        bbox = [x(1), y(1), x(2), y(2)];
       
        
        %update bbox by instance annotations
        try 
          %attempt to load the instance label file
          instance_annotations = load(fullfile(meta_path, LABELING_DIR, ...
                                           'verified_labels', BBOXES_BY_INSTANCE_DIR, ...
                                            strcat(inserted_label_name, '.mat')));         

          %instance_annotations = instance_annotations_file.annotations;


%           if(isempty(instance_annotations))
%             instance_annotations = [struct('image_name', cur_image_name, ...
%                                                 'bbox',  bbox)];
%           else
%             %add the new label
%             instance_annotations(end+1)  = struct('image_name', cur_image_name, ...
%                                                 'bbox',  bbox);
%           end
%                                               
%           %save the new annotations
%           annotations = instance_annotations;
%           save(fullfile(meta_path, LABELING_DIR,'verified_labels',BBOXES_BY_INSTANCE_DIR, ...
%                        strcat(inserted_label_name, '.mat')), 'annotations');         


          image_names = instance_annotations.image_names;
          image_names{end+1} = cur_image_name;
          %instance_annotations.image_names = image_names;
          
          boxes = instance_annotations.boxes;
          boxes{end+1} = bbox;
          %instance_annotations.bboxes = bboxes;
          
           save(fullfile(meta_path, LABELING_DIR,'verified_labels',BBOXES_BY_INSTANCE_DIR, ...
                        strcat(inserted_label_name, '.mat')), 'image_names', 'boxes');
        catch
          disp('not a valid label name!');
          continue;
        end
       
        %update bbox by image instance annotations 
        %add the bbox to the current boxes
        vatic_bboxes.(inserted_label_name) = bbox; 
         
        save(fullfile(meta_path,LABELING_DIR,'verified_labels',BBOXES_BY_IMAGE_INSTANCE_DIR, ...
                           strcat(cur_image_name(1:10),'.mat')), '-struct', 'vatic_bboxes');




        
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
    cur_image_struct =  image_structs_map(cur_image_name);
    %cur_image_struct =  image_structs_map(strcat(cur_image_name(1:10), '.jpg'));

  end %while cur_image_index < 







end%for each scene



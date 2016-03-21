%propogates labels from vatic output to all other images 
%assumes all images without both forward and backward pointers have been labeled

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'all'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


label_name = 'all';%make this 'all' to do it for all labels, 'bigBIRD' to do bigBIRD stuff
use_custom_labels = 0;
custom_labels = {};

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


  %get image structs, image_names, and make a map
  image_structs_file = load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  temp = cell2mat(image_structs_file.image_structs);
  all_image_names = {temp.image_name};
  camera_structs_map = containers.Map(all_image_names, image_structs_file.image_structs); 


  %% for label, propogate it throughout the scene
  for j=1:length(




end%for each scene































init;


density = 1;
%the scene and instance we are interested in
scene_name = 'SN208_3';

%any of the fast-rcnn categories
instance_name = 'chair1'; %make this 'all' to see all categories

score_threshold = .1;

scene_path = fullfile(BASE_PATH,scene_name);
if(density)
    scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
end




%% load data for scene

%camera structs for all images in the scene
camera_structs_file = load(fullfile(scene_path,RECONSTRUCTION_DIR,NEW_CAMERA_STRUCTS_FILE));

camera_structs_mat = cell2mat(camera_structs_file.camera_structs);

all_image_names = {camera_structs_mat.image_name};

%load turk annotation data
temp = load(fullfile(scene_path,LABELING_DIR,'turk_boxes',strcat(instance_name, '.mat')));
turk_annotations = cell2mat(temp.annotations);

%% create some data structures to access loaded data
camera_structs_map = containers.Map(all_image_names, camera_structs_file.camera_structs);
all_labels_map  = containers.Map(all_image_names, cell(1,length(all_image_names)));




%% put in the turk labels
for i=1:length(turk_annotations)
  cur_annotation = turk_annotations(i);
  cur_image_name = cur_annotation.frame;

  cur_turk_box = [cur_annotation.xtl, cur_annotation.ytl, ...
                    cur_annotation.xbr, cur_annotation.ybr];

  all_labels_map(cur_image_name) =  cur_turk_box;
end








%% MAIN LOOP

%for each image that doesn't have a label, 
% find two images that do have a label and form a straightish line with the unlabeled image.
% interpolate the labels

for i=1:length(all_image_names)

  cur_image_name = all_image_names{i};

  %% see if the image has been labeled yet.
  already_labeled_flag = 1;
  temp = all_labels_map(cur_image_name);

  if (length(temp) == 0)
    already_labeled_flag = 0; 
  end

  if (already_labeled_flag)
    continue; 
  end


  %% get the current image data ready
  cur_camera_struct = camera_structs_map(cur_image_name);
%   cur_direction = cur_camera_struct.direction;
%   cur_dir_normed = cur_direction/ norm(cur_direciton);
%   cur_scaled_pos = cur_camera_struct.scaled_world_position;
  
  %% now find two images with labels, i1,i2, such that the positions of 
   % i1,i2 ,and the current image approixmately form a line.
   % also they must all be facing approximately the same direction
  

  %first find all the labeled points with the same direction
  for j=1:length(turk_labeled_mat_names)
    cur_turk_mat_name = turk_labeled_mat_names{j};
    cur_turk_image_name = strcat(cur_turk_mat_name(1:10), '.png');      

    cur_turk_camera_struct  = camera_structs_map(cur_turk_image_name);
   % cur_turk_direction = cur_turk_camera_struct.direction;
   % cur_turk_dir_normed
   
   dir_angle = angle_between_directions_2D(cur_camera_struct, cur_turk_camera_struct);
   


  end%for j, each turk_labled mat   
  



end%for i, each image name,  MAIN LOOP





















save_dir = 'boxes_per_image';
image_names = dir(fullfile(scene_path,RGB_IMAGES_DIR,'*0101.png'));
image_names = {image_names.name};






 for i=1:length(image_names) 

    index = 21*(floor((i-1)/3)) +  mod((i-1)+3,3)*10 +1 ;
     
    save_changes = 0;
    
    rgb_name = image_names{index};
    rgb_image = imread(fullfile(scene_path,RGB_IMAGES_DIR,rgb_name));
    
    imshow(rgb_image);
    
    title(rgb_name);
    
    anns_exist = 1;
    
    rec_name = strcat(rgb_name(1:10),'.mat');
    
    try
        anns = load(fullfile(scene_path,'labeling',save_dir,rec_name));
    catch
        anns_exist = 0;
        anns = struct();
    end
    
    if(anns_exist)
        categories = fields(anns);

        for k=1:length(categories)
            bbox = anns.(categories{k});
            rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');

    %         text(bbox(1), bbox(2)-font_size,strcat(num2str(bbox(5)),cur_label),  ...
    %                                 'FontSize',font_size, 'Color','white');

        end%for k      
    end
%         if(length(dets_to_show) > 0)
%             dets_to_show = cat(1,dets_to_show,cur_dets);
%         else
%             dets_to_show = cur_dets;
%         end

    
    
    [x, y, but] = ginput(1);
    
    if(but~=1)
        save_changes = 1;
        
        done = 0;
        while(but~=1  && ~done)
        
            [x, y, ~] = ginput(2);
            
            label_name = input('Enter label: ', 's');
            
            if(label_name == 'q')
                done = 1;
                continue;
            end

            x = floor(x);
            y = floor(y);
            
            x(1) = max(1,x(1));
            x(2) = min(size(rgb_image,2),x(2));
            y(1) = max(1,y(1));
            y(2) = min(size(rgb_image,1),y(2));

            bbox = [x(1), y(1), x(2), y(2)];
            rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
            
            

            anns.(label_name) = bbox;
            
            [x, y, but] = ginput(1);
        end%whjile
        
        
        
    end%if but
%     ch = getkey();
%     if(ch == 'q')
%         break;
%     end
    hold off;
    
    if(save_changes)
        annotations = anns;
        save(fullfile(scene_path,'labeling',save_dir,rec_name),'-struct','annotations');
    end
    
    
%     if(done)
%         break;
%     end
    
 end%fior i, each image name


    
    


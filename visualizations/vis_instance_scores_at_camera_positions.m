
%initialize contants, paths and file names, etc. 
clearvars;
init;



%% USER OPTIONS

scene_name = 'Kitchen_Living_02_1'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 1;%whether or not to run for the scenes in the custom list
%custom_scenes_list = {'FB209_den1', 'SN208_den1', 'SN208_den2', ...
%    'Kitchen_Living_02_1_vid_1','Kitchen_Living_02_1_vid_2','Kitchen_Living_02_1_vid_3' };%populate this 
custom_scenes_list = {'Bedroom_01_1', 'Kitchen_Living_02_1' };%populate this 
%custom_scenes_list = {'Den_den2', 'Den_den3','Den_den4' };%populate this 


recognition_system_name = 'ssd_bigBIRD';


instance_name = 'all';%make this 'all' to do it for all labels, 'bigBIRD' to do bigBIRD stuff
use_custom_instances = 0;
custom_instances_list = {'coca_cola_glass_bottle', 'crystal_hot_sauce'};




show_figures = 1;
save_figures = 1;
save_results = 1;

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

f = figure(); 
colors = colormap(jet);
% colors = colormap(parula);
% colors = colors(end:-1:1,:);
colors = colors(33:end,:);
colormap(colors);

%% MAIN LOOP

for i=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{i};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %get all the instance labels in this scene
  all_instance_names = get_names_of_X_for_scene(scene_name, 'instance_labels');



   %decide which labels to process    
  if(use_custom_instances && ~isempty(custom_instances_list))
    all_instance_names = custom_instances_list;
  elseif(strcmp(instance_name,'bigBIRD'))
    temp = dir(fullfile(BIGBIRD_BASE_PATH));
    temp = temp(3:end);
    all_instance_names = {temp.name};
  elseif(strcmp(instance_name, 'all'))
    all_instance_names = all_instance_names;
  else
    all_instance_names = {instance_name};
  end


  %load image_structs for all images
  image_structs_file =  load(fullfile(meta_path, 'reconstruction_results', ...
                                group_name, 'colmap_results', ...
                                model_number, IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;

  %get a list of all the image file names
  image_names = {image_structs.(IMAGE_NAME)};

  %make a map from image name to image_struct
  image_structs_map = containers.Map(image_names,...
                                 cell(1,length(image_names)));
  %populate the map
  for jl=1:length(image_names)
    image_structs_map(image_names{jl}) = image_structs(jl);
  end


  %get all the image names in the scene
  all_image_names = get_names_of_X_for_scene(scene_name,'rgb_images'); 

  
  instance_images_map = containers.Map(all_instance_names, cell(1,length(all_instance_names)));

  
  for j=1:length(all_instance_names)
   
    cur_instance_name = all_instance_names{j};
    plot_index = 0;
    if(strcmp(scene_name, 'Bedroom_01_1'))
      if(strcmp(cur_instance_name, 'nature_valley_sweet_and_salty_nut_roasted_mix_nut'))
        plot_index = 1;
      elseif(strcmp(cur_instance_name, 'coca_cola_glass_bottle'))
        plot_index = 2;
      else
        continue;
      end
    end
    
    if(strcmp(scene_name, 'Kitchen_Living_02_1'))
      if(strcmp(cur_instance_name, 'crystal_hot_sauce'))
        plot_index = 3;
      elseif(strcmp(cur_instance_name, 'nature_valley_granola_thins_dark_chocolate'))
        plot_index = 4;
      else
        continue;
      end
    end


    try
    %load all detections for this instance
    detections_file = load(fullfile(meta_path, RECOGNITION_DIR, ...
                                       recognition_system_name, BBOXES_BY_INSTANCE_DIR, ...
                                      strcat(cur_instance_name, '.mat')));
    catch
      continue;
    end
                                    
    cur_instance_pc = pcread(fullfile(meta_path, 'labels', 'object_point_clouds',...
                                strcat(cur_instance_name, '.ply')));
                              
    cur_instance_loc = median(cur_instance_pc.Location)*scale;
    
     
    all_detections_for_instance = detections_file.detections;
    

    %f = figure(); 
    ax(plot_index) = subplot(2,2,plot_index);
    
    
    
    
%     f = figure(); 
%     colors = colormap(jet);
%     % colors = colormap(parula);
%     % colors = colors(end:-1:1,:);
%     colors = colors(33:end,:);
%     colormap(colors);
    
    plot(cur_instance_loc(1), cur_instance_loc(3), 'md', 'MarkerSize', 10, ...
                  'Color', [1 0 1], 'MarkerFaceColor', [1 0 1]);
    
    hold on;
    for k=1:length(all_detections_for_instance)

      cur_detection = all_detections_for_instance(k);

    
      cur_image_name = cur_detection.image_name;
      bbox = cur_detection.bbox;
      if(bbox(5) > 0)
        breakp=1;
      end
      
      cur_image_struct = image_structs_map(cur_image_name);
      
      cam_pos = cur_image_struct.world_pos*scale;
      
      plot(cam_pos(1), cam_pos(3), '.','MarkerSize', 20, 'Color', colors(floor(bbox(5)*(length(colors)-1) + 1), :));
 
    end
    title_string = cur_instance_name;
    title_string(strfind(title_string, '_')) = ' ';
    space_inds = strfind(title_string, ' ');
    if(length(space_inds) > 2)
      title_string = sprintf('%s\n%s', title_string(1:space_inds(3)-1), ...
                                       title_string(space_inds(3)+1:end));
    end
    %title([title_string ' (at red diamond)']);
    title(title_string, 'FontSize', 8);
    
    %xlabel('Camera Position(mm)');
    %ylabel('Camera Position(mm)');
%     if(plot_index == 1 || plot_index == 3)
%     xlabel('Position(mm)');
%     ylabel('Position(mm)');
%     end
    %h = colorbar;
    %ylabel(h, 'Detection Score');
    
    if(plot_index < 3)
      axis([-2500 2500 -2500 2500]);
    else
      axis([-4000 4000 -3000 2500]);
    end
    axis equal;
    hold off;
    
%     saveas(f, fullfile('/playpen/ammirato/Pictures/icra_2016_figures', ...
%           strcat(scene_name, cur_instance_name, '.jpg')));
    
  end%for j, each instance_name


end%for each scene


h = colorbar;
ylabel(h, 'Detection Score');
set(h, 'Position', [.89 .1 .05 .83]);

yl = ylabel('Position(mm)');
xl = xlabel('Position(mm)');

set(yl,'Position', [-16500 4500]);
set(xl,'Position', [-6000 -4200]);

set(yl,'FontSize', 20);
set(xl, 'FontSize', 20);

for il=1:length(ax)
  pos = get(ax(il), 'Position');
  if(il < 3)
  set(ax(il), 'Position', [.95*pos(1) .9*pos(2) 1.07*pos(3), pos(4)]);
  else
     set(ax(il), 'Position', [.95*pos(1) pos(2) 1.07*pos(3), pos(4)]);
  end
end

set(ll, 'Position', [pos(1) .93 .2 .02]);


if(~show_figures)
  close all;
end

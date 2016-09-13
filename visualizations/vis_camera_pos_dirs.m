%show a figure with the camera positions plotted in 3D for a scene, 
%possibly also show a line coming from each point indicating the 
%orientation of the camera at that point


%TODO:     - add option to plot reconstructed points, and save those figs/images
%          - add option to list image names next to points(or click point and get image name)           


%initialize contants, paths and file names, etc. 
init;





%% USER OPTIONS

scene_name = 'Kitchen_05_1'; %make this = 'all' to run all scenes
group_name = 'all';
group_name = 'all_minus_boring';
model_number = '0';
use_custom_scenes = 1;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'Kitchen_Living_02_1','Kitchen_Living_08_1','Bedroom_01_1','Office_01_1', 'Kitchen_05_1'} ;%populate this 
custom_scenes_list = {'Kitchen_Living_01_1','Kitchen_Living_03_1','Kitchen_Living_03_2','Kitchen_Living_04_2','Kitchen_Living_06'};%populate this 



view_direction = 1;%should the lines indicating camera direction be drawn?


plot_type = 1; %  0 - 3D point plot 
               %  1 - 2D point plot
save_figures = 2; % 0 - don't save
                  % 1 - save .fig file
                  % 2 - save .jpg image



view_figure = 1; %whether or not to make the figure(s) visible

use_scaled_positions = 0;%use positions in meters, not arbitrary reconstruction coords

show_image_names = 1;


%% SET UP DATA STRUCTURES


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

  %file that has postions and other meta data for each image 
  try
    %image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
    image_structs_file =  load(fullfile(meta_path,'reconstruction_results',group_name, 'colmap_results',model_number,IMAGE_STRUCTS_FILE));
  catch
    disp(strcat('No image structs file: ', scene_name));
    continue;
  end

  %image_structs = cell2mat(image_structs_file.(IMAGE_STRUCTS));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale = image_structs_file.scale;
  %get positions and directions of camera for each image
  if(use_scaled_positions)
    world_poses = [image_structs.world_pos]*scale; 
  else
    world_poses = [image_structs.world_pos];
  end


  directions = [image_structs.direction];

  %make figure invisible if option is set
  if(view_figure)
    positions_plot_fig = figure;
  else 
    positions_plot_fig = figure('Visible', 'off');
  end

 
  %% plot  sutff 

  % plot positions 
  switch plot_type
    case 0 %use 3D plot
      plot3(world_poses(1,:),world_poses(2,:), world_poses(3,:),'r.');
    case 1 % make plot just 2D
      plot(world_poses(1,:),world_poses(3,:),'r.');
  end 

  %makes plot prettier
  axis equal;

  %plot direction arrows if option is set
  if(view_direction)
      hold on;

      switch plot_type
        case 0 %3D plot
          quiver3(world_poses(1,:),world_poses(2,:),world_poses(3,:), ...
             directions(1,:),directions(2,:),directions(3,:), ...
             'ShowArrowHead','off','Color' ,'b');
        case 1  %2D plot
          quiver(world_poses(1,:),world_poses(3,:), ...
             directions(1,:),directions(3,:), ...
             'ShowArrowHead','on','Color' ,'b');
      end%switch
      hold off;
  end%if view_direction

  %% save stuff

  %if we are saving
  if(save_figures ~= 0)
    
    %make a suffix to add to the file name to indicate the plot type
    plot_type_suffix = '';
    switch plot_type
      case 0
        plot_type_suffix = '3D';
      case 1
        plot_type_suffix = '2D';
    end

    % file name, indicates what we are saving
    file_prefix = 'camera_pos_';
    if(view_direction)
      file_prefix = 'camera_pos_dir_';
    end

    %% save the figure if option is set
    switch save_figures
      case 1
        savefig(fullfile(meta_path,RECONSTRUCTION_DIR, ...
                strcat(file_prefix, plot_type_suffix, '.fig')));
      case 2
        %saveas(positions_plot_fig, fullfile(meta_path,RECONSTRUCTION_DIR, ...
        %         strcat(file_prefix, plot_type_suffix, '.jpg')));
        saveas(positions_plot_fig, fullfile('/playpen/ammirato/Data/cam_pos_dirs/', ...
                 strcat(scene_name, file_prefix, plot_type_suffix, '.jpg')));
    end


  end %if save_figures ~= 0

  % close the figure if we are not viewing it
  if(~view_figure)
    close(positions_plot_fig)
  end
end%for each scene



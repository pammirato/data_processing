%show a figure with the camera positions plotted in 3D for a scene, 
%possibly also show a line coming from each point indicating the 
%orientation of the camera at that point

%initialize contants, paths and file names, etc. 
init;





%% USER OPTIONS

scene_name = 'all'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


view_direction = 0;%should the lines indicating camera direction be drawn?


plot_type = 1; %  0 - 3D point plot 
               %  1 - 2D point plot

save_figures = 2; % 0 - don't save
                  % 1 - save .fig file
                  % 2 - save .jpg image



view_figure = 0; %whether or not to make the figure(s) visible

use_scaled_positions = 1;%use positions in meters, not arbitrary reconstruction coords




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
    image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  catch
    disp(strcat('No image structs file: ', scene_name));
    continue;
  end

  image_structs = cell2mat(image_structs_file.(IMAGE_STRUCTS));

  %get positions and directions of camera for each image
  if(use_scaled_positions)
    world_poses = [image_structs.scaled_world_pos]; 
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
             direcrtions(1,:),direcrtions(2,:),direcrtions(3,:), ...
             'ShowArrowHead','on','Color' ,'b');
        case 1  %2D plot
          quiver(world_poses(1,:),world_poses(3,:), ...
             direcrtions(1,:),direcrtions(2,:), ...
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
        saveas(positions_plot_fig, fullfile(meta_path,RECONSTRUCTION_DIR, ...
                 strcat(file_prefix, plot_type_suffix, '.jpg')));
    end


  end %if save_figures ~= 0

  % close the figure if we are not viewing it
  if(~view_figure)
    close(positions_plot_fig)
  end
end%for each scene


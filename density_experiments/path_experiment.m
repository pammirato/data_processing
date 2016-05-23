%shows bounding boxes by image, with many options.  Can view vatic outputted boxes,
%results from a recognition system, or both. Also allows changing of vatic boxes. 


%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'SN208_2cm_paths'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 

instance_name = 'chair5.mat';%make this 'all' to do it for all labels, 'bigBIRD' to do bigBIRD stuff
use_custom_instances = 1;
custom_instances_list = {'chair1.mat','chair2.mat','chair3.mat','chair4.mat','chair5.mat'};


recognition_system_name = 'fast_rcnn';

show_figures = 0;
show_global_figures = 1;
save_figures = 1;

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
  %get all the image names in the scene
  all_image_names = get_names_of_X_for_scene(scene_name,'rgb_images'); 

  
  instance_images_map = containers.Map(all_instance_names, cell(1,length(all_instance_names)));


  all_means = cell(1,length(all_instance_names)); 
 
  for j=1:length(all_instance_names)
   
    cur_instance_file_name = all_instance_names{j};
    cur_instance_name = cur_instance_file_name(1:end-4);


    cur_scores_grid_file = load(fullfile(meta_path,DENSITY_EXPERIMENTS_DIR, ...
                            recognition_system_name, ...
                            SCORE_ARRAYS_BY_INSTANCE_DIR, cur_instance_file_name));

    cur_scores_grid = cur_scores_grid_file.scores_grid;






    %assume square grid
    path_length = length(cur_scores_grid);
    num_paths = 9; %sizeh(cur_scores_grid);

    %pick out the columns with detections
    good_cols = [];
    for k=1:num_paths
   
      if(sum(cur_scores_grid(:,k)) > 10)
        good_cols(end+1) = k
      end 

    end%for k

    cur_scores_grid = cur_scores_grid(:,good_cols);
    num_paths = length(good_cols);
    grid_size = path_length;

 
    cur_instance_mean_std_num = zeros(3,grid_size-1);
    no_data = -ones(grid_size,grid_size);

    if(save_figures)
      mkdir(fullfile(meta_path,DENSITY_EXPERIMENTS_DIR, recognition_system_name, ...
                          DIFF_IMAGES_DIR, cur_instance_name));
    end
 
    %for each possible resolution, get the differences in scores
    for k=1:(grid_size-1)

      forward_filter = zeros(k*2 +1,1);
      forward_filter(end) = -1;    
      forward_filter(k+1) = 1;
      forward_results = abs(imfilter(cur_scores_grid, forward_filter));
    
      backward_filter = zeros(k*2 +1,1);
      backward_filter(1) = -1;    
      backward_filter(k+1) = 1;
      backward_results = abs(imfilter(cur_scores_grid, backward_filter));


      average_results = -ones(path_length,num_paths);

      %everything k poisitions away form boundary is good
      clean_indices = [(k+1):(grid_size-k)];
      average_results(clean_indices, :) = ...
                                      .5*forward_results(clean_indices,:) + ...
                                      .5*backward_results(clean_indices,:);



      %now fill in boundary values
      forward_only_rows = 1:min(k, grid_size-k);%the 
      backward_only_rows = max(k,grid_size-k+1):grid_size;
      forward_and_backward_rows = (k+1):grid_size-k;
      no_forward_or_back = grid_size-k+1:k;


      %symmetry due to square grid
      right_only_cols = forward_only_rows;
      left_only_cols = backward_only_rows;
      left_and_right_cols = forward_and_backward_rows;
      no_left_or_right = no_forward_or_back;


      % FORAWRD
      average_results(forward_only_rows,:) = ...
                               forward_results(forward_only_rows,:);

      %BACKWARD
      average_results(backward_only_rows,:) = ...
                             backward_results(backward_only_rows,:);

      %FORAWRD AND BACk
      average_results(forward_and_backward_rows,:) = ...
                       .5*backward_results(forward_and_backward_rows,:) + ...
                       .5*forward_results(forward_and_backward_rows,:);


      %NO FORWARD OR BACK
      %average_results(no_forward_or_back,:) = ... 
      %                     no_data(no_forward_or_back,:);








      cur_instance_mean_std_num(1,k) = mean(average_results(average_results~= -1));
      cur_instance_mean_std_num(2,k) = std(average_results(average_results~= -1));
      cur_instance_mean_std_num(3,k) = (length(forward_only_rows)*length(left_only_cols)*4*2) + ...
                      (length(forward_and_backward_rows)*length(left_and_right_cols)*4) + ...
                      (length(forward_and_backward_rows)*length(left_only_cols)*4*3) + ...
                      (length(forward_only_rows)*length(no_left_or_right)*4);



      

      if(show_figures)
        f = figure;
      else
        f = figure('Visible', 'off');
      end
      imagesc(average_results);
      title([cur_instance_name, ' res: ', num2str(k)]);
      h = colorbar;
      caxis([0,1]);
      ylabel(h, ['Average Differnce in score moving ', num2str(k) , ' positions']);%color bar label
      xlabel('X Poisiton (1 = 10cm)');
      ylabel('Y Poisiton (1 = 10cm)');

      if(save_figures)
       
        saveas(f, fullfile(meta_path,DENSITY_EXPERIMENTS_DIR, recognition_system_name, ...
                          DIFF_IMAGES_DIR, cur_instance_name, ...
                          strcat(num2str(k),  '.jpg')));
      end


      if(~show_figures)
        close(f);
      end

    end %for k, each grid resolution 


    %% now plot global means
    if(show_global_figures)
      f = figure;
    else
      f = figure('Visible', 'off');
    end

    plot(1:(grid_size-1), cur_instance_mean_std_num(1,:), 'r.-');
    hold on;
    %plot(1:(grid_size-1), cur_instance_mean_std_num(2,:), 'b.-');

    %draw number of points for each res
    %for k=1:length(cur_instance_mean_std_num)
   %   text(k,cur_instance_mean_std_num(2,k),num2str(cur_instance_mean_std_num(3,k)));
   % end%for j, each res

    
   % legend('mean', 'std');
    title(['Mean score difference for each resolution: ', cur_instance_name]);
    xlabel('resolution');
    ylabel('mean score difference for each image');

    if(save_figures)
        saveas(f, fullfile(meta_path,DENSITY_EXPERIMENTS_DIR, recognition_system_name, ...
                          DIFF_IMAGES_DIR, cur_instance_name, ...
                          strcat('mean_std',  '.jpg')));
    end
    if(~show_global_figures)
      close(f);
    end


    all_means{j} = cur_instance_mean_std_num(1,:);
  end%for j, each instance_name

 

  %show all means on one plot
  %all_means_fig = figure;
  hold on;
  for j=1:length(all_means)
    cur_instance_name = all_instance_names{j};
    if(strcmp(cur_instance_name(1:6), 'bottle'))
      continue;
    end
    cur_mean = all_means{j};
    color = rand(1,3);

    plot(1:length(cur_mean), cur_mean(:), '.-', 'color', color);
  end
  
  legend(all_instance_names(1:end-4));


 

  if(~show_figures && ~show_global_figures)
    %close all;
  end
end%for each scene



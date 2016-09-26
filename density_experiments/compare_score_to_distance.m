% compares detection scores for each instance and distance bewteen cameras for
% every pair of images in the scene. Plots resutls
%


%CLEANED - yes 
%TESTED - no

clearvars;

%TODO - global plot?

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'FB209_den1'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 1;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this
     

instance_name = 'all';%make this 'all' to do it for all labels
use_custom_instances = 0;
custom_instances_list = {};

recognition_system_name = 'ssd_bigBIRD';%which detector to use


make_global_plot = 0;%put plots for all scenes in subplots instead of separate windows
                     %NOT FULLY SUPPORTED
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



global_avg_diff_sums = zeros(1000,1);
all_avg_diffs = -ones(200,length(all_scenes));


%% MAIN LOOP

if(make_global_plot)
  f = figure();
end
for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %get all the instance labels in this scene
  instance_name_to_id_map = get_instance_name_to_id_map();
  all_instance_names = keys(instance_name_to_id_map);

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
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', group_name, ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
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



  %load the detections by instance for each image in the scene
  %these were already processed to pick the best detection for each instance in each image
  detections_map = containers.Map(image_names, cell(1,length(image_names)));

  for jl=1:length(image_names)
    image_name = image_names{jl};
    
    try
      dets = load(fullfile(meta_path, 'recognition_results', recognition_system_name, ...
                           'bounding_boxes_by_image_instance', ...
                          strcat(image_name(1:10), '.mat')));
    catch
      %there were no detections for this image, so skip it
      continue;
    end
    %poplulate the map 
    detections_map(image_name) = dets; 
 end


  %store the distances between each pair of images, and the score difference for each
  %instance between each pair of images
  %alos store all the scores for each instance in each image
  dists = -ones(length(image_names)^2,1);
  score_diffs = -ones(length(image_names)^2,length(all_instance_names));
  all_scores = -ones(length(image_names),length(all_instance_names));


  %for each image, compare score for instances with each other image, and record
  %distance between the two images
  for jl=1:length(image_names)

    %get the current image name, camera positions, and detection scores
    image_name_jl = image_names{jl};
    image_struct_jl = image_structs_map(image_name_jl);
    cam_pos_jl =  image_struct_jl.world_pos*scale;
    dets_jl = cell2mat(struct2cell(detections_map(image_name_jl)));
    scores_jl = dets_jl(:,5);
   
    %if there is no detection for an instance give it a large negative value 
    scores_jl(scores_jl<0) = -100;

    %store all scores for this image
    all_scores(jl,:) = scores_jl;

    %for each other image, get scores, distance to jl image, and compare
    for kl = 1:length(image_names)
      image_name_kl = image_names{kl};
      image_struct_kl = image_structs_map(image_name_kl);
      cam_pos_kl =  image_struct_kl.world_pos*scale;
      dets_kl = cell2mat(struct2cell(detections_map(image_name_kl)));
      scores_kl = dets_kl(:,5);
      scores_kl(scores_kl<0) = -100;

      %distance between images in the scene(in millimeters?)
      dist = pdist2(cam_pos_jl', cam_pos_kl');
     
      %score difference for each instance 
      score_diff = abs(scores_jl - scores_kl);

      %store in global arrays
      index = (jl-1)*length(image_names) + kl;
      dists(index)  =dist;
      score_diffs(index,:) = score_diff; 
    end%for kl
  end%for jl  


  %% graph results

  %bin dists because they are doubles few are the same 
  bin_size = 20;%size in mm
  max_dist = max(dists);%maximum distance between any images
  num_bins = ceil(max_dist/bin_size);
  %stores the average score difference for each instance for each binned distance
  avg_score_diff_per_dist = -ones(num_bins,size(score_diffs,2));
  
 
  if(make_global_figure)
    ax(il) = subplot(2,2,il);
  else
    f = figure(); 
  end 
  hold on;
  
  %for each instance, plot its average scores
  for jl=1:size(avg_score_diff_per_dist,2)
    %for each distance bin, get the score diffs and plot the average of them
    for kl=1:num_bins
      %get the distance in mm for this bin
      dist = kl*bin_size;
    
      %only get the score diffs for image pairs with the correct distance 
      gi = find( (dists < dist) & (dists > (dist-bin_size)) & (dist>0));
      %filters out image pairs where one or both did not have a valid detection
      gi2 = find(score_diffs(:,jl) <= 1);
      good_inds = intersect(gi, gi2);

      %get the average over all image pairs for this distance bin
      x= mean(score_diffs(good_inds,jl));  
      if(isnan(x))
        %something went wrong
        disp('NAN');
        avg_score_diff_per_dist(kl,jl) = 0;
      else
        avg_score_diff_per_dist(kl,jl)  = x;
      end
    end%for kl, each dist bin

    %generate a random color for this  instance and plot its score diffs
    color = rand(3,1);
    plot(0:length(avg_score_diff_per_dist(:,jl)),...
                   [0;avg_score_diff_per_dist(:,jl)], 'Color',color)

  end%for jl, each instance
  legend(all_instance_names);
 
  %draw a vertical line for our chosen density 
  line([300/bin_size 300/bin_size], [0 max(avg_score_diff_per_dist(:))]);

  %label graph
  if(~make_global_figure)
    xlabel(sprintf('binned distance between cameras(%dcm)', bin_size/10)
    ylabel('avg score difference');
  end

  %set axis limits so all graphs are at same scale
  axis([0 100 0 1]);
  hold off;
  

  %calcuate global stats across all instances and scenes
  if(make_global_figure)
    max_diffs = max(avg_score_diff_per_dist);
    bad_inds = max_diffs < .2;
    avg_score_diff_per_dist(:,bad_inds) = [];
    avg_avg_diff = mean(avg_score_diff_per_dist,2);
    all_avg_diffs(1:length(avg_score_diff_per_dist),i) = avg_avg_diff;
    global_avg_diff_sums(1:length(avg_avg_diff)) = ...
                     global_avg_diff_sums(1:length(avg_avg_diff)) + avg_avg_diff; 
  end%if make global figure
end%for il,  each scene

 
%label global plot, and make global stats plot 
if(make_global_figure)
  xl =xlabel('Binned Distance Between Cameras(2cm)');
  yl = ylabel('Absolute Difference in Detection Score');
  set(xl,'Position', [-10 -.15]);
  set(yl, 'Position', [-150 1.1]);
  tt = title('How detection changes with movement');
  set(tt, 'Position', [-10 2.45]);

  global_avg_diff = global_avg_diff_sums / length(all_scenes);
  global_avg_diff(global_avg_diff ==0) = [];
  figure;
  plot(1:length(global_avg_diff), global_avg_diff);

end%if make global figure


%initialize contants, paths and file names, etc. 
clearvars;
init;



%% USER OPTIONS

scene_name = 'FB209_den1'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 1;%whether or not to run for the scenes in the custom list
custom_scenes_list = {'FB209_den1', 'SN208_den1', 'SN208_den2', ...
    'Kitchen_Living_02_1_vid_1','Kitchen_Living_02_1_vid_3' };%populate this 
custom_scenes_list = {'Den_den2', 'Den_den3','Den_den4' };%populate this 
custom_scenes_list = {'FB209_den1', 'SN208_den1', 'SN208_den2', ...
    'Kitchen_Living_02_1_vid_1','Kitchen_Living_02_1_vid_3', ...
    'Den_den2', 'Den_den3','Den_den4'};%populate this 
  custom_scenes_list = {'FB209_den1', 'SN208_den2', ...
   'Kitchen_Living_02_1_vid_3', ...
   'Den_den3'};%populate this 

instance_name = 'all';%make this 'all' to do it for all labels, 'bigBIRD' to do bigBIRD stuff
use_custom_instances = 0;
custom_instances_list = {'chair5','chair6'};


recognition_system_name = 'ssd_bigBIRD';

show_figures = 0;
show_global_figures = 0;
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



global_avg_diff_sums = zeros(1000,1);
all_avg_diffs = -ones(200,length(all_scenes));


%% MAIN LOOP

f = figure();

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
  image_names = get_names_of_X_for_scene(scene_name,'rgb_images'); 

  
  instance_images_map = containers.Map(all_instance_names, cell(1,length(all_instance_names)));


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


  detections_map = containers.Map(image_names, cell(1,length(image_names)));

  for jl=1:length(image_names)
    image_name = image_names{jl};
    
    try
    dets = load(fullfile(meta_path, 'recognition_results', recognition_system_name, ...
                           'bounding_boxes_by_image_instance', ...
                          strcat(image_name(1:10), '.mat')));
    catch
      continue;
    end
                        
    detections_map(image_name) = dets; 
 end




  dists = -ones(length(image_names)^2,1);
  score_diffs = -ones(length(image_names)^2,length(all_instance_names));
  all_scores = -ones(length(image_names),length(all_instance_names));


  for jl=1:length(image_names)

    image_name_jl = image_names{jl};
    image_struct_jl = image_structs_map(image_name_jl);
    cam_pos_jl =  image_struct_jl.world_pos*scale;
    %dets_jl = detections_map(image_name_jl);
    dets_jl = cell2mat(struct2cell(detections_map(image_name_jl)));
    %det_jl = dets_jl.(instance_name);
    %score_jl = det_jl(5);
    scores_jl = dets_jl(:,5);
    
    scores_jl(scores_jl<0) = -100;
    all_scores(jl,:) = scores_jl;

    for kl = 1:length(image_names)
      image_name_kl = image_names{kl};
      image_struct_kl = image_structs_map(image_name_kl);
      cam_pos_kl =  image_struct_kl.world_pos*scale;
      %dets_kl = detections_map(image_name_kl);
      dets_kl = cell2mat(struct2cell(detections_map(image_name_kl)));
      %det_kl = dets_kl.(instance_name);
      %score_kl = det_kl(5); 
      scores_kl = dets_kl(:,5);
      scores_kl(scores_kl<0) = -100;

      dist = pdist2(cam_pos_jl', cam_pos_kl');
      %score_diff = abs(score_jl - score_kl);
      score_diff = abs(scores_jl - scores_kl);

      index = (jl-1)*length(image_names) + kl;
      dists(index)  =dist;
      score_diffs(index,:) = score_diff; 
    end%for kl

   

  end%for jl  

  bin_size = 20;
  max_dist = max(dists);
  num_bins = ceil(max_dist/bin_size);
  avg_score_diff_per_dist = -ones(num_bins,size(score_diffs,2));
  
  
  %f = figure(); 
  ax(i) = subplot(2,2,i);
  hold on;
  for jl=1:size(avg_score_diff_per_dist,2)
    for kl=1:num_bins
      dist = kl*bin_size;
      %good_inds = find( (dists < dist) & (dists > (dist-bin_size))  & (score_diffs(:,jl) > 0));
      gi = find( (dists < dist) & (dists > (dist-bin_size)) & (dist>0));
      gi2 = find(score_diffs(:,jl) <= 1);
      good_inds = intersect(gi, gi2);
      x= mean(score_diffs(good_inds,jl));  
      if(isnan(x))
        avg_score_diff_per_dist(kl,jl) = 0;
      else
        avg_score_diff_per_dist(kl,jl)  = x;
      end
    end
    color = rand(3,1);
    plot(0:length(avg_score_diff_per_dist(:,jl)), [0;avg_score_diff_per_dist(:,jl)], 'Color',color)

  end%for jl
  %legend(all_instance_names);
  
  line([300/bin_size 300/bin_size], [0 max(avg_score_diff_per_dist(:))]);
%   xlabel('binned distance between cameras(2cm)')
%   ylabel('avg score difference');
  axis([0 100 0 1]);
  hold off;
  
%   saveas(f, fullfile('/playpen/ammirato/Pictures/icra_2016_figures/', ...
%           strcat(scene_name, 'density_2', '.jpg')));
  
    max_diffs = max(avg_score_diff_per_dist);
    bad_inds = max_diffs < .2;
    avg_score_diff_per_dist(:,bad_inds) = [];

   avg_avg_diff = mean(avg_score_diff_per_dist,2);
   
   all_avg_diffs(1:length(avg_score_diff_per_dist),i) = avg_avg_diff;
   
    
   global_avg_diff_sums(1:length(avg_avg_diff)) =  global_avg_diff_sums(1:length(avg_avg_diff)) + avg_avg_diff; 

end%for each scene

  
xl =xlabel('Binned Distance Between Cameras(2cm)');
yl = ylabel('Absolute Difference in Detection Score');
set(xl,'Position', [-10 -.15]);
set(yl, 'Position', [-150 1.1]);
tt = title('How detection changes with movement');
set(tt, 'Position', [-10 2.45]);

% global_avg_diff = global_avg_diff_sums / length(all_scenes);
% global_avg_diff(global_avg_diff ==0) = [];
% 
% figure;
% plot(1:length(global_avg_diff), global_avg_diff);


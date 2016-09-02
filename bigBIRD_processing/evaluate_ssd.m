%shows bounding boxes by image, with many options.  Can view vatic outputted boxes,
%results from a recognition system, or both. Also allows changing of vatic boxes. 

%TODO  - add scores to rec bboxes
%      - add labels to rec bboxes
%      - move picking labels to show outside of loop
clearvars;
%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 



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
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


  instance_names = get_names_of_X_for_scene(scene_name, 'instance_labels');

  average_precision = zeros(1,length(instance_names));
  for jl=1:length(instance_names)
    cur_instance_name = instance_names{jl};
    gt_labels = load(fullfile(meta_path, 'labels', 'strict_labels', ...
                              'bounding_boxes_by_instance', strcat(cur_instance_name, '.mat'))); 
                            
    gt_boxes = gt_labels.boxes; %reshape(cell2mat(gt_labels.boxes),length(gt_labels.boxes),4);
    gt_image_names = gt_labels.image_names;
    
    %load the ssd results
    try
    ssd_labels = load(fullfile(meta_path, 'recognition_results', 'ssd_bigBIRD', ...
                              'bounding_boxes_by_class', strcat(cur_instance_name, '.mat'))); 
    catch
      continue;
    end
                            
    ssd_all_boxes = ssd_labels.boxes;
    ssd_image_names = ssd_labels.image_names;

    ssd_top_boxes = zeros(length(ssd_all_boxes),5);
    
    %get just the top detection for each iamge
    for kl=1:length(ssd_all_boxes)
      boxes = ssd_all_boxes{kl};
      boxes = sortrows(boxes, -5);
      ssd_top_boxes(kl,:) = boxes(1,:);
    end
    
    
    thresholds = [0:.1:1];
    precisions = zeros(1,length(thresholds));
    recalls = zeros(1,length(thresholds));
    
    for kl=1:length(thresholds)
      
      thresh = thresholds(kl);
      
      good_inds = find(ssd_top_boxes(:,5) > thresh);
      
      threshed_boxes = ssd_top_boxes(good_inds,:);
      threshed_image_names = ssd_image_names(good_inds);
      
      num_retrieved = length(threshed_image_names);
      num_relevant = length(gt_image_names);
      
      num_correct_boxes = 0;
      for ll=1:length(gt_image_names)
        gt_name = gt_image_names{ll};
        
        gt_index = strfind(threshed_image_names, gt_name);
        gt_index = find(cellfun(@isempty, gt_index) == 0);
        if(isempty(gt_index))
          continue;
        end
        
        assert(length(gt_index)==1);
        
        pred_box = threshed_boxes(gt_index,:);
        
        iou = get_bboxes_iou(pred_box(1:4), gt_boxes{ll});
        
        if(iou > 0)
          num_correct_boxes = num_correct_boxes+1;
        end
       
      end%for ll
      
      precisions(kl) = num_correct_boxes / num_retrieved;
      recalls(kl) = num_correct_boxes / num_relevant;   
    end    
  end 
end 


 


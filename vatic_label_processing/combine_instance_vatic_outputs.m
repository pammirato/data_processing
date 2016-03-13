% combines output from multiple vatic 'videos' into one file
% used because intially 'videos' are split up into smaller segement
% so load on workers is not too high  



%TODO - what happens when label is OUTSIDE FRAME????
%     - test


%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'all'; %make this = 'all' to run all scenes
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

for i=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{i};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);



  %get a list of all the 'videos' outputted from vatic
  original_file_names = get_names_of_X_for_scene(scene_name, 'instance_labels');


  all_label_outputs = cell(0);
  all_original_file_names = cell(0);

  group_name_to_sub_group_names_map = containers.Map();


  cur_index = 1;

  

  %% find which files need to be combined
  for j=1:length(original_file_names)
     
    cur_file_name = original_file_names{j};

    %see if this file is a sub_goup of a full_group for one instance
    % ex) chair1.mat holds all the annotations for the chair1 instance
    %     but chair2_1.mat, chair2_2.mat each hold part of the annotations for the chair2 instance


    %get a cell array of all parts of the file name separated by '_' character 
    split_file_name = strplit(cur_file_name, '_');

    
    if(length(split_file_name) == 1)
      %this can't be a sub_group because it doesn't have a '_' character
      continue;
    else%this MIGHT be a sub_group
     
      %get the last part of the filename  
      file_suffix = split_file_name{end};
      %get rid of the .mat part
      file_suffix = file_suffix(1:end-4);     

      %check if every character in the suffix is a number 
      is_digit = isstrprop(file_suffix,'digit');
  
      if(sum(is_digit) == length(file_suffix))
        %it is a sub-group
        %recover the group name
        group_name = strjoin(split_file_name(1:end-1),'');
      
        %put this sub-group name into the list of sub_group names for this group 
        try
          sub_names = group_names_to_sub_group_names_map(group_name);
          sub_names{end+1} = cur_file_name;
          group_names_to_sub_group_names_map(group_name) = sub_names;
        catch%if this is the first sub_group for this group, add it to the map
          group_names_to_sub_group_names_map(group_name) = {cur_file_name}; 
        end
      else
        %this is not a sub-group
        continue; 
      end%if sum(digit) ...  , this is a sub-group
       

    end%length == 1, file name has a '_'
  end%for j, len(original_file_anems)









  %% now combine the files into one file per group

  %make a directory to store sub group files that will be deleted
  to_delete_dir = fullfile(scene_path,LABELING_DIR,BBOXES_BY_INSTANCE_DIR, ...
                            'temp_to_delete');
  mkdir(to_delete_dir);

  all_group_names = keys(group_names_to_sub_group_names_map);

  
  for j=1:length(all_group_names)
    
    cur_group_name = all_group_names{j}; 
    all_sub_group_names = group_names_to_sub_group_names_map(cur_group_name);


    

    %will hold data for entire group
    group_data = load(fullfile(scene_path,LABELING_DIR,BBOXES_BY_INSTANCE_DIR, ...
                                 all_sub_group_names{k}));

    %load all the annotations for each sub_group
    for k=1:length(all_sub_group_names)
      vatic_file = load(fullfile(scene_path,LABELING_DIR,BBOXES_BY_INSTANCE_DIR, ...
                                 all_sub_group_names{k}));

      group_data.annotations = cat(2,group_data.annotations,vatic_file.annotations);  
    
      %could delete here but want to wait until group is saved before deleting
      %so just move for now
      movefile(fullfile(scene_path,LABELING_DIR, ... 
                        BBOXES_BY_INSTANCE_DIR,all_sub_group_names{k}), ...
               fullfile(to_delete_dir,all_sub_group_names{k}));
    end %for k, each sub group name

    group_data.num_frames =  length(group_data.annotations;

    save(fullfile(scene_path,LABELING_DIR, BBOXES_BY_INSTANCE_DIR, ...
                  strcat(cur_group_name,'.mat')),'-struct','group_data');



      
  end%for , each group name 

  %delete all the subgroups
  rmdir(to_delete_dir);
end%for i, each scene 




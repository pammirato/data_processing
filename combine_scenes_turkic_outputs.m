

clear;
init;




%the scene and instance we are interested in
density = 1;
scene_name = 'SN208_3';
scene_path = fullfile(BASE_PATH,scene_name);
if(density)
    scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
end



turk_path = fullfile(scene_path,LABELING_DIR,'turk_boxes');






%% group mats of same labels
file_names = dir(fullfile(turk_path,'*.mat'));
file_names = {file_names.name};


all_label_outputs = cell(0);
all_file_names = cell(0);

cur_index = 1;

for i=1:length(file_names)
    
    if( i ~= cur_index)
        continue;
    end
    cur_name = file_names{i};
    
    cur_mat = load(fullfile(turk_path,cur_name));
    
    
    if(isstrprop(cur_name(end-4),'digit'))
        cur_name = cur_name(1:end-6);
    else
        all_label_outputs{end+1} = {cur_mat};
        all_file_names{end+1} = cur_name;
        cur_index = i+1;
        continue;
    end
    
    
    cur_index = i +1;
    
    same_label_outputs = cell(0);
    same_label_outputs{end+1} = cur_mat;
    while(cur_index <= length(file_names))
        next_name = file_names{cur_index};
        if(strcmp(cur_name,next_name(1:end-6)))
            same_label_outputs{end+1} = load(fullfile(turk_path,next_name));
            cur_index = cur_index+1;
        else
            break;
        end
    end% while
    
    all_label_outputs{end+1} = same_label_outputs;
    all_file_names{end+1} = cur_name;
        
end%for i len(file_anems)









%%
for i=1:length(all_label_outputs)
    
    cur_mats = all_label_outputs{i};
    
    if(length(cur_mats) < 2)
        continue;
    end
    
    first_mat = cur_mats{1};
    total_num_frames = first_mat.num_frames;
    
    all_annotations = first_mat.annotations;
    
    for j=2:length(cur_mats)
        next_mat = cur_mats{j};
        
        boxes = next_mat.annotations;
%         for k=2:length(boxes)
%             cb = boxes{k};
%             cb.frame = cb.frame -1 + total_num_frames;
%             boxes{k} = cb;
%         end % for k
        
        boxes = boxes(2:end);
        
        all_annotations = cat(2,all_annotations,boxes);
        
        total_num_frames = total_num_frames + next_mat.num_frames -1;
      
        
    end%for j 
    
    first_mat.num_frames = total_num_frames;
    first_mat.annotations = all_annotations;
    
    cur_name = first_mat.slug;
    first_mat.slug = cur_name(1:end-2);
    
    save(fullfile(turk_path,strcat(all_file_names{i},'.mat')),'-struct','first_mat');
    
end%for i 1-len(all_label_outputs)

for i=1:9
    delete(fullfile(turk_path,strcat('*_',num2str(i),'.mat')));
end




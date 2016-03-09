clear;
init;

density = 1;
scene_name = 'SN208_3';





scene_path = fullfile(BASE_PATH,scene_name);
if(density)
    scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
end


vid_names = dir(fullfile(scene_path,LABELING_DIR,'turk_boxes','*.mat'));
vid_names = {vid_names.name};


for i=1:length(vid_names)
    v_name = vid_names{i};

    v_mat = load(fullfile(scene_path,LABELING_DIR,'turk_boxes',v_name));


    image_names = dir(fullfile(scene_path,LABELING_DIR,'images_for_labeling',v_name(1:end-4),'*.jpg'));
    image_names = {image_names.name};


    annotations = v_mat.annotations;

    for j=1:length(annotations)
        ann = annotations{j};

        cur_name = image_names{ann.frame + 1}; 

        %ann.frame = str2num(cur_name(1:10));
        ann.frame = strcat(cur_name(1:10),'.png');

        annotations{j} = ann;

    end 

    v_mat.annotations = annotations;

    save(fullfile(scene_path,LABELING_DIR,'turk_boxes',v_name),'-struct','v_mat');

end    


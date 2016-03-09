

clear;
init;

debug =0;


%the scene and instance we are interested in
density = 1;
scene_name = 'SN208_3';
scene_path = fullfile(BASE_PATH,scene_name);
if(density)
    scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
end

turk_path = fullfile(scene_path,LABELING_DIR,'turk_boxes');



label_to_images_that_see_it_map = load(fullfile(scene_path,LABELING_DIR,...
                                    DATA_FOR_LABELING_DIR, ...
                                    LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE));
 
label_to_images_that_see_it_map = label_to_images_that_see_it_map.(LABEL_TO_IMAGES_THAT_SEE_IT_MAP);
             



file_names = dir(fullfile(turk_path,'*.mat'));
file_names = {file_names.name};


for i=1:length(file_names)
    %% load info for this label
    cur_name = file_names{i};
    label_name = cur_name(1:end-4)
    
    cur_mat = load(fullfile(turk_path,cur_name));
    
    
    
    
    
    % load my data
%     image_names = dir(fullfile(scene_path,LABELING_DIR,IMAGES_FOR_LABELING_DIR,label_name,'*.jpg'));
%     image_names = {image_names.name};
    ls = label_to_images_that_see_it_map(label_name);
    ls = cell2mat(ls);
    %image_names = {ls.image_name};
    
    %transform_structs = load(fullfile(scene_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name,'transform_structs.mat'), 'transform_stucts');
    %transform_structs = transform_structs.transform_stucts;

    transform_map = load(fullfile(scene_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name,'transform_map.mat'));
    transform_map = transform_map.transform_map;
    
    %assert(length(image_names) == length(transform_map.values));
    
    annotations = cur_mat.annotations;
    for j=1:length(annotations)
        %% get info from turkic
        ann = annotations{j};
        
        bbox = [ann.xtl, ann.ytl, ann.xbr, ann.ybr];
        frame = ann.frame;
        
        
         if(strcmp(frame(1:6),'000000'))
            continue;
        end
        
        %image_name = strcat(sprintf('%010d',frame),'.png');
        image_name = frame;

        
        %% apply transformation to box
        ts = transform_map(image_name);

        label_struct = ts.label_struct;
        centering_offset = ts.centering_offset;
        crop_dimensions = ts.crop_dimensions;
        big_image_place = ts.big_image_place;
        resize_scale = ts.resize_scale;


        %%
        bbox = bbox * (1/resize_scale);

        %%
        xcrop_min = int64(crop_dimensions(1));
        ycrop_min = int64(crop_dimensions(3));

        bbox(1) = bbox(1) + xcrop_min;
        bbox(2) = bbox(2) + ycrop_min;
        bbox(3) = bbox(3) + xcrop_min;
        bbox(4) = bbox(4) + ycrop_min;


        %%
        start_row = big_image_place(1);
        start_col = big_image_place(3);

        bbox(1) = max(1,bbox(1) - start_col);
        bbox(2) = max(1,bbox(2) - start_row);
        bbox(3) = max(1,bbox(3) - start_col);
        bbox(4) = max(1,bbox(4) - start_row);
        
        %% debug vis
        if(debug)
            rgb_image = imread(fullfile(scene_path,RGB_IMAGES_DIR, image_name));

            imshow(rgb_image);
            hold on;

            rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');

           % ginput(1);
        end
        
        %% put new info back into structs
        ann.xtl = bbox(1);
        ann.ytl = bbox(2);
        ann.xbr = bbox(3);
        ann.ybr = bbox(4);
        
        %ann.frame = image_name;
        
        annotations{j} = ann;
        
    end%for j
    
    cur_mat.annotations = annotations;
    
    save(fullfile(turk_path,cur_name), '-struct','cur_mat');

    
end%for i






clear;
init;



%the scene and instance we are interested in
scene_name = 'FB209';
scene_path = fullfile(BASE_PATH,scene_name);

all_label_boxes = {};
all_label_names = {};
cur_label_name = '';
cur_label_boxes = {};
cur_frames = {};


fid_images = fopen(fullfile(scene_path,LABELING_DIR,'turk_bboxes','vatic_outputfile.txt')); 





counter = 0;

%skip header
line = fgetl(fid_images); 


line = fgetl(fid_images);
while(ischar(line))
    counter = counter +1;
    %get image info
    line = strsplit(line);

    frame = str2double(line{1});
    bbox = str2double(line(2:5));
    label_name = line{6};
    label_name = label_name(7:end);


    if(~strcmp(label_name,cur_label_name))
        
        

        %all_label_names{end+1} = label_name;

        %all_label_boxes{end+1} = cur_label_boxes;

        if(length(cur_label_boxes) > 0)
            labeled_boxes_map = containers.Map(cur_frames,cur_label_boxes); 
            mkdir(fullfile(scene_path,LABELING_DIR,'turk_boxes',cur_label_name));
            save(fullfile(scene_path,LABELING_DIR,'turk_boxes',cur_label_name,...
                    'labeled_boxes_map.mat'), 'labeled_boxes_map');

        end

        cur_label_name = label_name;
        cur_label_boxes = {};
        cur_frames = {};

        %get all image names for this label
        image_names = dir(fullfile(scene_path,LABELING_DIR,IMAGES_FOR_LABELING_DIR,label_name,'*.jpg'));
        image_names = {image_names.name};

        
        transform_structs = load(fullfile(scene_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name,'transform_structs.mat'), 'transform_stucts');
        transform_structs = transform_structs.transform_stucts;

        assert(length(image_names) == length(transform_structs)+1);
    end% if label_names dont match




    image_name = image_names{frame+1};

    if(frame == 0)
        line = fgetl(fid_images);
        continue;
    end

    ts = transform_structs{frame};

    label_struct = ts.label_struct;
    centering_offset = ts.centering_offset;
    crop_dimensions = ts.crop_dimensions;
    big_image_place = ts.big_image_place;
    resize_scale = ts.resize_scale;


    %%
    bbox = bbox * (1/resize_scale);

    %%
    xcrop_min = crop_dimensions(1);
    ycrop_min = crop_dimensions(3);

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
%         bbox(1) = bbox(1) - start_row;
%         bbox(2) = bbox(2) - start_col;
%         bbox(3) = bbox(3) - start_row;
%         bbox(4) = bbox(4) - start_col; 
%     

    %%
    cur_label_boxes{end+1} = bbox;
    cur_frames{end+1} = image_name;

    line = fgetl(fid_images);
%%
%     img = imread(fullfile(scene_path,JPG_RGB_IMAGES_DIR,image_name));
%     imshow(img);
%     %rectangle('Position',[bbox(2) bbox(1) (bbox(4)-bbox(2)) (bbox(3)-bbox(1))], 'LineWidth',2, 'EdgeColor','b');
%     rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
% 
% 
%     %ginput(1);
end 



% all_label_boxes{end+1} = cur_label_boxes;
% all_label_boxes = all_label_boxes(2:end);
labeled_boxes_map = containers.Map(cur_frames,cur_label_boxes); 
mkdir(fullfile(scene_path,LABELING_DIR,'turk_boxes',cur_label_name));
save(fullfile(scene_path,LABELING_DIR,'turk_boxes',cur_label_name,...
        'labeled_boxes_map.mat'), 'labeled_boxes_map');









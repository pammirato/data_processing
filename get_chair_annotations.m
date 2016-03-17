%draws the bboxes on the images



init;

density = 1;
scene_name = 'SN208';

category_name = 'chair';
concat = 1;

%label_name = 'table2';


scene_path = fullfile(BASE_PATH,scene_name);
if(density)
    scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
end
turk_path = fullfile(scene_path,LABELING_DIR,'turk_boxes');



turk_labels = dir(turk_path);
turk_labels = turk_labels(3:end);
turk_labels = {turk_labels.name};

image_names = dir(fullfile(scene_path,'rgb','*.png'));
image_names = {image_names.name};

annotations_map = containers.Map(image_names,cell(1,length(image_names)));


for i=1:length(turk_labels)
    
    label = turk_labels{i};
    
    label_name = label(1:end-4);
    
    if(~strcmp(label(1:5),'chair'))
        continue;
    end
    
    disp(label);
    
    
    ann_file = load(fullfile(turk_path,strcat(label)));

    annotations = ann_file.annotations;
    for j=1:1:length(annotations)

        ann = annotations{j};

        bbox = double([ann.xtl, ann.ytl, ann.xbr, ann.ybr]);
        frame = ann.frame;

        if(frame(8) =='0')
            continue;
        end
        
        old_boxes = annotations_map(frame);
        
        if(concat)
            old_boxes{end+1} = {bbox};
        else 
            old_boxes{end+1} = {bbox,label_name};
        end
        annotations_map(frame) = old_boxes;
        
        

    end%for j, each annotation

    
end%for i, each turk label







for i=1:length(image_names)
    
    cur_name = image_names{i};
    anns = annotations_map(cur_name);
    
    
    if(concat)
        boxes = zeros(length(anns),4);
        
        for j=1:length(anns)
            b = anns{j};
            boxes(j,:) = cell2mat(b);
        end
        
        
    else
    
        annotations = struct();


        for j=1:length(anns)
            a = anns{j};

            f = a{2};
            box = a{1};

            annotations.(f) = box;

        end%for j
    end
        
    
    
    if(concat)
        save(fullfile(scene_path,'labeling','chair_boxes_per_image_concat',strcat(cur_name(1:10),'.mat')),'boxes');

    else
        save(fullfile(scene_path,'labeling','chair_boxes_per_image',strcat(cur_name(1:10),'.mat')),'-struct','annotations');
    end
    
    
    
    
end%for i, each image name

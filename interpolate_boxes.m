


init;


debug = 0;


density = 1;
%the scene and instance we are interested in
scene_name = 'SN208_2';
recognition_system_name = 'fast-rcnn';
font_size = 10;

%any of the fast-rcnn categories
category_name = 'chair'; %make this 'all' to see all categories

score_threshold = .1;

scene_path = fullfile(BASE_PATH,scene_name);
if(density)
    scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
end


image_names = dir(fullfile(scene_path,RGB_IMAGES_DIR,'*0101.png'));
image_names = {image_names.name};






 for i=1:21:21%length(image_names) 

    
    rgb_name = image_names{i};
    image_index = str2double(rgb_name(1:6));
    
    rec_name1 = strcat(rgb_name(1:10),'.mat');
    anns1 = load(fullfile(scene_path,'labeling','chair_boxes_per_image',rec_name1));
    
    
    anns11 = load(fullfile(scene_path,'labeling','chair_boxes_per_image', ...
                    strcat(sprintf('%06d',image_index+10),'0101.mat')));
    anns21 = load(fullfile(scene_path,'labeling','chair_boxes_per_image', ...
        strcat(sprintf('%06d',image_index+20),'0101.mat')));
    
    
    categories = fields(anns1);
    
    
    two_ten_structs = cell(1,9);
    twelve_twenty_structs = cell(1,9);
    
    for j=1:length(two_ten_structs)
        two_ten_structs{j} = struct();
        twelve_twenty_structs{j} = struct();
    end
    
    

    for j=1:length(categories)
        box1 = anns1.(categories{j});
        box11 = anns11.(categories{j});
        box21 = anns21.(categories{j});
        
        two_ten_boxes = zeros(9,4);
        for k=1:4
            labeled_pos = [1,11];
            labeled_val = [box1(k),box11(k)];
            query_pos = 2:10;
            two_ten_boxes(:,k) = interp1(labeled_pos,labeled_val,query_pos);
        
        end
        
        
        twelve_twenty_boxes = zeros(9,4);
        for k=1:4
            labeled_pos = [1,11];
            labeled_val = [box11(k),box21(k)];
            query_pos = 2:10;
            twelve_twenty_boxes(:,k) = interp1(labeled_pos,labeled_val,query_pos);
        end
        
        for k=1:9
            two_struct = two_ten_structs{k};
            twelve_struct = twelve_twenty_structs{k};
            
            two_struct.(categories{j}) = two_ten_boxes(k,:);
            twelve_struct.(categories{j}) = twelve_twenty_boxes(k,:);
            
            two_ten_structs{k} = two_struct;
            twelve_twenty_structs{k} = twelve_struct;
        end
        
        
        if(debug)
            rgb_image = imread(fullfile(scene_path,'rgb',rgb_name));
            imshow(rgb_image);
            hold on;
            title(rgb_name);
            bbox = box1;
            rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
            hold off;
            
            [~,~,but] = ginput(1);
            
            counter = 1;
            while(but == 1  && counter < 10)
                rgb_name = strcat(sprintf('%06d',image_index + counter),'0101.png');
                rgb_image = imread(fullfile(scene_path,'rgb',rgb_name));
                imshow(rgb_image);
                hold on;
                title(rgb_name);
                bbox = two_ten_boxes(counter,:);
                rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
                hold off;
                
                counter = counter +1;
                
                [~,~,but] = ginput(1);
            end%while but = 1
        end%if debug
            
        
        if(debug)
            rgb_name = strcat(sprintf('%06d',image_index + 10),'0101.png');
            rgb_image = imread(fullfile(scene_path,'rgb',rgb_name));
            imshow(rgb_image);
            hold on;
            title(rgb_name);
            bbox = box11;
            rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
            hold off;
            
            [~,~,but] = ginput(1);
            
            counter = 11;
            while(but == 1  && counter < 20)
                rgb_name = strcat(sprintf('%06d',image_index + counter),'0101.png');
                rgb_image = imread(fullfile(scene_path,'rgb',rgb_name));
                imshow(rgb_image);
                hold on;
                title(rgb_name);
                bbox = twelve_twenty_boxes(counter-10,:);
                rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
                hold off;
                
                counter = counter +1;
                
                [~,~,but] = ginput(1);
            end%while but = 1
        end%if debug
            
        
        
        
        
        
    end%for j, each category 

    
    

    for k=1:9
        two_struct = two_ten_structs{k};
        twelve_struct = twelve_twenty_structs{k};

        two_name = strcat(sprintf('%06d',image_index + k),'0101.mat');
        annotations = two_struct;
        save(fullfile(scene_path,'labeling','chair_boxes_per_image',two_name),'-struct','annotations');

        
        twelve_name = strcat(sprintf('%06d',image_index + k + 10),'0101.mat');
        annotations = twelve_struct;
        save(fullfile(scene_path,'labeling','chair_boxes_per_image',twelve_name),'-struct','annotations');
        
        
    end
   

 end%fior i, each image name


    
    


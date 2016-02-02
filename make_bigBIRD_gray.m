

clear;
init;

object_name = 'all';  %make this = 'all' to go through all objects


final_img_dimensions = [224,224];
border_size = 5;



d = dir(BIGBIRD_BASE_PATH);
d = d(3:end);



if(strcmp(object_name,'all'))
    num_objects = length(d);
else
    num_objects = 1;
end



for i=1:num_objects
    
    if(num_objects >1)
        object_name = d(i).name()
    end
    
    object_path = fullfile(BIGBIRD_BASE_PATH,object_name);
    masks_path = fullfile(object_path,'masks');
    
    mkdir(fullfile(object_path,'mvcnn_images'));
    
    
    
    
    
    %% get dimensions
    box_map = load(fullfile(object_path,'ground_truth_bboxes','box_map.mat'));
    box_map = box_map.box_map;
    
    boxes = box_map.values;
    
    boxes = cell2mat(boxes);
    
    widths = boxes(3,:) - boxes(1,:);
    heights = boxes(4,:) - boxes(2,:);
    
    max_dimension = max(cat(2,widths,heights));
    
    scale_factor = (max(final_img_dimensions)-border_size)/max_dimension;
    
    
    
    
    
    
    
    %%
    dd = dir(fullfile(object_path,'*.jpg'));
    image_names = {dd.name};

    
    for j=1:length(image_names)
        
        cur_name = image_names{j};
        
        mask_name = strcat(cur_name(1:end-4),'_mask.pbm');
       
        %convert to gray scale
        rgb_img = imread(fullfile(object_path,cur_name));
        gray_img = rgb2gray(rgb_img);
        
        %white out everything but the object
        mask_img = imread(fullfile(masks_path,mask_name));
        %segmented_img = gray_img .* uint8(~mask_img);
        segmented_img = uint8(255*ones(size(gray_img)));
        segmented_img(find(mask_img == 0)) = gray_img(find(mask_img == 0));
        
        
        %crop image
        bbox = box_map(cur_name);
        cropped_img = segmented_img(bbox(2):bbox(4),bbox(1):bbox(3));
        
        %scale image
        scaled_img = imresize(cropped_img,scale_factor);
        
        %add border to image
        final_img  = uint8(255*ones(final_img_dimensions));
        size_scaled = size(scaled_img);
        
        start_row = max(1,floor((final_img_dimensions(1)-size_scaled(1))/2));
        end_row = min(final_img_dimensions(1),start_row + size_scaled(1)-1);
        start_col = max(1,floor((final_img_dimensions(2)-size_scaled(2))/2));
        end_col = min(final_img_dimensions(2),start_col + size_scaled(2)-1);
        
        final_img(start_row:end_row, start_col:end_col) = scaled_img;
        
        
        imwrite(final_img,  ...
            fullfile(object_path,'mvcnn_images',strcat(cur_name(1:end-4),'_mvcnn.png')));
    
    
    end % for j, each image
    
    
    
end% for i, each object

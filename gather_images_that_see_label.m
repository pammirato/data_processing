%this script plots detection scores for one instance in a scene againts 
%variation in viewpoint of the instance, and distance from the camera


init;


density  = 1;
%the scene and instance we are interested in
scene_name = 'SN208_3';


label_name = 'all';%make this 'all' to do it for all labels, bigBIRD to do bigBIRD stuff
use_custom_labels = 1;
custom_labels = {'chair4', 'chair6'};

kinect_to_use = '1';

debug = 0;


label_box_size = 5;
max_image_dimension = 600;
start_crop_size = 400;
do_depth_crop = 0;

select_certain_grid_positions = 1;
grid_size = [21 21];
positions_in_each_row = zeros(grid_size(1),grid_size(2));
positions_in_each_row([1,11,21],:) = 1;

max_images_per_dir = 50;
min_images_per_dir = 20;


scene_path = fullfile(BASE_PATH,scene_name);
if(density)
    scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
end


%get the map to find all the interesting images
label_to_images_that_see_it_map = load(fullfile(scene_path,LABELING_DIR,...
                                    DATA_FOR_LABELING_DIR, ...
                                    LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE));
 
label_to_images_that_see_it_map = label_to_images_that_see_it_map.(LABEL_TO_IMAGES_THAT_SEE_IT_MAP);
             
all_labels = label_to_images_that_see_it_map.keys;
      
num_labels = 1;
if(strcmp(label_name,'all'))
    num_labels = length(all_labels);
elseif(strcmp(label_name,'bigBIRD'))
    d = dir(fullfile(BIGBIRD_BASE_PATH));
    d = d(3:end);
    all_labels = {d.name};
    breakp=1;
else 
    all_labels = {label_name};
end

if(use_custom_labels)
    all_labels = custom_labels;
end
% edit all all_labels to just do some custom list of labels

for i =1:length(all_labels) %num_labels

%     if(num_labels > 1)
%         label_name = all_labels{i}
%     end
       
    label_name = all_labels{i}



    %get the structs with IMAGE_NAME, X, Y, DEPTH for images that see this
    %instance
    try
    label_structs = label_to_images_that_see_it_map(label_name);
    catch
        disp(strcat('could not find ',label_name));
        continue;
    end

    %get all the image names
    temp = cell2mat(label_structs);
    image_names = {temp.(IMAGE_NAME)};
    clear temp;



    % %load data about psition of each image in this scene
    % camera_structs_file =  load(fullfile(scene_path,RECONSTRUCTION_DIR,CAMERA_STRUCTS_FILE));
    % camera_structs = camera_structs_file.(CAMERA_STRUCTS);
    % camera_structscale  = camera_structs_file.scale;

    % %get a list of all the image file names in the entire scene
    % temp = cell2mat(camera_structs);
    % all_image_names = {temp.(IMAGE_NAME)};
    % clear temp;
    % 
    % %make a map from image name to camera_struct
    % camera_structs_map = containers.Map(all_image_names, camera_structs);
    % clear all_image_names;


    mkdir(fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, label_name));


    transform_structs = cell(1,length(image_names));
    
    %for each image
    for jj=1:length(image_names)
        %figure;
        png_name = image_names{jj};
        
        if(png_name(8) ~= kinect_to_use)
            continue;
        end
        
        if(select_certain_grid_positions)
            image_index = str2double(png_name(1:6)) -1;
            col = 1 + floor(image_index/grid_size(2));
            row = mod(image_index,grid_size(1)) +1;
            
            if(~positions_in_each_row(row,col))
                continue;
            end
        end
        
        
        jpg_name = strcat(png_name(1:end-3),'jpg');



        if( ~ (exist(fullfile(scene_path, JPG_RGB_IMAGES_DIR, jpg_name),'file')==2))
            continue;
        end

        img = imread(fullfile(scene_path, JPG_RGB_IMAGES_DIR, jpg_name));

        ls = label_structs{jj};
        
%         if(jpg_name(8) == '1' || jpg_name(8) == '2')
%             ls.(X)  = min(1920,ls.x + 40);
%         end
        
        depth = ls.depth;
        
        crop_size = start_crop_size;
        if(do_depth_crop && depth >1000)
            crop_size = crop_size - crop_size*(1000/depth)/3;
        end


        %first draw the label dot
        x_dot_min = max(1,floor(ls.(X) - label_box_size/2));
        x_dot_max = min(size(img,2),floor(ls.(X) + label_box_size/2));
        y_dot_min = max(1,floor(ls.(Y) - label_box_size/2));
        y_dot_max = min(size(img,1),floor(ls.(Y) + label_box_size/2));


        temp =  img(y_dot_min:y_dot_max,x_dot_min:x_dot_max,1);
        img(y_dot_min:y_dot_max,x_dot_min:x_dot_max,1) = 255*ones(size(temp));
        img(y_dot_min:y_dot_max,x_dot_min:x_dot_max,2) = zeros(size(temp));
        img(y_dot_min:y_dot_max,x_dot_min:x_dot_max,3) = zeros(size(temp));

        if(debug)
            imshow(img);
            ginput(1);
        end
        %imshow(img);


        %now center the label
        display_image = uint8(255*ones(2*size(img,1),2*size(img,2),3));
        center_pos = [size(img,1), size(img,2)];

        label_pos = double([ls.y ls.x]);

        diff_pos = center_pos - label_pos ;

        start_row = 1+diff_pos(1);
        end_row = start_row+size(img,1)-1;
        start_col = 1+diff_pos(2);
        end_col = start_col+size(img,2)-1;


        display_image(start_row:end_row,start_col:end_col,:) = img;


        %now crop the image around the label
        y_crop_min = max(1,floor(start_row + label_pos(1) - (crop_size/2)));
        y_crop_max = min(size(display_image,1),floor(start_row + label_pos(1) + (crop_size/2)));

        x_crop_min = max(1,floor(start_col + label_pos(2) - (crop_size/2)));
        x_crop_max = min(size(display_image,2),floor(start_col + label_pos(2) + (crop_size/2)));


        crop_img = display_image(y_crop_min:y_crop_max,x_crop_min:x_crop_max,:);





        %now resize the image
        scale = max_image_dimension/max(size(crop_img));
        scale_img = imresize(crop_img,scale);

        %imshow(scale_img);

        imwrite(scale_img,fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, label_name,jpg_name));


        t_struct = struct('label_struct',ls,'centering_offset',diff_pos, ...
                        'crop_dimensions', [x_crop_min,x_crop_max,y_crop_min,y_crop_max], ...
                        'big_image_place', [start_row,end_row,start_col,end_col], ...
                         'resize_scale', scale);

        transform_structs{jj} = t_struct;

    end%for i in image_names

    %add in reference image
    if(exist(fullfile(BIGBIRD_BASE_PATH,label_name,'NP1_0.jpg'),'file'))
        ref_img = imread(fullfile(BIGBIRD_BASE_PATH,label_name,'NP1_0.jpg'));
    else
        ref_img = imread(fullfile(scene_path,LABELING_DIR,'reference_images', ...
                            strcat(label_name,'.jpg')));
    end
    ref_img = imresize(ref_img,[size(scale_img,1),size(scale_img,2)]);


     num_buckets = 0;
     num_images = length(dir(fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, label_name,'*.jpg')));
     if(num_images > max_images_per_dir)
        %num_images = length(image_names);

        

        if(mod(num_images,max_images_per_dir) < min_images_per_dir)
            num_buckets = floor(num_images/max_images_per_dir);
        else
            num_buckets = ceil(num_images/max_images_per_dir);
        end
    
        

        if(num_buckets > 1)
            images_moved_so_far = 0;
            
            new_image_names = dir(fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, label_name,'*.jpg'));
            new_image_names = {new_image_names.name};

            for k=1:num_buckets
                mkdir(fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, ...
                            strcat(label_name, '_', num2str(k))));
                
                start_kk = images_moved_so_far + 1;
                end_kk = start_kk + max_images_per_dir - 1;

                if(end_kk > length(new_image_names) || k ==num_buckets)
                    end_kk = length(new_image_names);
                end
                
                for kk=start_kk:end_kk
                    movefile(fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, ...
                                        label_name, new_image_names{kk}), ...
                             fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, ...
                                        strcat(label_name, '_', num2str(k)), new_image_names{kk}));
                end
                imwrite(ref_img,fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, strcat(label_name, '_', num2str(k)),'0000000000.jpg') );

                images_moved_so_far = end_kk;

            end% for k
        else
            imwrite(ref_img,fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, label_name,'0000000000.jpg') );
        end% if buckets > 1

    else
        imwrite(ref_img,fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, label_name,'0000000000.jpg') );
    end%if more images than max images
    


    mkdir(fullfile(scene_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name));
    %save(fullfile(scene_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name,'transform_structs.mat'), 'transform_stucts');


    transform_map = containers.Map(image_names, transform_structs);
    save(fullfile(scene_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name,'transform_map.mat'), 'transform_map');

    
    
    
    if(num_buckets  > 1)
        try
        rmdir(fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, label_name));
        catch
        end
    end  

end%for i, each label_naem







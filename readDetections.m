


room_name = 'KitchenLiving12';

class_name = 'monitor';
label_name = 'monitor1';

read_mapping = 0;



base_path =['/home/ammirato/Data/' room_name];

write_path = [base_path '/labeling/' label_name '/'];
mkdir(write_path);

rgb_images_path = [base_path '/rgb/'];
mapping_label_path = [base_path '/labeling/mapping/labeled_mapping.txt'];

camera_data_path =[ base_path '/reconstruction_results/'];


detections_path = [base_path '/recognition_results/detections/matFiles/'];
detections_suffix = '.p.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
num_total_rgb_images = length(dir([base_path '/rgb_FIX/'])) -2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


cccc = load([base_path '/reconstruction_results/' 'camera_data.mat']);
camera_data_map = cccc.camera_data_map;


write_dir = dir(write_path);
write_dir = write_dir(3:end);

%%%%
%first find all image names that with the object labeled


if(read_mapping)

    fid_map_label = fopen(mapping_label_path);

    %labeled_images = cell(1,1);
    labeled_image_names = cell(1,1);
    labeled_image_points = cell(1,1);
    
    counter = 1;

    %skip header
    for i=1:11
        line = fgetl(fid_map_label);
    end


    %get hand labeled point
    line = fgetl(fid_map_label);
    while(ischar(line))
        line =strsplit(line);

        rgb_filename = line{1};
        x = str2double(line{2});
        y = str2double(line{3});

        label = fgetl(fid_map_label);
        if(strcmp(label,label_name))

            %save this image as one that hsa the object
            %labeled_images{counter} = {rgb_filename,x,y};
            labeled_image_names{counter} = rgb_filename;
            labeled_image_points{counter} = [x y];
            
            counter = counter +1;

            %get the dashed line
            line = fgetl(fid_map_label);

            %get line with image or error
            line = fgetl(fid_map_label);
            while(length(line) > 4)


                line =strsplit(line);

                rgb_filename = line{1};

                %see what's up
                if(strcmp(rgb_filename,'ERROR:'))
                    line = fgetl(fid_map_label);
                    break;
                end

                x = str2double(line{2});
                y = str2double(line{3});

                %save the data
                %labeled_images{counter} = {rgb_filename,x,y};
                labeled_image_names{counter} = rgb_filename;
                labeled_image_points{counter} = [x y];
            
                counter = counter +1;

                %get next line
                line = fgetl(fid_map_label);

            end %while >4
        else
            %read dashed
            line = fgetl(fid_map_label);

            %read the rest of lines for this object
            line = fgetl(fid_map_label);
            while(length(line) > 4)

                %get next line
                line = fgetl(fid_map_label);

            end %while >4
        end%if labels match





        line = fgetl(fid_map_label);
    end




    %now labeled images has filename, x,y for each image that see instance

    %save([write_path 'labeled_images.mat', labeled_images]);

    
    
%     labeled_names = cell(1,length(labeled_images));
%     labeled_points = cell(1,length(labeled_images));
%     for i=1:length(labeled_images)
%         a = labeled_images{i};
%         labeled_names{i} = a{1};
%         labeled_points{i} = [a{2}, a{3}];
%     end
    
    [C,IA,IC] = unique(labeled_image_names);
    
    sIA = sort(IA);
    
    duplicate_indicies = zeros(1,length(labeled_image_names) - length(C));
    
    
    single_counter = 1;
    dup_counter = 1;
    for i=1:length(labeled_image_names)
        if(i == sIA(single_counter))
           single_counter = single_counter +1;
        else
            duplicate_indicies(dup_counter) = i;
            dup_counter = dup_counter +1;
        end
    end
    
    
    %removes duplicates  
    labels_map = containers.Map(labeled_image_names(IA),labeled_image_points(IA));
    
    
    for i=1:length(duplicate_indicies)
        filename = labeled_image_names{duplicate_indicies(i)};
        
        extra_point = labeled_image_points{duplicate_indicies(i)};
        old_label_data = labels_map(filename);
        labels_map(filename) = [old_label_data extra_point(1) extra_point(2)];
        
        
    end
    
    
    labeled_image_names = labels_map.keys;
    
    save([write_path 'labeled_image_names.mat'], 'labeled_image_names');
    save([write_path 'labels_map.mat'], 'labels_map');
    
    
    
    
    
else
    
    labeled_image_names = load([write_path 'labeled_image_names.mat']);
    labeled_image_names = labeled_image_names.labeled_image_names;
    
    labels_map = load([write_path 'labels_map.mat'], 'labels_map');
    labels_map = labels_map.labels_map;

end%if read mapping









    

































%%now find the bouding box with the highest score that contains the 
%%labeled point in each labeled image.




%mat_files = dir([detections_path object_name '/']);
%mat_files = mat_files(3:end);
detections = cell(1,length( labeled_image_names));

depth_of_label = zeros(1,length(labeled_image_names));

max_score = 0;
max_index = 0;

for i=1:length(labeled_image_names)
    
    rgb_filename = labeled_image_names{i};
    
    label_data = labels_map(rgb_filename);
    
    %update the label data to include the depth of the label
    new_label_data = zeros(1,length(label_data)/2 *3);
    for j=1:2:length(label_data)
        label_x = label_data(1);
        label_y = label_data(2);

        depth_of_label = depth_image(floor(label_y), floor(label_x));
        
        index = floor(j/2);
        new_label_data((index*3)+1) = label_x;
        new_label_data((index*3)+2) = label_y;
        new_label_data((index*3)+3) = depth_of_label;
    end
    

    
    
    %get name for detection scores
    file_prefix = rgb_filename(1:(strfind(rgb_filename,'.')-1));
    
    %get index for asscioated depth image
    file_suffix = rgb_filename((strfind(rgb_filename,'b')+1):end);
    depth_image = imread([base_path '/raw_depth/raw_depth' file_suffix]);
    
    
    try
        all_scores = load([detections_path class_name '/' file_prefix detections_suffix]);
    catch
        disp(['could not load detection scores for ' file_prefix]);
        %update the label map to include the depth
        labels_map(rgb_filename) = new_label_data;
        
        detections{i} = [-1 -1 -1 -1 -1];
        continue;
    end
    
    %get the scores from the struct
    all_scores = all_scores.dets;
    
    %sort according to score
    all_scores = sortrows(all_scores, -5);
    
    box_found = 0;
    counter = 1;
    
    while(~box_found && counter <= length(all_scores))
        bbox = all_scores(counter,1:4);
        
        for j=1:2:length(label_data)
            label_x = label_data(1);
            label_y = label_data(2);
            if(label_x >= bbox(1) && label_x <= bbox(3) && ...
               label_y >= bbox(2) && label_y <= bbox(4))
            
                detections{i} = all_scores(counter,:);
                if(all_scores(counter,5) > max_score)
                   max_score = all_scores(counter,5);
                   max_index = counter;
                end
                box_found = 1;
                break;
       
            end %if label is in bounding box
        end
        counter = counter +1; %move to next bbox
    end%while we havent =found a box
    
   
    %update the label map to include the depth
    labels_map(rgb_filename) = new_label_data;
    
end%for i = labeled images

top_detection_per_image = containers.Map(labeled_image_names, detections);

%save the new label_map (but dont overwrite the old one)
save([write_path 'labels_map_depth.mat'], 'labels_map');
save([write_path 'top_detections_per_image.mat'], 'top_detection_per_image');


%depth_of_label_from_image = container.Map(labeled_images,depth_of_label);




max_score_image_name = labeled_image_names{max_index};
max_score_label_data = labels_map(max_score_image_name);
max_score_detection_data = top_detection_per_image(max_score_image_name);
max_score_camera_data = camera_data_map(max_score_image_name);


%max_info_mat = {max_score_image_name, max_score_detection_data,max_score_label_data,max_score_camera_data};


save([write_path 'max_info.mat', 'max_score_image_name'], 'max_score_detection_data', 'max_score_label_data', 'max_score_camera_data');



%max_score_direction = max_camera_data(4:6);
    











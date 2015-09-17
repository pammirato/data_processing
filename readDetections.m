
%%set up some paths 


%which data set to use
room_name = 'KitchenLiving12';

%the class fast-rcnn uses
class_name = 'monitor';

%the label we gave it
label_name = 'monitor2';


%whether or not to read the label mapping(we may have already done this)
read_mapping = 1;



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


cccc = load([camera_data_path 'camera_data.mat']);
camera_data_map = cccc.camera_data_map;


%write_dir = dir(write_path);
%write_dir = write_dir(3:end);



%%%%
%first find all image names that with the object labeled


if(read_mapping)

    %open the mapping file
    fid_map_label = fopen(mapping_label_path);

    %hold all the image names, and the points our label mapped to in them
    labeled_image_names = cell(1,1);
    labeled_image_points = cell(1,1);
    
    
    %separete index because not every image in the file is interesting
    %right now
    counter = 1;

    %skip header
    for i=1:11
        line = fgetl(fid_map_label);
    end


    %get hand labeled point
    line = fgetl(fid_map_label);
    while(ischar(line))
        
        
        %get info from the line
        line =strsplit(line);

        rgb_filename = line{1};
        x = str2double(line{2});
        y = str2double(line{3});

        %get the label
        label = fgetl(fid_map_label);
        
        %if this is the label we care about, save all these
        %filenames/points
        if(strcmp(label,label_name))

            %save this image as one that has the object
            labeled_image_names{counter} = rgb_filename;
            labeled_image_points{counter} = [x y];
            
         
            counter = counter +1;

            %get the dashed line
            line = fgetl(fid_map_label);

            %get line with image or error
            line = fgetl(fid_map_label);
            
            %while the line is not blank, get all the other image infos
            while(length(line) > 4)


                line =strsplit(line);

                rgb_filename = line{1};

                %make sure at least one other image saw this label
                %really only need this check for the first line after dash
                if(strcmp(rgb_filename,'ERROR:'))
                    line = fgetl(fid_map_label);
                    break;
                end

                x = str2double(line{2});
                y = str2double(line{3});

                %save the data
                labeled_image_names{counter} = rgb_filename;
                labeled_image_points{counter} = [x y];
            
                counter = counter +1;

                %get next line
                line = fgetl(fid_map_label);

            end %while >4
            
        else  %this is not the label we care about
            
            %read dashed
            line = fgetl(fid_map_label);

            %read the rest of lines for this object, but dont save
            line = fgetl(fid_map_label);
            while(length(line) > 4)

                %get next line
                line = fgetl(fid_map_label);

            end %while >4
        end%if labels match

        %read the space between label sections
        line = fgetl(fid_map_label);
    end




    %now labeled_image_names has filenames and
    %labeled_image_points has x,y
    %for each image that sees labels

    
    
    %get only the  unique image names, but keep all the points.
    
    %since there are multiple different hand labels for one instance,
    %some images might have multiple labels in them. So they might appear
    %more than once in labeled_image_names, and have more tha none point in
    %labeled_image_points. 
    
    %The goal is to only have the name once in labeled_image_names, and
    %concatenate the points in labeled_image_points
    
    
    %get the unique indices
    [C,IA,IC] = unique(labeled_image_names);
    
    %the indices of unique names, sorted ascending
    sIA = sort(IA);
    
    %will hold the indicies of dupicate names
    duplicate_indicies = zeros(1,length(labeled_image_names) - length(C));
    
    
    original_counter = 1;
    dup_counter = 1;
    
    %for each entry, determine if it is an orginial or duplicate
    for i=1:length(labeled_image_names)
        
        if(original_counter < length(sIA) && i == sIA(original_counter))
           original_counter = original_counter +1;
        else
            duplicate_indicies(dup_counter) = i;
            dup_counter = dup_counter +1;
        end
    end
    
    
    %removes duplicates  when put in the map
    labels_map = containers.Map(labeled_image_names(IA),labeled_image_points(IA));
    
    %now get each original name and point, and concatenate duplicate name's
    %point, and put back in the map
    for i=1:length(duplicate_indicies)
        
        %the name of a duplicate
        filename = labeled_image_names{duplicate_indicies(i)};
        
        %the point from the duplicate(this is different from original
        %point)
        extra_point = labeled_image_points{duplicate_indicies(i)};
        
        %concatenate the points
        old_label_data = labels_map(filename);
        labels_map(filename) = [old_label_data extra_point(1) extra_point(2)];
        
        
    end
    
    %get only the unique names
    labeled_image_names = labels_map.keys;
    
    save([write_path 'labeled_image_names.mat'], 'labeled_image_names');
    save([write_path 'labels_map.mat'], 'labels_map');
    
    
    
    
    
else %read if we already did above
    
    labeled_image_names = load([write_path 'labeled_image_names.mat']);
    labeled_image_names = labeled_image_names.labeled_image_names;
    
    labels_map = load([write_path 'labels_map.mat'], 'labels_map');
    labels_map = labels_map.labels_map;

end%if read mapping









    

































%now find the bouding box with the highest score that contains at least
%one of the labeled points in each labeled image.

%holds highest score and bboxe for each image
detections = cell(1,length( labeled_image_names));


%keep track of the overall best score for this instance(over all images)
max_score = 0;
max_index = 0;


%for each(unique) filename
for i=1:length(labeled_image_names)
    
    rgb_filename = labeled_image_names{i};
    
    %get all the points that are on the instance
    label_data = labels_map(rgb_filename);


    %get name for detection scores
    file_prefix = rgb_filename(1:(strfind(rgb_filename,'.')-1));
    
    %get index for asscioated depth image
    file_suffix = rgb_filename((strfind(rgb_filename,'b')+1):end);
    depth_image = imread([base_path '/raw_depth/raw_depth' file_suffix]);
   




    
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
    

    
    
 
    %try to laod fast-rcnn score for this image (it might not exist!)
    try
        all_scores = load([detections_path class_name '/' file_prefix detections_suffix]);
    catch
        
        %if it doesn't exist, save the depth of he labels, and indicate no
        %detection
        
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
    
    %now get the box with the highest score that containts a labeled point
    
    %while we have not found a box that contains the labeled point
    while(~box_found && counter <= length(all_scores))
        bbox = all_scores(counter,1:4);
        
        %go every 2 b/c x,y
        for j=1:2:length(label_data)
            label_x = label_data(j);
            label_y = label_data(j+1);
            
            %if the point is in the box
            if(label_x >= bbox(1) && label_x <= bbox(3) && ...
               label_y >= bbox(2) && label_y <= bbox(4))
            
           %the first one found is the highest because we sorted
                detections{i} = all_scores(counter,:);
                
                %see if this is the overall max for all images
                if(all_scores(counter,5) > max_score)
                   max_score = all_scores(counter,5);
                   max_index = i;
                end
                box_found = 1;%stop looking at this image
                break;
       
            end %if label is in bounding box
        end
        counter = counter +1; %move to next bbox
    end%while we havent =found a box
    
    %make the point used to pick the bounding box the first in the array
    if(j ~=1)
        point_used = label_data(j:j+1);
        label_data(j:j+1) = label_data(1:2);
        label_data(1:2) = point_used;
    end
   
    %update the label map to include the depth
    labels_map(rgb_filename) = new_label_data;
    
end%for i = labeled images




%save everything



%all the detection scores we found
top_detection_per_image_map = containers.Map(labeled_image_names, detections);

%save the new label_map that has depth (but dont overwrite the old one)
save([write_path 'labels_map_depth.mat'], 'labels_map');
save([write_path 'top_detection_per_image_map.mat'], 'top_detection_per_image_map');


%save data about the overall max score
max_score_image_name = labeled_image_names{max_index};
max_score_label_data = labels_map(max_score_image_name);
max_score_detection_data = top_detection_per_image_map(max_score_image_name);
max_score_camera_data = camera_data_map(max_score_image_name);

save([write_path 'max_info.mat'], 'max_score_image_name', 'max_score_detection_data', 'max_score_label_data', 'max_score_camera_data');


    











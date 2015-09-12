

room_name = 'KitchenLiving12';

class_name = 'monitor';
label_name = 'monitor1';

base_path =['/home/ammirato/Data/' room_name];

rgb_images_path = [base_path 'rgb/'];
mapping_label_path = [base_path '/labeling/labeled_mapping.txt'];

detections_path = [base_path '/recognition_results/detections/matFiles/'];
detections_suffix = '.p.mat';



%%%%
%first find all image names that with the object labeled


fid_map_label = fopen(mapping_label_path);

labeled_images = cell(1,1);
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
    x = str2num(line{2});
    y = str2num(line{3});

    label = fgetl(fid_map_label);
    if(strcmp(label,label_name))
        
        %save this image as one that hsa the object
        labeled_images{counter} = {rgb_filename,x,y};
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

            x = str2num(line{2});
            y = str2num(line{3});
            
            %save the data
            labeled_images{counter} = {rgb_filename,x,y};
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
















%mat_files = dir([detections_path object_name '/']);
%mat_files = mat_files(3:end);
detections = zeros(length( labeled_images),5);


for i=1:1%length(labeled_images)
    label_data = labeled_images{i};
    rgb_filename = label_data{1};
    
    label_x = label_data{2};
    label_x = label_x(1);
    label_y = label_data{3};
    label_y = label_y(1);
    
    
    file_prefix = rgb_filename(1:(strfind(rgb_filename,'.')-1));
    
    try
        all_scores = load([detections_path class_name '/' file_prefix detections_suffix]);
    catch
        disp(['could not load detection scores for ' file_prefix]);
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
        
        if(label_x >= bbox(1) && label_x <= bbox(3) && ...
                label_y >= bbox(2) && label_y <= bbox(4))
            
            box_found = 1;
            detections(i,:) = all_scores(counter,:);
        end %if label is in bounding box
    end%while we havent =found a box
    
end%for i = labeled images


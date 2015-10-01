
%For one object instance in a scene:
%
%find and save names of all images that see that instance
%save a map from an image names, to a list of points in that image(pixels) that are on the instance
%
%i.e. if image rgb3K1.png has a monitor in it, the map will return at least one point in the image 
%		that is on the monitor. 
%


%which data set to use
room_name = 'KitchenLiving12';

%the class fast-rcnn or some detector uses
class_name = 'monitor';

%the label we gave it
label_name = 'monitor2';







%path to eveything in this scene
base_path =['/home/ammirato/Data/' room_name];

%where to save everything
write_path = [base_path '/labeling/' label_name '/'];
mkdir(write_path);


rgb_images_path = [base_path '/rgb/'];

%path to file that has all images that see labeled points
mapping_label_path = [base_path '/labeling/mapping/labeled_mapping.txt'];

%path to the camera data(positions/orientations)
camera_data_path =[ base_path '/reconstruction_results/'];

%where the results of the detector is
%detections_path = [base_path '/recognition_results/detections/matFiles/'];
%detections_suffix = '.p.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
num_total_rgb_images = length(dir([base_path '/rgb/'])) -2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%load camera data
cccc = load([camera_data_path 'camera_data.mat']);
camera_data_map = cccc.camera_data_map;





%%%%
%first find all image names that with the object labeled



%open the file that has all images that see each labeled point in the scene
fid_map_label = fopen(mapping_label_path);

%hold all the image names, and the points where the instance is in the image
labeled_image_names = cell(1,1);
labeled_image_points = cell(1,1);


%separete index because not every image in the file is interesting
counter = 1;

%skip header
for i=1:11
    line = fgetl(fid_map_label);
end


%now go through each labeled point, see if the label is the same as our instance, 
%if so then keep track of all the images that see that point, othewise skip them


%get hand labeled point
line = fgetl(fid_map_label);
while(ischar(line))
    
    
    %get image name and point
    line =strsplit(line);

    rgb_filename = line{1};
    x = str2double(line{2});
    y = str2double(line{3});

    %get the label
    label = fgetl(fid_map_label);
    
    %if this is the label we care about, save all these image names and the point
    if(strcmp(label,label_name))

    %%%START  - save just the first one (its a tiny different cause it was hand labeled)

        %save this image as one that has the object
        labeled_image_names{counter} = rgb_filename;
        
        
        file_suffix = rgb_filename((strfind(rgb_filename,'b')+1):end);
        depth_image = imread([base_path '/raw_depth/raw_depth' file_suffix]);
        depth_of_label = depth_image(floor(y), floor(x));
        labeled_image_points{counter} = [x y depth_of_label];
        
        
        counter = counter +1;

        %get the dashed line
        line = fgetl(fid_map_label);

        %%%END   - save just the first one


        %get line with image or error(see below)
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


            file_suffix = rgb_filename((strfind(rgb_filename,'b')+1):end);
            depth_image = imread([base_path '/raw_depth/raw_depth' file_suffix]);
            depth_of_label = depth_image(floor(y), floor(x));
            labeled_image_points{counter} = [x y depth_of_label];

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
    labels_map(filename) = [old_label_data extra_point(1) extra_point(2) extra_point(3)];
    
    
end

%get only the unique names
labeled_image_names = labels_map.keys;

save([write_path 'names_of_images_that_see_instance.mat'], 'labeled_image_names');
save([write_path 'map_image_name_to_labeled_points.mat'], 'labels_map');


    
    
    





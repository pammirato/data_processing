

%this would hange for evey object
room_name = 'KitchenLiving12';

%where to get the images from
images_path = ['/home/ammirato/Data/' room_name '/'];

%holds the points the user clicked on in world coordinates.
points = cell(1,1);
labels = cell(1,1);
images_used = cell(1,1);
%num_points = 1;

%load the images
%[rgb_images image_names] = readImages([images_path 'rgb/'], step_size); 
rgb_files = dir([images_path 'rgb/']);
rgb_files = rgb_files(3:end);

%sort the image file names by time
[~,index] = sortrows({rgb_files.date}.'); 
rgb_files = rgb_files(index); 
clear index;


unreg_prefix = 'unreg_depth';
raw_prefix = 'raw_depth';

rgb_save_path = [images_path 'new_rgb/'];
unreg_depth_save_path = [images_path 'new_unreg_depth/'];
raw_depth_save_path = [images_path 'new_raw_depth/'];


counter = 0;

for i=1:length(rgb_files)
    
    org_name = rgb_files(i).name;
    
    prefix_index = strfind(org_name, 'b');
    suffix_index = strfind(org_name, 'K');
    
    org_stamp = org_name(prefix_index+1:suffix_index-1);
    rgb_prefix = org_name(1:prefix_index);
    suffix = org_name(suffix_index:end);
    
    %get rid of old stamp prefix
    %if(strcmp(org_stamp(1:4),'1111'))
    %    org_stamp = org_stamp(5:end);
    %elseif(strcmp(org_stamp(1:4),'2222'))
    %    org_stamp = org_stamp(5:end);
    %end
    
    counter_string = org_stamp;
    if(length(counter_string) < 6)
        pad = '';
        for i=1:(5-length(counter_string))
            pad = [pad '0'];
        end
        counter_string = [pad counter_string];
    end
    
    
    movefile([images_path 'rgb/' org_name], ... 
                [images_path 'rgb_fix/' rgb_prefix counter_string suffix]);
     
    movefile([images_path 'unreg_depth/unreg_depth' org_stamp suffix], ...
                [images_path 'unreg_depth_fix/' unreg_prefix counter_string suffix]);
    
    %movefile([images_path 'raw_depth/raw_depth' org_stamp suffix], ...
     %           [raw_prefix num2str(counter) suffix]);
         
   
    counter = counter +1;
    
end


  
    
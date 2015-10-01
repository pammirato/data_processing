
base_path = '/home/ammirato/Data/KitchenLiving12/';

rgb_images_path = [base_path 'rgb/'];
mapping_label_path = [base_path '/labeling/labeled_mapping.txt'];



fid_map_label = fopen(mapping_label_path);


%rgb_files = dir(rgb_images_path);
%rgb_files = rgb_files(3:end);

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

    label = fgetl(fid_map_label)
    
    %get the dashed line
    line = fgetl(fid_map_label);
    
    imshow(imread([rgb_images_path rgb_filename]));
    hold on;
    scatter(x,y,15,'r');
    [xi, gi, but] = ginput(1);
    hold off;
    
    line = fgetl(fid_map_label);
    f = figure;
    
    while(length(line) > 4)
        
       
        line =strsplit(line);
    
        rgb_filename = line{1};
        
        if(strcmp(rgb_filename,'ERROR:'))
            line = fgetl(fid_map_label);
            break;
        end
        
        x = str2num(line{2});
        y = str2num(line{3});

        
        imshow(imread([rgb_images_path rgb_filename]));
        hold on;
        scatter(x,y,15,'r');
        
        
        [xi, gi, but] = ginput(1);
        hold off;
        
        
        line = fgetl(fid_map_label);
        
        %if done with this initial image
        if(but ~= 1)
            while(length(line) > 4)
               line = fgetl(fid_map_label); 
            end
            
        end%if but
        
        
        
        
        
    end
    close all;
        
    line = fgetl(fid_map_label);
end
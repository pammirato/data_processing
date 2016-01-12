%renames files to just numbered indices, saves a map back to original names


clear;
init; 


scene_name = 'FB341_2';  %make this = 'all' to go through all rooms






d = dir(BASE_PATH);
d = d(3:end);

if(strcmp(scene_name,'all'))
    num_rooms = length(d);
else
    num_rooms = 1;
end

for i=1:num_rooms
    
    if(num_rooms >1)
        scene_name = d(i).name();
        break;
    end
    
    scene_path = fullfile(BASE_PATH,scene_name);
    
    dr = dir(fullfile(BASE_PATH, scene_name,RGB_IMAGES_DIR));
    dr = dr(3:end);
    
    
    org_rgb_names = {dr.name};
    new_rgb_names = cell(1,length(org_rgb_names));
    
    
    ones_base_index = 500;
    twos_base_index = ones_base_index + 900;

    
    for j=1:length(org_rgb_names)
        
        org_rgb_name = org_rgb_names{j};
        index = org_rgb_name(4:end-6);
        
        if(length(index) > 4)
            if(strcmp(index(1:4), '1111'))
                old_counter = index(5:end);
                old_counter = str2num(old_counter);
                
                new_index = num2str(ones_base_index + old_counter);
                
                new_rgb_names{j} = strcat(org_rgb_name(1:3),new_index,org_rgb_name(end-5:end)); 
                
            else
                assert(strcmp(index(1:4),'2222'));
                
                old_counter = index(5:end);
                old_counter = str2num(old_counter);
                
                new_index = num2str(twos_base_index + old_counter);
                
                new_rgb_names{j} = strcat(org_rgb_name(1:3),new_index,org_rgb_name(end-5:end)); 
  
            end% if '1111'
            
        else
            new_rgb_names{j} = org_rgb_names{j};
                        
        end%if length > 4
        
       
    end%for j
    
    
    

    
    
    
    name_map1 = containers.Map(org_rgb_names,new_rgb_names);
    
    save(fullfile(BASE_PATH,scene_name, 'name_mapping1.mat'),'name_map1');
  
    
    for j=1:length(org_rgb_names)
        j
        org_rgb_name = org_rgb_names{j};
        
        org_unreg_depth_name = strcat('unreg_depth',org_rgb_name(4:end));
        org_raw_depth_name = strcat('raw_depth',org_rgb_name(4:end));
        org_rgb_jpg_name = strcat(org_rgb_name(1:end-3),'jpg');
        
        
        kinect_id = strcat('0',org_rgb_name(end-4));
        
        
        new_rgb_name = new_rgb_names{j};
        new_unreg_depth_name = strcat('unreg_depth',new_rgb_name(4:end));
        new_raw_depth_name = strcat('raw_depth',new_rgb_name(4:end));
        new_rgb_jpg_name = strcat('rgb',new_rgb_name(4:end-3),'jpg');
        

        if(strcmp(org_rgb_name,new_rgb_name))
            continue;
        end
        
        assert(movefile(fullfile(scene_path,RGB_IMAGES_DIR, org_rgb_name), ...
                 fullfile(scene_path,RGB_IMAGES_DIR, new_rgb_name)));
             
        assert(movefile(fullfile(scene_path,UNREG_DEPTH_IMAGES_DIR, org_unreg_depth_name), ...
                 fullfile(scene_path,UNREG_DEPTH_IMAGES_DIR, new_unreg_depth_name)));
             
        assert(movefile(fullfile(scene_path,RAW_DEPTH_IMAGES_DIR, org_raw_depth_name), ...
                 fullfile(scene_path,RAW_DEPTH_IMAGES_DIR, new_raw_depth_name)));
             
%         assert(movefile(fullfile(scene_path,RGB_JPG_IMAGES_DIR, org_rgb_jpg_name), ...
%                  fullfile(scene_path,RGB_JPG_IMAGES_DIR, new_rgb_jpg_name)));

    end%for j
    
    
    

    
    
    
    
    
end%for i, each room
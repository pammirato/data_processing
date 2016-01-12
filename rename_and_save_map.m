%renames files to just numbered indices, saves a map back to original names


clear;
init; 


scene_name = 'FB241B';  %make this = 'all' to go through all rooms






d = dir(BASE_PATH);
d = d(3:end);

if(strcmp(scene_name,'all'))
    num_rooms = length(d);
else
    num_rooms = 1;
end

for i=1:num_rooms
    
    if(num_rooms >1)
        scene_name = d(i).name()
    end
    
    scene_path = fullfile(BASE_PATH,scene_name);
    
    dr = dir(fullfile(BASE_PATH, scene_name,RGB_IMAGES_DIR));
    dr = dr(3:end);
    
    
    org_rgb_names = {dr.name};
    
    %*3 so there are extra slots, because files may have been deleted
    sorted_org_rgb_names = cell(1,length(org_rgb_names)*3 +200);
    
    if(isempty(strfind(org_rgb_names{1},'rgb')))
        continue;
    end
    
    %sort the original names
    for j=1:length(org_rgb_names)
        
        name = org_rgb_names{j};
        if(strcmp(name(1),'2'))
            index = name(8:end-6);
            %plus one cause matlab is 1 based
            index = str2num(index) +1 + length(org_rgb_names);
            
        else
            index = name(4:end-6);        

            %plus one cause matlab is 1 based
            index = str2num(index) +1;
        
        end
        k_index = str2num(name(end-4));
        sorted_org_rgb_names{(index-1)*3 +k_index} = name;
       
    end%for j
    
    
    sorted_org_rgb_names = sorted_org_rgb_names(find(~cellfun('isempty',sorted_org_rgb_names)));
    
    assert(length(sorted_org_rgb_names) > 1);
    assert(length(sorted_org_rgb_names) == length(org_rgb_names));
    assert(length(sorted_org_rgb_names) == length(unique(sorted_org_rgb_names)));
    
    
    
    %new_names = cell(1,length(org_names));
    
%     new_indices = [1:length(org_rgb_names)];
%     new_indices = num2str(new_indices,'%06d ');
%     
%     new_indices = strsplit(new_indices);
    
    new_indices = -ones(1,length(sorted_org_rgb_names));
    
    
    next_new_index = 1;
    for j=1:length(sorted_org_rgb_names)
        
        if(new_indices(j) ~= -1)
            continue;
        end
        
        new_indices(j) = next_new_index;
        
        org_name = sorted_org_rgb_names{j};
        org_index = org_name(4:end-6);

        %now check if the next images should have the same index
        if( j < length(sorted_org_rgb_names))
            next_name = sorted_org_rgb_names{j+1};
            if(strcmp(org_index,next_name(4:end-6)))
                new_indices(j+1) = next_new_index;

                if(j < length(sorted_org_rgb_names)-1)
                    next_next_name = sorted_org_rgb_names{j+2};
                    if(strcmp(org_index,next_next_name(4:end-6)))
                        new_indices(j+2) = next_new_index;
                    end
                end
            end
        end%if J <length

        next_new_index = next_new_index +1;

    end
    new_indices = num2str(new_indices,'%06d ');
    new_indices = strsplit(new_indices);
    
    
    new_rgb_names = cell(1,length(org_rgb_names));
    
%     map = containers.Map(sorted_org_names,new_inidices);
%     
%     save(fullfile(BASE_PATH,scene_name, 'name_map.mat'),'map');
    
    
    
    for j=1:length(sorted_org_rgb_names)
        org_rgb_name = sorted_org_rgb_names{j};
        
%         org_unreg_depth_name = strcat('unreg_depth',org_rgb_name(4:end));
%         org_raw_depth_name = strcat('raw_depth',org_rgb_name(4:end));
%         org_rgb_jpg_name = strcat(org_rgb_name(1:end-3),'jpg');
%         
%         
        kinect_id = strcat('0',org_rgb_name(end-4));
        
        
        new_rgb_name = strcat(new_indices{j}, kinect_id, RGB_INDEX_STRING,'.png');
%         new_unreg_depth_name = strcat(new_indices{j}, kinect_id, UNREG_DEPTH_INDEX_STRING,'.png');
%         new_raw_depth_name = strcat(new_indices{j}, kinect_id, RAW_DEPTH_INDEX_STRING,'.png');
%         new_rgb_jpg_name = strcat(new_indices{j}, kinect_id, RGB_JPG_INDEX_STRING,'.jpg');
%         
        %save for map later
        new_rgb_names{j} = new_rgb_name;
        
        
    end
    
    %make sure we have the same amount of file names
    assert(length(org_rgb_names) == length(unique(new_rgb_names)));  
    
    assert(~strcmp(new_rgb_names{1},sorted_org_rgb_names{1}));
    
    name_map = containers.Map(new_rgb_names,sorted_org_rgb_names);
    save(fullfile(BASE_PATH,scene_name, NAME_MAP_FILE),NAME_MAP);
    
    
    
    
    for j=1:length(sorted_org_rgb_names)
        
        org_rgb_name = sorted_org_rgb_names{j};
        new_rgb_name = new_rgb_names{j};
        
        org_unreg_depth_name = strcat('unreg_depth',org_rgb_name(4:end));
        org_raw_depth_name = strcat('raw_depth',org_rgb_name(4:end));
        org_rgb_jpg_name = strcat(org_rgb_name(1:end-3),'jpg');
        
        
        kinect_id = strcat('0',org_rgb_name(end-4));
        
        
        %new_rgb_name = strcat(new_indices{j}, kinect_id, RGB_INDEX_STRING,'.png');
        new_unreg_depth_name = strcat(new_indices{j}, kinect_id, UNREG_DEPTH_INDEX_STRING,'.png');
        new_raw_depth_name = strcat(new_indices{j}, kinect_id, RAW_DEPTH_INDEX_STRING,'.png');
        new_rgb_jpg_name = strcat(new_indices{j}, kinect_id, RGB_JPG_INDEX_STRING,'.jpg');
       
        
        if(strcmp(org_rgb_name,new_rgb_name))
            continue;
        end
        
        
        if(exist(fullfile(scene_path,RGB_IMAGES_DIR, org_rgb_name),'file') ==2 && ...
                exist(fullfile(scene_path,UNREG_DEPTH_IMAGES_DIR, org_unreg_depth_name),'file')==2)
        
            assert(movefile(fullfile(scene_path,RGB_IMAGES_DIR, org_rgb_name), ...
                            fullfile(scene_path,RGB_IMAGES_DIR, new_rgb_name)));

            assert(movefile(fullfile(scene_path,UNREG_DEPTH_IMAGES_DIR, org_unreg_depth_name), ...
                            fullfile(scene_path,UNREG_DEPTH_IMAGES_DIR, new_unreg_depth_name)));

            assert(movefile(fullfile(scene_path,RAW_DEPTH_IMAGES_DIR, org_raw_depth_name), ...
                            fullfile(scene_path,RAW_DEPTH_IMAGES_DIR, new_raw_depth_name)));

            if(exist(fullfile(scene_path,JPG_RGB_IMAGES_DIR),'dir') == 7)
                assert(movefile(fullfile(scene_path,JPG_RGB_IMAGES_DIR, org_rgb_jpg_name), ...
                                fullfile(scene_path,JPG_RGB_IMAGES_DIR, new_rgb_jpg_name))); 
            end
        
        end
% %         movefile(fullfile(scene_path,RGB_JPG_IMAGES_DIR,strcat(org_name(1:end-3),'jpg')), ...
%                  fullfile(scene_path,RGB_JPG_IMAGES_DIR,strcat(new_inidices{j},'.jpg')));
       
    end%for j
    
    

    
    
    
    
end%for i, each room
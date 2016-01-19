%renames files to just numbered indices, saves a map back to original names



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
        scene_name = d(i).name();
    end
    
    scene_path = fullfile(BASE_PATH,scene_name);
    
   
    name_map = load(fullfile(scene_path,NAME_MAP_FILE));
    name_map = name_map.(NAME_MAP);
    
    new_rgb_names = name_map.keys;
    
    
    for j=1:length(new_rgb_names)
       new_rgb_name = new_rgb_names{j};
        
       org_rgb_name = name_map(new_rgb_name);
       
       new_unreg_depth_name = new_rgb_name;
       new_unreg_depth_name(9:10) = UNREG_DEPTH_INDEX_STRING;
       
       new_raw_depth_name = new_rgb_name;
       new_raw_depth_name(9:10) = RAW_DEPTH_INDEX_STRING;
       
       new_rgb_jpg_name = new_rgb_name;
       new_rgb_jpg_name(9:10) = RGB_JPG_INDEX_STRING;

       
       org_unreg_depth_name = strcat('unreg_depth',org_rgb_name(4:end));
       
       org_raw_depth_name = strcat('raw_depth',org_rgb_name(4:end));
       org_rgb_jpg_name = strcat(org_rgb_name(1:end-3),'jpg');
       
       
       
               
        if(exist(fullfile(scene_path,RGB_IMAGES_DIR, new_rgb_name),'file') ==2 && ...
                exist(fullfile(scene_path,UNREG_DEPTH_IMAGES_DIR, new_unreg_depth_name),'file')==2)
        
            assert(movefile(fullfile(scene_path,RGB_IMAGES_DIR, new_rgb_name), ...
                            fullfile(scene_path,RGB_IMAGES_DIR, org_rgb_name)));

            assert(movefile(fullfile(scene_path,UNREG_DEPTH_IMAGES_DIR, new_unreg_depth_name), ...
                            fullfile(scene_path,UNREG_DEPTH_IMAGES_DIR, org_unreg_depth_name)));

            assert(movefile(fullfile(scene_path,RAW_DEPTH_IMAGES_DIR, new_raw_depth_name), ...
                            fullfile(scene_path,RAW_DEPTH_IMAGES_DIR, org_raw_depth_name)));

            if(exist(fullfile(scene_path,JPG_RGB_IMAGES_DIR),'dir') == 7)
                assert(movefile(fullfile(scene_path,RGB_JPG_IMAGES_DIR, new_rgb_jpg_name), ...
                                fullfile(scene_path,RGB_JPG_IMAGES_DIR, org_rgb_jpg_name))); 
            end
        
        end

        
    end
    
    
    
    
    
end%for i, each room
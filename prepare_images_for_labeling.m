%renames files to just numbered indices, saves a map back to original names



init; 


scene_name = 'FB209';  %make this = 'all' to go through all rooms

scene_path = fullfile(BASE_PATH,scene_name);

%get the map to find all the interesting images
label_to_images_that_see_it_map = load(fullfile(scene_path,LABELING_DIR,...
                                    DATA_FOR_LABELING_DIR, ...
                                    LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE));
 
label_to_images_that_see_it_map = label_to_images_that_see_it_map.(LABEL_TO_IMAGES_THAT_SEE_IT_MAP);
             
             
             
%get the structs with IMAGE_NAME, X, Y, DEPTH for images that see this
%instance
label_structs = label_to_images_that_see_it_map(instance_name);

%get all the image names
temp = cell2mat(label_structs);
image_names = {temp.(IMAGE_NAME)};
clear temp;

org_names = image_names;



d = dir(fullfile(scene_path, RGB_IMAGES_DIR));
d = d(3:end);


sorted_org_names = cell(1,length(d));
sorted_label_structs = cell(1,length(d));


%sort the original names
for j=1:length(org_names)

    name = org_names{j};
    ls = label_structs{j};
    
    index = name(4:end-6);

    k_index = str2num(name(end-4));

    %plus one cause matlab is 1 based
    index = str2num(index) +1;


    sorted_org_names{(index-1)*3 +k_index} = name;
    
    sorted_label_structs{(index-1)*3 +k_index} = ls;

end%for j


%pick out non-empty cells
sorted_org_names = sorted_org_names(find(~cellfun('isempty',sorted_org_names)));
sorted_label_structs = sorted_label_structs(find(~cellfun('isempty',sorted_label_structs)));











%new_names = cell(1,length(org_names));

new_indices = [1:length(sorted_org_names)];
new_names = num2str(new_indices,'%06d ');

new_names = strsplit(new_names);


map = containers.Map(sorted_org_names,new_names);

save(fullfile(BASE_PATH,scene_name, 'name_map.mat'),'map');



for j=1:length(sorted_org_names)
    org_name = sorted_org_names{j};
    movefile(fullfile(scene_path,RGB_JPG_IMAGES_DIR,strcat(org_name(1:end-3),'jpg')), ...
             fullfile(scene_path,RGB_JPG_IMAGES_DIR,strcat(new_names{j},'.jpg')));

end%for j


    
    
   
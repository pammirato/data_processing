

scene_name = 'Office_01_2';


rgb = 0;


%folder_path = '/playpen/ammirato/Data/RohitData/Kitchen_Living_11/rgb/';
if(rgb)
  folder_path = fullfile('/playpen/ammirato/Data/RohitMetaData' ,scene_name, 'reconstruction_setup', 'rgb');% ...
                        %'reconstruction_setup',  'hand_scan/rgb_chosen');
  folder_path_new = fullfile('/playpen/ammirato/Data/RohitMetaData',scene_name,'reconstruction_setup', 'rgb_new');% ...
else                           % 'reconstruction_setup', 'hand_scan/rgb_renamed');
  folder_path = fullfile('/playpen/ammirato/Data/RohitMetaData' ,scene_name,'reconstruction_setup', 'raw_depth');
  folder_path_new = fullfile('/playpen/ammirato/Data/RohitMetaData',scene_name,'reconstruction_setup', 'raw_new');
end


mkdir(folder_path_new);

d = dir(fullfile(folder_path, '*.png'));

org_names = {d.name};

for il = 1:length(org_names)

  old_name = org_names{il};

  new_index_string = sprintf('%06d', il);

  if(~strcmp(old_name(1:6), new_index_string))

    new_name = strcat(new_index_string, old_name(7:end)); 

    movefile(fullfile(folder_path, old_name), fullfile(folder_path_new, new_name));
    %copyfile(fullfile(folder_path, old_name), fullfile(folder_path_new, new_name));
  end
end


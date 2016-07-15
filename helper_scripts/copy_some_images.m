

scene_name = 'Kitchen_Living_03_1';



%folder_path = '/playpen/ammirato/Data/RohitData/Kitchen_Living_11/rgb/';
names_path = fullfile('/playpen/ammirato/Data/RohitMetaData', scene_name, ...
                     'labels', 'wei_label_files');
org_path = fullfile('/playpen/ammirato/Data/RohitData' ,scene_name, 'rgb');% ...
                        %'reconstruction_setup',  'hand_scan/rgb_chosen');
new_path = fullfile('/playpen/ammirato/Data/RohitMetaData',scene_name, 'labels', ...
                       'rgb');% ...
                           % 'reconstruction_setup', 'hand_scan/rgb_renamed');
%folder_path = fullfile('/playpen/ammirato/Data/RohitMetaData' ,scene_name, 'raw_depth');
%folder_path_new = fullfile('/playpen/ammirato/Data/RohitMetaData',scene_name, 'raw_new');



mkdir(new_path);

d = dir(fullfile(names_path, '*.txt'));

org_names = {d.name};

for il = 1:length(org_names)

  name = org_names{il};

  rgb_name = strcat(name(1:10), '.png');

  copyfile(fullfile(org_path,rgb_name), fullfile(new_path, rgb_name));
end


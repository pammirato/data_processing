



folder_path = '/playpen/ammirato/Data/RohitData/Kitchen_Living_11/to_rename/';


start_ind = 689;

assert(start_ind > 99 && start_ind < (1000-12));

d = dir(fullfile(folder_path, '*.png'));

org_names = {d.name};

for il = 1:length(org_names)

  old_name = org_names{il};

  new_name = strcat(old_name(1:3), num2str(start_ind + il -1), old_name(7:end)); 

  movefile(fullfile(folder_path, old_name), fullfile(folder_path, new_name));

end


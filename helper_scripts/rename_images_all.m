



%folder_path = '/playpen/ammirato/Data/RohitData/Kitchen_Living_11/rgb/';
folder_path = '/playpen/ammirato/Data/RohitMetaData/Bedroom11/hand_scan/rgb/';




d = dir(fullfile(folder_path, '*.png'));

org_names = {d.name};

for il = 1:length(org_names)

  old_name = org_names{il};

  new_index_string = sprintf('%06d', il+4000);

  if(~strcmp(old_name(1:6), new_index_string))

    new_name = strcat(new_index_string, old_name(7:end)); 

    movefile(fullfile(folder_path, old_name), fullfile(folder_path, new_name));
  end
end


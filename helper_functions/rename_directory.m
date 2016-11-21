function [] = rename_directory(dir_name, scene_path, org_to_new_index_map)
%Renames all images in a given directory 

  org_dir = fullfile(scene_path, dir_name);
  new_dir = fullfile(scene_path, strcat(dir_name,'_renamed'));

  mkdir(new_dir);

  temp = dir(org_dir);
  temp = temp(3:end);
  org_names = {temp.name};
  ex_name = temp(3).name;
  

  for jl=1:length(org_names)
    org_name = org_names{jl};
    try
      new_index = org_to_new_index_map(org_name(1:6));
    catch
      delete(fullfile(org_dir, org_name));
      continue;
    end
    new_name = strcat(new_index,org_name(7:end));

    movefile(fullfile(org_dir,org_name), fullfile(new_dir,new_name));
  end%for jl
                               
  rmdir(org_dir);
  movefile(new_dir,org_dir); 

end 

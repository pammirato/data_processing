function [instance_name_to_id_map] = get_instance_name_to_id_map()
% return a map from string instance name to numeric id

  init;

  %load text file mapping from instance name to category id
  instance_name_to_id_map = containers.Map();
  fid_bb_map = fopen(fullfile(ROHIT_METAMETA_BASE_PATH,'instance_id_map.txt'), 'rt');

  line = fgetl(fid_bb_map);
  while(ischar(line))
    line = strsplit(line);
    instance_name_to_id_map(line{1}) = str2double(line{2}); 
    line = fgetl(fid_bb_map);
  end
  fclose(fid_bb_map);

end

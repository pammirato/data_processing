
base = fullfile('/playpen/ammirato/Downloads/val2014/');

d = dir();
image_names = {d(30:end).name};

for il=1:500

  cur_image_name = image_names{il};

  movefile(fullfile(base, cur_image_name), fullfile('/playpen/ammirato/Downloads/temp_images/',cur_image_name));
end


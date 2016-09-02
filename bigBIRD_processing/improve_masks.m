clearvars;
init_bigBIRD;


%TODO - add   rotation
%             alpha composition
%             illumination
%





debug = 1;

d = dir(BIGBIRD_BASE_PATH);
object_names = {d(3:end).name};
object_names = {'progresso_new_england_clam_chowder'};


%load mapping from bigbird name ot category id
obj_cat_map = containers.Map();
fid_bb_map = fopen('/playpen/ammirato/Data/RohitMetaMetaData/big_bird_cat_map.txt', 'rt');

line = fgetl(fid_bb_map);
while(ischar(line))
  line = strsplit(line);
  obj_cat_map(line{1}) = str2double(line{2}); 
  line = fgetl(fid_bb_map);
end
fclose(fid_bb_map);




for il=1:length(object_names)

  cur_bb_name = object_names{il};
  image_names = dir(fullfile(BIGBIRD_BASE_PATH, object_names{il}, 'rgb', '*.jpg'));
  image_names = {image_names.name};


  %for each object chosen, put in the image with random parameters
  for jl=1:length(image_names)


    rgb_name = image_names{jl};
    mask_name = strcat(rgb_name(1:end-4), '_mask.pbm');

    %load the chosen image
    object_img = imread(fullfile(BIGBIRD_BASE_PATH, cur_bb_name, 'rgb', rgb_name)); 

    %load the object mask for the chosen image
    object_mask = imread(fullfile(BIGBIRD_BASE_PATH, cur_bb_name, 'masks', mask_name));


    if(debug)
      imshow(object_img);
      hold on;
      h = imagesc(object_mask);
      set(h, 'AlphaData', .5);
      hold off;
      ginput(1);
    end 
  end
end%for il, each background image












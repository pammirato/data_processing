clearvars;
init_bigBIRD;


%TODO - add   rotation
%             alpha composition
%             illumination
%





debug = 0;

d = dir(BIGBIRD_BASE_PATH);
object_names = {d(3:end).name};
%object_names = {'listerine_green'};


%load mapping from bigbird name ot category id
%obj_cat_map = containers.Map();
%fid_bb_map = fopen('/playpen/ammirato/Data/RohitMetaMetaData/big_bird_cat_map.txt', 'rt');
%
%line = fgetl(fid_bb_map);
%while(ischar(line))
%  line = strsplit(line);
%  obj_cat_map(line{1}) = str2double(line{2}); 
%  line = fgetl(fid_bb_map);
%end
%fclose(fid_bb_map);

save_base_path = fullfile('/playpen/ammirato/Data/cropped_bigBIRD');


for il=1:length(object_names)

  cur_bb_name = object_names{il};
  disp(cur_bb_name);
  image_names = dir(fullfile(BIGBIRD_BASE_PATH, object_names{il}, 'rgb', '*.jpg'));
  image_names = {image_names.name};
 
  save_path = fullfile(save_base_path,cur_bb_name);
  if(~exist(save_path,'dir'))
    mkdir(save_path);
  end
 
  %for each object chosen, put in the image with random parameters
  for jl=1:length(image_names)


    rgb_name = image_names{jl};

    %% load the chosen image
    object_img = imread(fullfile(BIGBIRD_BASE_PATH, cur_bb_name, 'rgb', rgb_name)); 


    object_img = object_img(220:830, 380:925, :);

     

    img_save_path = fullfile(save_path,strcat(rgb_name(1:end-4), '.jpg'));

    imwrite(object_img,img_save_path);
  end

end





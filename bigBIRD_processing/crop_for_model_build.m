%crops the original BigBIRD images in a predefined crop
%an attempt to remove the statinoary background in the bigBird images

init_bigBIRD;



d = dir(BIGBIRD_BASE_PATH);
object_names = {d(3:end).name};

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

    %crop the image
    object_img = object_img(220:830, 380:925, :);
    %save croppped image
    img_save_path = fullfile(save_path,strcat(rgb_name(1:end-4), '.jpg'));
    imwrite(object_img,img_save_path);
  end
end





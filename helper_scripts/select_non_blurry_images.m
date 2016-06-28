clearvars;


scene_name= 'Kitchen_Living_02_2';


base_path = '/playpen/ammirato/Data/RohitMetaData';

base_path = fullfile(base_path, scene_name);

hand_scan_path = fullfile(base_path, 'hand_scan');

rgb_image_path = fullfile(hand_scan_path, 'rgb');
rgb_chosen_path = fullfile(hand_scan_path, 'rgb_chosen');

mkdir(rgb_chosen_path);

rgb_image_names = dir(fullfile(rgb_image_path, '*.png'));
rgb_image_names = {rgb_image_names.name};


for il=1:length(rgb_image_names)


  cur_image_name = rgb_image_names{il};

  rgb_img = imread(fullfile( rgb_image_path, cur_image_name));


  imshow(rgb_img);

  [x, y, but] = ginput(1);



  if(but ~=1)

    movefile(fullfile(rgb_image_path, cur_image_name), ...
            fullfile(rgb_chosen_path, cur_image_name));

  end

end%for il


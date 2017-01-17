

source = fullfile('/playpen/ammirato/Data/big_bird_instance_singles');

image_names = dir(fullfile(source,'*.jpg'));
image_names = {image_names.name};

cols = 5;

counter = 1;


html_fid = fopen(fullfile(source,'table2.html'), 'wt');

for il=1:length(image_names)
%  img = imread(fullfile(source,image_names{il}));
%
%  img = img(313:733,510:799,:);
%  imwrite(img,fullfile(source,image_names{il}));

  fprintf(html_fid, strcat('<td><img src="images/', image_names{il}, '" style="width:304px;height:228px;">', image_names{il}, '</td>\n'));


end

fclose(html_fid);




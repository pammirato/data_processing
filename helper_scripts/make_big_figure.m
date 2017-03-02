
%initialize contants, paths and file names, etc. 
clearvars;
init;



%% USER OPTIONS
load_path = fullfile('/playpen/ammirato/Pictures/icra_2016_figures/images_to_agg');
save_path = fullfile('/playpen/ammirato/Pictures/icra_2016_figures/');

image_names = {'000732_crystal.tif', '000840_crystal.tif','000900_crystal.tif',...
                '000936_crystal.tif','000957_crystal.tif','000969_crystal.tif' };
              
image_names = dir(fullfile(load_path));
image_names = image_names(3:end);
image_names = {image_names.name};
image_names = image_names(end:-1:1);

              
border = 50;

crs = 44;
cre = 1170;%230;
ccs = 145;
cce = 2145;

sub_rows = 2;
sub_cols = 2;


%% SET UP GLOBAL DATA STRUCTURES

img = imread(fullfile(load_path, image_names{1}));
%img = img(crs:cre, ccs:cce,:);    

i_r = size(img,1);
i_c = size(img,2);
num_img = length(image_names);



agg_img = uint8(255*ones(i_r*sub_rows + border*(sub_rows-1), ...
                   i_c*sub_cols + border*(sub_cols-1), 3));
agg_img = uint8(zeros(i_r*sub_rows + border*(sub_rows-1), ...
                   i_c*sub_cols + border*(sub_cols-1), 3));

                 

                 
                 
s_r = 1;
e_r = s_r + i_r -1;
s_c = 1;
e_c = s_c + i_c - 1;
%% MAIN LOOP
f = figure(); 
for il=1:length(image_names)
  


  img = imread(fullfile(load_path, image_names{il}));

  img = imresize(img,[i_r, i_c]);
  %img = img(crs:cre, ccs:cce,:);    

  [col, row] = ind2sub([sub_cols, sub_rows], il);

  s_r = (row-1) * (i_r+border) + 1;
  s_c = (col-1) * (i_c+border) + 1;
  
  e_r = s_r + i_r - 1;
  e_c = s_c + i_c - 1;

  agg_img(s_r:e_r, s_c:e_c,:) = img;

  imshow(agg_img);
  
  
  %f = figure(); 
%   ax(il) = subplot(sub_rows,sub_cols,il);
%   hold on;
%   imshow(img);

end%for each scene

%print(fullfile(save_path, 'agg_img.jpg'), '-djpeg');
saveas(f, fullfile(save_path, 'a_common_instances.jpg'));

%for il=1:length(ax)
%  pos = get(ax(il), 'Position');
%  set(ax(il), 'Position', [pos(1) pos(2) .85*pos(3), pos(4)]);
%end


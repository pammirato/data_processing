% puts multiple images together into one big image
% ASSUMMES IMAGES ARE ALL THE EXACT SAME SIZE


%TODO - change var names to differentiate between pixel postition and 'subplot' position
%     - don't require all images to be the same size, (just use imresize)
%     - better loading, maybe choose extension to load      
%     - other background colors(not important)

%CLEANED - no
%TESTED - no

clearvars;

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

%where to load image from, and where to save the final image
load_path = fullfile('/playpen/ammirato/Pictures/icra_2016_figures/images_to_agg');
save_path = fullfile('/playpen/ammirato/Pictures/icra_2016_figures/');

%name of the images to load
load_all = 1; %whether or not to load all images in load path
              % ASSUMES all files in load path are images
image_names = {}; %can give custom list here

              
% number of rows and columns for figure
sub_rows = 2;
sub_cols = 2;

background_color = 0;   % 0 = white
                        % 1 = black

%how much space between images in figure
border = 50;



%variables for cropping images          
do_crop = 0;
    
crs = 44; %crop row start
cre = 1170;%crop row end
ccs = 145;%column
cce = 2145;



%% SET UP GLOBAL DATA STRUCTURES

if(load_all)
  %load all files in load path
  image_names = dir(fullfile(load_path));
  image_names = image_names(3:end);
  image_names = {image_names.name};
  image_names = image_names(end:-1:1);
end

%read first image to set up everything, get dimensions, etc
img = imread(fullfile(load_path, image_names{1}));

%crop the image if desired
if(do_crop)
  img = img(crs:cre, ccs:cce,:);    
end

%get number of rows and cols in images
img_rows = size(img,1);
img_cols = size(img,2);
num_img = length(image_names);


%make a blank image big enough to hold all the other images
big_img = uint8(255*ones(img_rows*sub_rows + border*(sub_rows-1), ...
                   img_cols*sub_cols + border*(sub_cols-1), 3));
big_img = uint8(zeros(img_rows*sub_rows + border*(sub_rows-1), ...
                   img_cols*sub_cols + border*(sub_cols-1), 3));

                 

                 
%keep track of where we are in the big image(where to put the next loaded image) 
start_row = 1;
end_row = start_row + img_rows -1;
start_col = 1;
end_col = start_col + img_cols - 1;
%% MAIN LOOP

%put each image into the big image
for il=1:length(image_names)
  img = imread(fullfile(load_path, image_names{il}));

  %make sure images are all the same size
  img = imresize(img,[img_rows, img_cols]);
  
  %maybe crop 
  if(do_crop)
    img = img(crs:cre, ccs:cce,:);    
  end

  %get the row and column that this image should be in
  %i.e. 1st image should be in 1,1.  Second image should be in 1,2.  etc. 
  [col, row] = ind2sub([sub_cols, sub_rows], il);

  %get pixel position in big image of this row/col
  start_row = (row-1) * (img_rows+border) + 1;
  start_col = (col-1) * (img_cols+border) + 1;
  end_row = start_row + img_rows - 1;
  end_col = start_col + img_cols - 1;

  %put the image in the big image
  big_img(start_row:end_row, start_col:end_col,:) = img;

  %show progress
  imshow(big_img);
end%for each scene

%save the big image
imwrite((big_img,  fullfile(save_path, 'big_img.jpg'));



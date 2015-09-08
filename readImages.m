function [images image_names] = readImages(images_path, step_size)

files = dir([images_path]);
files = files(3:end);

%sort the image file names by time
[~,index] = sortrows({files.date}.'); 
files = files(index); 
clear index;



%load the images
images = cell(1,length(files)/step_size);
image_names = cell(1,length(files)/step_size);

for i=1:step_size:length(files)
  index = floor(i/step_size) + 1;
  images{index} = imread([images_path files(i).name]);
  image_names{index} = files(i).name;
end%for i files


end%readImages

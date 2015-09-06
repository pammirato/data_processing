function images = readImages(images_path)

files = dir([images_path]);
files = files(3:end);

%sort the image file names by time
[~,index] = sortrows({files.date}.'); 
files = files(index); 
clear index;


%load the images
images = cell(1,length(files));

for i=1:1%length(files)
  images{i} = imread([images_path files(i).name]);
end%for i files


end%readImages

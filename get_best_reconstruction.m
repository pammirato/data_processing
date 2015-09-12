IMAGES_TXT = 'images.txt';


results_path = '/home/ammirato/Documents/Kinect/Data/Bathroom1/reconstruction_results/';


d = dir(results_path);
d = d(3:end);


counters = zeros(1,length(d));


for i=1:length(d)
  fid_images = fopen([results_path d(i).name '/' IMAGES_TXT]);

  %get comment lines
  fgetl(fid_images); 
  fgetl(fid_images); 
  line = fgetl(fid_images);

  counter = 0;
  while(ischar(line))

    %two lines per image
    line = fgetl(fid_images);
    line = fgetl(fid_images);
    
    counter = counter +1; 
  end%while ischar

  counters(i) = counter;

end%for lenght(d)


[value  best_index] = max(counters);


best_index = best_index-1;



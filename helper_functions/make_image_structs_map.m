function [image_structs_map] = make_image_structs_map(image_structs)
% Makes a map from image index name (10 digits of image name, no file extension)
% to image_struct
% 
% image_structs should be a struct array


  %get image names and remove extension if it exists
  image_names = {image_structs.image_name};
  image_names = cell2mat(image_names');
  if(size(image_names,2) > 10)
    image_names(:,11:end) = [];
  end
  image_names = mat2cell(image_names, ones(1,size(image_names,1)), 10);

 
  %make empty map 
  image_structs_map = containers.Map(image_names,...
                                 cell(1,length(image_names)));
  %populate map
  for il=1:length(image_names)
    image_structs_map(image_names{il}) = image_structs(il);
  end
end%function
  


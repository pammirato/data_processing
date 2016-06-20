



fid_labels = fopen('/playpen/ammirato/Detectors/ssd/caffe/models/VGGNet/coco/SSD_300x300/label_map.txt');


line = fgetl(fid_labels);


while(ischar(line))

  line = fgetl(fid_labels);
  line = fgetl(fid_labels);
  line = fgetl(fid_labels);

  inds = strfind(line,'"');
  line = line(inds(1)+1:inds(2)-1);
  disp(line);
  line = fgetl(fid_labels);

  line = fgetl(fid_labels);
end

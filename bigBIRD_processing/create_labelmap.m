%create a prototxt labelmap for the bigbird images
%
%
% NOT USED


init_bigBIRD;

output_path = fullfile('/playpen/ammirato/Detectors/ssd/caffe/data/BigBIRD/');

fid_bb_map = fopen('/playpen/ammirato/Data/RohitMetaMetaData/big_bird_cat_map.txt', 'rt');

fid_out = fopen(fullfile(output_path, 'labelmap_bigBIRD.prototxt'), 'wt');

fprintf(fid_out, 'item {\n');
fprintf(fid_out, '\tname: "%s"\n', 'none_of_the_above');
fprintf(fid_out, '\tlabel: %s\n','0');
fprintf(fid_out, '\tdisplay_name: "%s"\n', 'background');
fprintf(fid_out, '}\n');

line = fgetl(fid_bb_map);
while(ischar(line))
  line = strsplit(line);

  fprintf(fid_out, 'item {\n');
  fprintf(fid_out, '\tname: "%s"\n', line{1});
  fprintf(fid_out, '\tlabel: %s\n', line{2});
  fprintf(fid_out, '\tdisplay_name: "%s"\n', line{1});
  fprintf(fid_out, '}\n');

  line = fgetl(fid_bb_map);
end


fclose(fid_bb_map);
fclose(fid_out);







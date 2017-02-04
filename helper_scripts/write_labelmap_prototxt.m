init;





%get the names of all the instance labels for this scene
instance_name_to_id_map = get_instance_name_to_id_map();
instance_names = keys(instance_name_to_id_map);


save_path = fullfile('/playpen/ammirato/Data/Rohit_COCO_format/labelmap_rohit.prototxt');
fid = fopen(save_path,'wt');

for il=1:length(instance_names)
  cur_name = instance_names{il};
  fprintf(fid,'item {\n');
  fprintf(fid,'\tname: "%d"\n', instance_name_to_id_map(cur_name));
  fprintf(fid,'\tlabel: %d\n', instance_name_to_id_map(cur_name));
  fprintf(fid,'\tdisplay_name: "%s"\n', cur_name);
  fprintf(fid,'}\n');
  
end%for il

fclose(fid);




base_path = '/home/ammirato/Data/KitchenLiving12/labeling/';
mapping_path = [base_path 'mapping.txt'];
label_path = [base_path 'all_labeled_points.txt'];
mapping_label_path = [base_path 'labeled_mapping.txt'];



fid_map_label = fopen(mapping_label_path,'wt');
fid_map = fopen(mapping_path);
fid_label = fopen(label_path);


%copy header
for i=1:11
    line = fgetl(fid_map);
    fprintf(fid_map_label, [line '\n']);
end

%skip header
fgetl(fid_label);
fgetl(fid_label);
fgetl(fid_label);

%theres
point = strsplit(fgetl(fid_label));
labeled_point = strcat(point(1), {' '},  point(2), {'00 '}, point(3), {'00'});
label = fgetl(fid_label);


line = fgetl(fid_map);
while(ischar(line))
    
  fprintf(fid_map_label, [line '\n']);
    
  if(strcmp(labeled_point, line))
      %write the label
      fprintf(fid_map_label, [label '\n']);
      
      %get next point and label
      point = strsplit(fgetl(fid_label));
      if(length(point) <3)
          break;
      end
      
      labeled_point = strcat(point(1), {' '},  point(2), {'00 '}, point(3), {'00'});
      label = fgetl(fid_label);
  end

 
  line =fgetl(fid_map);
  

end

%for reading later
fprintf(fid_map_label, '\n');
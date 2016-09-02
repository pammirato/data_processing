clearvars;

init_bigBIRD;


%TODO - add   rotation
%             alpha composition
%             illumination
%

image_width = '1280';
image_height = '1024';
image_depth = '3';


back_base_path = '/playpen/ammirato/Data/BigBirdCompositeData/';


label_path = fullfile(back_base_path,'composite_metadata');
comp_img_path = fullfile(back_base_path, 'composite_images');
composite_image_names = dir(comp_img_path);
composite_image_names = {composite_image_names(3:end).name};






%load mapping from bigbird name ot category id
obj_cat_map = containers.Map();
fid_bb_map = fopen('/playpen/ammirato/Data/RohitMetaMetaData/big_bird_cat_map.txt', 'rt');

line = fgetl(fid_bb_map);
while(ischar(line))
  line = strsplit(line);
  obj_cat_map(line{2}) = line{1}; 
  line = fgetl(fid_bb_map);
end
fclose(fid_bb_map);




for il=1:length(composite_image_names)

  fprintf('%d of %d\n', il, length(composite_image_names));

  cur_comp_image_name = composite_image_names{il};

  ext_ind = strfind(cur_comp_image_name, '.');
  cur_composite_base_name = cur_comp_image_name(1:ext_ind-1);
  cur_label_filename = strcat(cur_composite_base_name, '.txt');
  fid_label_txt = fopen(fullfile(label_path, cur_label_filename), 'rt');


  %read in the bounding boxes
  txt_labels = zeros(3,6); %hold cat id, xmin, ymin, xmax, ymax, azimuth angle 
  counter = 1;
  line = fgetl(fid_label_txt);
  while(ischar(line))
    txt_labels(counter,:) = cellfun(@str2num, strsplit(line));
    counter = counter +1;
    line = fgetl(fid_label_txt);
  end
  txt_labels(counter:end, :) = [];

  fclose(fid_label_txt);



  %create xml file
  cur_xml_filename = strcat(cur_composite_base_name, '.xml');
  fid_label_xml = fopen(fullfile(label_path, cur_xml_filename), 'wt');

  fprintf(fid_label_xml, '<annotation>\n');   
    fprintf(fid_label_xml, '\t<Folder>BigBIRD</Folder>\n');   
    fprintf(fid_label_xml, '\t<filename>%s</filename>\n', cur_comp_image_name);   
    fprintf(fid_label_xml, '\t<size>\n');   
      fprintf(fid_label_xml, '\t\t<width>%s</width>\n', image_width);   
      fprintf(fid_label_xml, '\t\t<height>%s</height>\n', image_height);   
      fprintf(fid_label_xml, '\t\t<depth>%s</depth>\n', image_depth);   
    fprintf(fid_label_xml, '\t</size>\n');   
    fprintf(fid_label_xml, '\t<segmented>0</segmented>\n');   
  for jl=1:size(txt_labels,1)
    fprintf(fid_label_xml, '\t<object>\n');   
      fprintf(fid_label_xml, '\t\t<name>%s</name>\n',obj_cat_map(num2str(txt_labels(jl,1))));   
      fprintf(fid_label_xml, '\t\t<truncated>0</truncated>\n');   
      fprintf(fid_label_xml, '\t\t<difficult>0</difficult>\n');   
      fprintf(fid_label_xml, '\t\t<bndbox>\n');   
        fprintf(fid_label_xml, '\t\t\t<xmin>%d</xmin>\n', txt_labels(jl,2));   
        fprintf(fid_label_xml, '\t\t\t<ymin>%d</ymin>\n', txt_labels(jl,3));   
        fprintf(fid_label_xml, '\t\t\t<xmax>%d</xmax>\n', txt_labels(jl,4));   
        fprintf(fid_label_xml, '\t\t\t<ymax>%d</ymax>\n', txt_labels(jl,5));   
      fprintf(fid_label_xml, '\t\t</bndbox>\n');   
    fprintf(fid_label_xml, '\t</object>\n');   
  end
  fprintf(fid_label_xml, '</annotation>');   

  fclose(fid_label_xml);

  %docNode = com.mathworks.xml.XMLUtils.createDocument('annotation');
  %folder_node = docNode.createElement('Folder');
  %docNode.getDocumntElement.appendChild(folder_node);  

  %xmlwrite(fullfile(label_path, cur_xml_filename), docNode)
  


end%for il, each background image














source = fullfile('/playpen/ammirato/Data/big_bird_instance_singles');

image_names = dir(fullfile(source,'images/*.jpg'));
image_names = {image_names.name};

cols = 5;

counter = 1;


html_fid = fopen(fullfile(source,'table2.html'), 'wt');

fprintf(html_fid,'<table>');

counter = 1;

%for il=1:cols:length(image_names)
while(counter <= length(image_names))
  fprintf(html_fid,'\n\t<tr>');
%  img = imread(fullfile(source,image_names{il}));
%
%  img = img(313:733,510:799,:);
%  imwrite(img,fullfile(source,image_names{il}));


  for jl=1:cols
    if(counter + jl -1 > length(image_names))
      break;
    end

    fprintf(html_fid, strcat('\n\t\t<td><img src="images/', image_names{counter + jl - 1}, ...
                       '" class="big_bird_single"></td>\n'));
                       %'" style="width:152px;height:114px;"></td>\n'));
  end%for jl

  fprintf(html_fid,'\n\t</tr>');
  fprintf(html_fid,'\n\t<tr>');


  for jl=1:cols
    if(counter + jl -1 > length(image_names))
      break;
    end
    name = image_names{counter + jl - 1};

    if(length(name) > 22)
      name = strcat(name(1:18),'<br/>', name(19:end));
    end   

 
    fprintf(html_fid, strcat('\n\t\t<td>',name(1:end-4) , '</td>\n'));
  end%for jl


  counter = counter + cols;



  fprintf(html_fid,'\n\t</tr>');
end

fprintf(html_fid,'</table>');
fclose(html_fid);




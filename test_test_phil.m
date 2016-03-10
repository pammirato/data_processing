% 
% 
% max_score_direction = max_camera_data(4:6) + max_camera_data(1:3);
% 
% 
% pos = zeros(length(labeled_images),3);
% dirs = zeros(length(labeled_images),3);
% dirs2 = zeros(length(labeled_images),3);
% 
% 
% for i=1:length(labeled_images)
% 
%   cur_label_data = labeled_images{i};
%   cur_filename = cur_label_data{1};
%   cur_camera_data = camera_data_map(cur_filename);
%   cur_direction = cur_camera_data(4:6) +cur_camera_data(1:3);
%   
%   pos(i,:) = cur_camera_data(1:3);
%   dirs(i,:) = cur_camera_data(4:6);
%   dirs2(i,:) = cur_direction(1:3);
%   
%   
%   cur_angle = atan2(norm(cross(max_score_direction,cur_direction)), dot(max_score_direction,cur_direction));
% 
%   angle_from_max(i) = cur_angle;
% end%for i 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% plot3(depth_of_label,angle_from_max,detections(:,5),'r.');
% 
% 
% vals = camera_data_map.values;
% vals = cell2mat(vals);
% 
% figure;
% 
% 
% plot3(pos(:,1), pos(:,2), pos(:,3), 'r.');
% hold on;
% plot3(dirs(:,1), dirs(:,2), dirs(:,3), 'k.');
% hold on;
% scatter3(max_camera_data(1),max_camera_data(1),max_camera_data(3),25,'b');
% 
% figure;
% plot3(pos(:,1), pos(:,2), pos(:,3), 'r.');
% hold on;
% plot3(dirs2(:,1), dirs2(:,2), dirs2(:,3), 'k.');


% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% img2 = img;
% sum_img = sum(img2,3);
% thresh_img = sum_img;
% thresh_img(thresh_img<765) =0;
% 
% firstCol = find(thresh_img(1,:)==0,1);
% lastCol = find(thresh_img(1,:)==0,1,'last');
% 
% firstRow = find(thresh_img(:,firstCol)==0,1);
% lastRow = find(thresh_img(:,firstCol)==0,1,'last');
% 
% 
% cropped_image = img(firstRow:lastRow, firstCol:lastCol,:);
% 
% imwrite(cropped_image, 'cropped.png');



% 
% 
% for i=1:length(ground_truth_bboxes)
%     bbox = ground_truth_bboxes{i};
%     xi = bbox(1);
%     yi = bbox(2);
%     xxi = bbox(3);
%     yyi = bbox(4);
%     if(xi < 1)
%         xi = 1;
%     end
%     if(xxi > size(rgb_image,2))
%         xxi = size(rgb_image,2);
%     end
%     if(yi <1)
%         yi = 1;
%     end
%     if(yyi > size(rgb_image,1))
%         yyi = size(rgb_image,1)
%     end
%     
%     bbox = [xi, yi, xxi, yyi];
%     
%     ground_truth_bboxes{i} = bbox;
%     
% end
% 
% 
% % 
% 
% 
% 
% 
% 
% %get the map to find all the interesting images
% label_to_images_that_see_it_map = load(fullfile(scene_path,LABELING_DIR,...
%                                     DATA_FOR_LABELING_DIR, ...
%                                     LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE));
%  
% label_to_images_that_see_it_map = label_to_images_that_see_it_map.(LABEL_TO_IMAGES_THAT_SEE_IT_MAP);
%              
% all_labels = label_to_images_that_see_it_map.keys;
% 
% 
% new_labels = cell(1,length(all_labels));
% new_values = cell(1,length(all_labels));
% 
% for i=1:length(all_labels)
%     label = all_labels{i};
%     
%     value = label_to_images_that_see_it_map(label);
%     label = strtrim(label);
% 
%     new_labels{i} = label;
%     new_values{i} = value;
% 
% end
% 
% label_to_images_that_see_it_map = containers.Map(new_labels,new_values);
% save(fullfile(scene_path,LABELING_DIR,...
%                                     DATA_FOR_LABELING_DIR, ...
%                                     LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE), ...
%                                       LABEL_TO_IMAGES_THAT_SEE_IT_MAP);
% 
% 
% 
% 
% 





% 
% 
% 
% 
% scene_name = 'FB241B';  %make this = 'all' to go through all rooms
% 
% 
% d = dir(BASE_PATH);
% d = d(3:end);
% 
% if(strcmp(scene_name,'all'))
%     num_rooms = length(d);
% else
%     num_rooms = 1;
% end
% 
% for i=1:num_rooms
%     
%     if(num_rooms >1)
%         scene_name = d(i).name()
%     end
%     
%     scene_path = fullfile(BASE_PATH,scene_name);
%     
%     dr = dir(fullfile(BASE_PATH, scene_name,RGB_IMAGES_DIR));
%     dr = dr(3:end);
%     
%     
%     org_rgb_names = {dr.name};
%     
%     %*3 so there are extra slots, because files may have been deleted
%     sorted_org_rgb_names = cell(1,length(org_rgb_names)*3 +200);
%     
%     if(isempty(strfind(org_rgb_names{1},'rgb')))
%         continue;
%     end
%     
%     %sort the original names
%     for j=1:length(org_rgb_names)
%         
%         name = org_rgb_names{j};
%         if(strcmp(name(1),'2'))
%             index = name(8:end-6);
%             %plus one cause matlab is 1 based
%             index = str2num(index) +1 + length(org_rgb_names);
%             
%         else
%             index = name(4:end-6);        
% 
%             %plus one cause matlab is 1 based
%             index = str2num(index) +1;
%         
%         end
%         k_index = str2num(name(end-4));
%         sorted_org_rgb_names{(index-1)*3 +k_index} = name;
%        
%     end%for j
% 
% 
% end
% 
% 
%     sorted_org_rgb_names = sorted_org_rgb_names(find(~cellfun('isempty',sorted_org_rgb_names)));
%     
%     assert(length(sorted_org_rgb_names) > 1);
%     assert(length(sorted_org_rgb_names) == length(org_rgb_names));
%     assert(length(sorted_org_rgb_names) == length(unique(sorted_org_rgb_names)));
%     
%     
% 
% 
% 
% 




% 
% 
% for i=1:length(values)
%     
%     v = values{i};
%     
%     index = v(4:end-6);
%     
%     index = str2num(index);
%     index = num2str(index);
%     
%     kindex = v(end-4);
%     
%     
%     v = strcat('rgb',index,'K',kindex,'.png');
%     
%     values{i} = v;
%     
%     
% end%for i
% 
% name_map = containers.Map(keys,values);
% save(fullfile(BASE_PATH,scene_name, NAME_MAP_FILE),NAME_MAP);




% 
% 
% for i=1:11
%    img_name = camera_structs(i);
%    cur_struct = structs_map(img_name.image_name);
%    
%    cur_struct.cluster_id = i-1;
%    
%    structs_map(img_name.image_name) = cur_struct;
%    
%    
% end
% 

% 
% x_dist = ones(1,grid_size*length(all_score_thresholds));
% for qq=1:grid_size
%     start_i = (length(all_score_thresholds)*(qq-1) + 1);
%     end_i = start_i + length(all_score_thresholds)-1;
%     x_dist(start_i:end_i) = qq;
% end%for qq













% 
% 
% 
% rgb_image = imread(fullfile(scene_path,JPG_RGB_IMAGES_DIR,rgb_name));
%     
%     imshow(rgb_image);
%     
%     title(rgb_name);
%     rec_name = strcat(rgb_name(1:10),'.mat');
%     rec_mat = load(fullfile(scene_path,'labeling','chair_boxes_per_image',rec_name));
%    
%     
%     anns = rec_mat.annotations;
% 
%     for k=1:size(anns,1)
%         bbox = double(anns(k,:));
%         rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
% 
% %         text(bbox(1), bbox(2)-font_size,strcat(num2str(bbox(5)),cur_label),  ...
% %                                 'FontSize',font_size, 'Color','white');
% 
%     end%for k      
% %         if(length(dets_to_show) > 0)
% %             dets_to_show = cat(1,dets_to_show,cur_dets);
% %         else
% %             dets_to_show = cur_dets;
% %         end
% 
%     
%     
%     [x, y, but] = ginput(1);
%     
%     if(but~=1)
%         save_changes = 1;
%         
%         
%         while(but~=1)
%         
%             [x, y, ~] = ginput(2);
% 
%             x = floor(x);
%             y = floor(y);
%             
%             x(1) = max(1,x(1));
%             x(2) = min(size(rgb_image,2),x(2));
%             y(1) = max(1,y(1));
%             y(2) = min(size(rgb_image,1),y(2));
% 
%             bbox = [x(1), y(1), x(2), y(2)];
%             rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
%             anns(size(anns,1)+1,:) = single(bbox);
%             
%             [x, y, but] = ginput(1);
%         end%whjile
%         
%         
%         
%     end%if but
% %     ch = getkey();
% %     if(ch == 'q')
% %         break;
% %     end
%     hold off;
%     
%     if(save_changes)
%         annotations = anns;
%         save(fullfile(scene_path,'labeling','chair_boxes_per_image',rec_name),'annotations');
%     end
% 
% 









% % 
% % 
% density = 1;
% scene_name = 'SN208';
% 
% label_name = 'table2';
% 
% 
% scene_path = fullfile(BASE_PATH,scene_name);
% if(density)
%     scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
% end
% % boxes_path = fullfile(scene_path,RECOGNITION_DIR,'bboxes');
% boxes_path_load = fullfile(scene_path,'labeling','chair_boxes_per_image');
% boxes_path_save = fullfile(scene_path,'labeling','chair_boxes_per_image_concat');
% 
% 
% boxes_name = dir(fullfile(boxes_path_load,'*.mat'));
% boxes_name = {boxes_name.name};
% 
% for i=1:length(boxes_name)
%     box_name= boxes_name{i};
% 
%     a = load(fullfile(boxes_path_load,box_name));
%     
%     boxes = cell(0);
%     
%     cats = fields(a);
%     for j=1:length(cats)
%         c = cats{j};
%         
%         boxes{end+1} = a.(c);
%     end
% 
%     boxes = cell2mat(boxes');
%     
%     boxes2 = boxes(:,2);
%     boxes4 = boxes(:,4);
%     
%     boxes(:,2) = boxes(:,1);
%     boxes(:,1) = boxes2;
%     boxes(:,4) = boxes(:,3);
%     boxes(:,3) = boxes4;
%     
%     save(fullfile(boxes_path_save,box_name),'boxes');
% end
% 
% 
% 
% 















% 
% 
% scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
% 
% 
% %load a map from image name to camera data
% %camera data is an arraywith the camera position and a point along is orientation vector
% % [CAM_X CAM_Y CAM_Z DIR_X DIR_Y DIR_Z]
% camera_structs_file =  load(fullfile(scene_path,RECONSTRUCTION_DIR,NEW_CAMERA_STRUCTS_FILE));
% %camera_structs = camera_structs_file.(CAMERA_STRUCTS);
% camera_structs = cell2mat(camera_structs_file.(CAMERA_STRUCTS));
% scale  = camera_structs_file.scale;
% 
% write_path = fullfile(scene_path,'rgb_new');
% mkdir(write_path);
% 
% image_names = {camera_structs.image_name};
% structs_map = containers.Map(image_names,camera_structs_file.(CAMERA_STRUCTS));
% 
% 
% for i=253:length(image_names)
%     
%     image_name = image_names{i};
%     
%     cur_struct = structs_map(image_name);
%     
%     img= imread(fullfile(scene_path,'rgb',image_name));
%     
%     new_image_name = strcat('000',num2str(i),'0101.png');
%     
%     cur_struct.image_name = new_image_name;
%     cur_struct.cluster_id = i;
%     
%     structs_map(image_name) = cur_struct;
%     
%     imwrite(img,fullfile(write_path,new_image_name));
%     
%     
% end %for i
% 
% 
% camera_structs = structs_map.values;
% 
% save(fullfile(scene_path, RECONSTRUCTION_DIR, NEW_CAMERA_STRUCTS_FILE), CAMERA_STRUCTS, SCALE);
% 



% 
% 
% 
% scene_name = 'SN208_2';
% scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
% image_names = dir(fullfile(scene_path,RECOGNITION_DIR,'bboxes_selective_search','*.mat'));
% image_names = {image_names.name};
% 
% 
% for i=253:length(image_names)
%     
%     image_name = image_names{i};
%     
%     new_image_name = strcat('000',num2str(i),'0101.mat');
%     
%     ss_boxes = load(fullfile(scene_path,RECOGNITION_DIR,'bboxes_selective_search',image_name));
%     boxes = ss_boxes.boxes;
%     
%     
%     dets = load(fullfile(scene_path,RECOGNITION_DIR,'results_fast_rcnn',image_name));
%     dets = dets.dets;
%     
%     save(fullfile(scene_path,RECOGNITION_DIR,'bboxes_selective_search_new',new_image_name),'boxes');
%     save(fullfile(scene_path,RECOGNITION_DIR,'results_fast_rcnn_new',new_image_name),'dets');
%     
%     
% end %for i
% 
% 
% camera_structs = structs_map.values;
% 
% save(fullfile(scene_path, RECONSTRUCTION_DIR, NEW_CAMERA_STRUCTS_FILE), CAMERA_STRUCTS, SCALE);
% 
% 
% 
% 
% 


% 
% aa = zeros(1,63);
%  for i=1:63%length(image_names) 
% 
%     aa(i) = 21*(floor((i-1)/3)) +  mod((i-1)+3,3)*10 +1 ;
%     
%  end






% 
% dd = '/playpen/ammirato/Data/Density/SN208_3/cloud/';
% 
% 
% d=  dir('/playpen/ammirato/Data/Density/SN208_3/cloud/*.pcd');
% image_names = {d.name};
% 
% mkdir('/playpen/ammirato/Data/Density/SN208_3/unreg_depth_new/*.png');
% 
% for i =1:length(image_names)
%     
%    cur_name = image_names{i};
%    
%    cur_index = str2num(cur_name(1:6));
%    
%    new_index = cur_index - 83;
%    
%    new_name = strcat(sprintf('%06d',new_index),cur_name(7:end));
%     
%    
%    img = imread(fullfile(dd,cur_name));
%    
%    imwrite(img, fullfile(new_dd,new_name));
% end





% d = dir(BASE_PATH);
% d = d(3:end);
% 
% for i=1:length(d)
%     
%     a = d(i).name;
%     scene_path = fullfile(BASE_PATH,a);
%     meta_path = fullfile(META_BASE_PATH,a);
%     
%     if(isdir(scene_path))
%         try
% %            movefile(fullfile(scene_path,'odom.txt'), fullfile(meta_path,'odom.txt'));
% %             movefile(fullfile(scene_path,UNREG_DEPTH_IMAGES_DIR), fullfile(scene_path,'raw_depth'));
% %           movefile(fullfile(meta_path,RECONSTRUCTION_DIR,'misc'),fullfile(meta_path,'misc'));
% %           movefile(fullfile(scene_path,'name_map.mat'),fullfile(meta_path,RECONSTRUCTION_DIR,'name_map.mat'));
% %         movefile(fullfile(scene_path,RECOGNITION_DIR),fullfile(meta_path,RECOGNITION_DIR));
% %         movefile(fullfile(scene_path,RECONSTRUCTION_DIR),fullfile(meta_path,RECONSTRUCTION_DIR));
% %         movefile(fullfile(scene_path,LABELING_DIR),fullfile(meta_path,LABELING_DIR));
% %         movefile(fullfile(scene_path,'tar_files'),fullfile(meta_path,'tar_files'));
%         catch
%         end    
%     end
%     
% end%for i

% 
% d = dir(BIGBIRD_BASE_PATH);
% d = d(3:end);
% 
% for i=1:length(d)
%     
%    instance_path = fullfile(BIGBIRD_BASE_PATH,d(i).name);
%    
%    mkdir(fullfile(instance_path,'sift'));
%    movefile(fullfile(instance_path,'*sift.mat'), fullfile(instance_path,'sift'));
% end
% 







%
%d = dir(ROHIT_BASE_PATH);
%d = d(3:end);
%
%for i=1:length(d)
%   
%  a = d(i).name;
%  scene_path = fullfile(ROHIT_BASE_PATH,a);
%  
%  if(isdir(scene_path))
%    try
%      movefile(fullfile(scene_path,'labels','bounding_boxes_by_image'), ...
%               fullfile(scene_path,'labels','bounding_boxes_by_image_instance_level'));
%      mkdir(fullfile(scene_path,'labels','bounding_boxes_by_image_class_level'));
%    catch
%    end
%  end
%end





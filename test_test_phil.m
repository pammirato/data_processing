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




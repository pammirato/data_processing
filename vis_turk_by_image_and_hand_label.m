


init;


density = 1;
%the scene and instance we are interested in
scene_name = 'SN208_3';
recognition_system_name = 'fast-rcnn';
font_size = 10;

%any of the fast-rcnn categories
category_name = 'chair'; %make this 'all' to see all categories

score_threshold = .1;

scene_path = fullfile(BASE_PATH,scene_name);
if(density)
    scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
end

save_dir = 'boxes_per_image';
image_names = dir(fullfile(scene_path,RGB_IMAGES_DIR,'*0101.png'));
image_names = {image_names.name};






 for i=1:length(image_names) 

    index = 21*(floor((i-1)/3)) +  mod((i-1)+3,3)*10 +1 ;
     
    save_changes = 0;
    
    rgb_name = image_names{index};
    rgb_image = imread(fullfile(scene_path,RGB_IMAGES_DIR,rgb_name));
    
    imshow(rgb_image);
    
    title(rgb_name);
    
    anns_exist = 1;
    
    rec_name = strcat(rgb_name(1:10),'.mat');
    
    try
        anns = load(fullfile(scene_path,'labeling',save_dir,rec_name));
    catch
        anns_exist = 0;
        anns = struct();
    end
    
    if(anns_exist)
        categories = fields(anns);

        for k=1:length(categories)
            bbox = anns.(categories{k});
            rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');

    %         text(bbox(1), bbox(2)-font_size,strcat(num2str(bbox(5)),cur_label),  ...
    %                                 'FontSize',font_size, 'Color','white');

        end%for k      
    end
%         if(length(dets_to_show) > 0)
%             dets_to_show = cat(1,dets_to_show,cur_dets);
%         else
%             dets_to_show = cur_dets;
%         end

    
    
    [x, y, but] = ginput(1);
    
    if(but~=1)
        save_changes = 1;
        
        done = 0;
        while(but~=1  && ~done)
        
            [x, y, ~] = ginput(2);
            
            label_name = input('Enter label: ', 's');
            
            if(label_name == 'q')
                done = 1;
                continue;
            end

            x = floor(x);
            y = floor(y);
            
            x(1) = max(1,x(1));
            x(2) = min(size(rgb_image,2),x(2));
            y(1) = max(1,y(1));
            y(2) = min(size(rgb_image,1),y(2));

            bbox = [x(1), y(1), x(2), y(2)];
            rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
            
            

            anns.(label_name) = bbox;
            
            [x, y, but] = ginput(1);
        end%whjile
        
        
        
    end%if but
%     ch = getkey();
%     if(ch == 'q')
%         break;
%     end
    hold off;
    
    if(save_changes)
        annotations = anns;
        save(fullfile(scene_path,'labeling',save_dir,rec_name),'-struct','annotations');
    end
    
    
%     if(done)
%         break;
%     end
    
 end%fior i, each image name


    
    


function output = display_recognition_performance(~, event_obj,camera_structs, fig_handle, category_name, label_name, scene_path)
                                                    
                                                    
                                                    
   
    
    disp('hello, world');
    
    camera_structs = cell2mat(camera_structs);
    
    positions = [camera_structs.scaled_world_pos];
    
    breakp = 1;
    
    cursor = get(event_obj);
    
    cp = cursor.Position;
    cp = [cp(1), cp(3)];
    positions = positions([1,3],:);
    

    [dist, index] = pdist2(positions',cp,'euclidean','Smallest',1);
    
    struct = camera_structs(index);
    
    
    image_name = struct.image_name;
    
    rec_mat = load(fullfile(scene_path,'recognition_results','fast-rcnn',...
                            strcat(image_name(1:10),'.mat')));
    rec_dets = rec_mat.dets;
    rec_category_dets = rec_dets.(category_name);
    
    %get rid of anything below .1
    rec_category_dets = rec_category_dets(rec_category_dets(:,5) >=.1,:);
    
    
    turk_boxes= load(fullfile(scene_path,'labeling', 'turk_boxes', strcat(label_name, '.mat')));
    turk_annotations = cell2mat(turk_boxes.annotations);

    image_names = {turk_annotations.frame};
    
    turk_map = containers.Map(image_names,turk_boxes.annotations);
    
    ann = turk_map(image_name);
    
    turk_bbox = [ann.xtl, ann.ytl, ann.xbr, ann.ybr];
    

    
    
    
    set(0,'CurrentFigure',fig_handle);
    
    imshow(imread(fullfile(scene_path,'jpg_rgb',strcat(image_name(1:10),'.jpg'))));
    title(image_name);
    rectangle('Position',[turk_bbox(1) turk_bbox(2) (turk_bbox(3)-turk_bbox(1)) (turk_bbox(4)-turk_bbox(2))], 'LineWidth',3, 'EdgeColor','r');

    font_size = 10;
    for i =1:length(rec_category_dets)
       bbox = double(rec_category_dets(i,1:5)); 
       rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b'); 
       text(bbox(1), bbox(2)-font_size,num2str(bbox(5)),  ...
                                    'FontSize',font_size, 'Color','white');
    end
    
    
    
    
                        
end
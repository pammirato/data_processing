 %this script plots detection scores for one instance in a scene againts 
%variation in viewpoint of the instance, and distance from the camera
%to the instance



init;


debug = 0;


%the scene and instance we are interested in
density = 1;
scene_name = 'SN208';
grid_size = 11; %number of camera positions in a row/col 
recognition_system_name = 'results_fast_rcnn';

compare_to_first = 0;  %whether to just compare all points to the first, 
                       %or to compare 'all to all' kind of
get_all_results_per_res = 1;
res = 1;

use_rec_boxes = 1; %use the boxes from the recognition system(not selective search)
use_gt_boxes = 1;  %use the ground truth boxes
gt_instance = 'all';  %make all to use all instances
gt_instances = {'chair1','chair2','chair3','chair4','chair5','chair6','chair7','chair8'};
gt_score = 1;

save_figs = 0;


%any of the fast-rcnn categories
category_name = 'chair'; %make this 'all' to see all categories

all_score_thresholds = .1:.1:.1; %the different score thresholds to apply
%score_threshold = 0.5; %only choose boxes with score above this
iou_threshold = .5; %require interseciton over union to be above this

scene_path = fullfile(BASE_PATH,scene_name);
if(density)
    scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
end


%get the names of all the scenes
d = dir(BASE_PATH);
d = d(3:end);

%determine if just one or all scenes are being processed
if(strcmp(scene_name,'all'))
    num_scenes = length(d);
else
    num_scenes = 1;
end

for i=1:num_scenes
    
    %if we are processing all scenes
    if(num_scenes >1)
        scene_name = d(i).name();
    end

    scene_path =fullfile(BASE_PATH, scene_name);
    if(density)
        scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
    end

    %% load dasta about camera positions for each image
    camera_structs_file =  load(fullfile(scene_path,RECONSTRUCTION_DIR,NEW_CAMERA_STRUCTS_FILE));
    structs = camera_structs_file.(CAMERA_STRUCTS);
    scale  = camera_structs_file.scale;
     
   
    structs = cell2mat(structs);
    structs_map = containers.Map({structs.image_name},camera_structs_file.(CAMERA_STRUCTS));

    image_names = {structs.image_name}; 
    
    
    %% set arrays to store all the data 
    

    if(compare_to_first)
        results_grid = zeros(grid_size,grid_size,5);
        scores_grid  = zeros(grid_size,grid_size,length(gt_instances));
    elseif(get_all_results_per_res)
            forward_results = -ones(grid_size,grid_size,5);
            right_results = -ones(grid_size,grid_size,5);
    else
        %data for moving forawrd some amount
        forward_totals_by_res = zeros(length(all_score_thresholds),5,grid_size); 
        forward_avgs_by_res = zeros(length(all_score_thresholds),5,grid_size);
        forward_num_used_by_res = zeros(length(all_score_thresholds),grid_size);

        %data for moving to the right some amount
        right_totals_by_res = zeros(length(all_score_thresholds),5,grid_size);
        right_avgs_by_res = zeros(length(all_score_thresholds),5,grid_size);
        right_num_used_by_res = zeros(length(all_score_thresholds),grid_size);
    end
    
   
    
    %% load all the boxes and whatnot
    rec_boxes = cell(grid_size,grid_size); %holds rec system or selective search boxes  for each image
    gt_boxes = cell(grid_size,grid_size); %hold true boxes for each image
    
    for j=1:length(image_names)      
        image_name = image_names{j};
        
        %get name for file that has boxes
        rec_name = strcat(image_name(1:10),'.mat');   
        
        %get the 'position index' of the image
        image_index = str2double(image_name(1:6)) -1;

        col = 1 + floor(image_index/grid_size);
        row = mod(image_index,grid_size) +1;
    
        if(use_rec_boxes)
            cur_rec = load(fullfile(scene_path,RECOGNITION_DIR,recognition_system_name,rec_name));
            cur_rec = cur_rec.dets;   
            cur_rec = cur_rec.(category_name);
            %cur_rec = cur_rec(cur_rec(:,5)>score_threshold,:);

            rec_boxes{row,col} = cur_rec;
            
        else %load selective search boxes
            cur_rec = load(fullfile(scene_path,RECOGNITION_DIR, ...
                            'bboxes_selective_search', ...
                            rec_name));
            cur_rec = cur_rec.boxes;   
            
            % change format of boxes
            cr1 = cur_rec(:,1);
            cr3 = cur_rec(:,3);
            cur_rec(:,1) = cur_rec(:,2);
            cur_rec(:,2) = cr1;
            cur_rec(:,3) = cur_rec(:,4);
            cur_rec(:,4) = cr3;
            
            rec_boxes{row,col} = cur_rec;
        end

        if(use_gt_boxes)
            gt_box = load(fullfile(scene_path,LABELING_DIR, ...
                'chair_boxes_per_image',strcat(image_name(1:10),'.mat')));
            
            if(~strcmp(gt_instance,'all'))
                try
                    gt_box = gt_box.(gt_instance);
                catch
                    gt_box = [-1, -1, -1, -1];
                end
            end
            gt_boxes{row,col} = gt_box;
        else
           gt_boxes{row,col} = -1; 
        end
        
    end % for j, each image name
      
    %make sure nothing extra was added
    assert(size(rec_boxes,1) == grid_size);
    assert(size(rec_boxes,2) == grid_size);

    
       %% do experiment
       
       
  
   for q=1:length(all_score_thresholds)
       score_threshold = all_score_thresholds(q);
   

    %% do the experiment
    
    
    %constants for what data goes where
    TOTAL_BOXES = 1; %total number of boxes
    BOXES_MISSING_IOU = 2; %number of boxes that do NOT have > iou_threshold iou with another box
    BOXES_MISSING_IOU_PERCENT = 3; %
    GT_MISSING_IOU = 4; %number of ground truth boxes that do have > iou_threshold iou with another box in exactly one of a pair of images
    GT_MISSING_IOU_PERCENT = 5; %
    


    
    %% setup for comparing to first image only
     if(compare_to_first)
         first_rec_boxes = rec_boxes{1,1};
         
         if(size(first_rec_boxes,2) == 5)
             first_rec_boxes = first_rec_boxes(first_rec_boxes(:,5) > score_threshold,:);
         end
         
         first_gt_boxes = gt_boxes{1,1};
     end%if compare to first
    
    
%% for each image, 
    for j=1:length(image_names)
        j
            
        image_name = image_names{j};
        
        %same as above
        image_index = str2double(image_name(1:6)) -1;
        col = 1 + floor(image_index/grid_size);
        row = mod(image_index,grid_size) +1;

        
        cur_rec_boxes = rec_boxes{row,col}; 
        if(size(cur_rec_boxes,2) == 5)
            cur_rec_boxes = cur_rec_boxes(cur_rec_boxes(:,5) > score_threshold,:);
        end
        cur_gt_boxes = gt_boxes{row,col};
        
        %% show all the rec boxes
        if(debug) 
            hold off;
            figure;
            imshow(imread(fullfile(scene_path,'rgb',image_name)));
            hold on;
            title(strcat('direct(blue):   ', image_name));
            
            if(use_rec_boxes)
                rec_dets = load(fullfile(scene_path,RECOGNITION_DIR,recognition_system_name,strcat(image_name(1:10),'.mat')));
                rec_dets = rec_dets.dets;   
                rec_dets = rec_dets.(category_name);
                rec_dets = rec_dets(rec_dets(:,5)>score_threshold,:);
            else
                rec_dets = load(fullfile(scene_path,RECOGNITION_DIR, ...
                            'bboxes_selective_search', ...
                            strcat(image_name(1:10),'.mat')));
                rec_dets = rec_dets.boxes;
                
                r1 = rec_dets(:,1);
                r3 = rec_dets(:,3);
                
                rec_dets(:,1) = rec_dets(:,2);
                rec_dets(:,2) = r1;
                rec_dets(:,3) = rec_dets(:,4);
                rec_dets(:,4) = r3;
                
            end
            
            %show true boxes in BLUE
            for kk=1:size(rec_dets,1)
                bbox = double(rec_dets(kk,:));
                rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
            end%for k  
                     
            %show preloaded boxes in RED
            for kk=1:size(cur_rec_boxes,1)
                bbox = double(cur_rec_boxes(kk,:));
                rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','r');
            end%for k  
        
            temp = ginput(1);
            
        end%if debug
        
        
        
        

         if(compare_to_first)
             results_grid(row,col,:) = density_calculations(first_rec_boxes,cur_rec_boxes,...
                                                            first_gt_boxes, cur_gt_boxes, ...
                                                            iou_threshold);
             if(use_gt_boxes)
                 for k=1:length(gt_instances)
                     instance = gt_instances{k};
                     try
                        gt_box = cur_gt_boxes.(instance);
                     catch
                        gt_box = [-1, -1, -1, -1];
                     end
                     scores_grid(row,col,k) = get_score_for_box(gt_box, cur_rec_boxes,iou_threshold);
                 end
             end
             
         elseif(get_all_results_per_res)
             
            forward_row = row + res;
            if(forward_row  <= size(rec_boxes,1))
                forward_rec_boxes = rec_boxes{forward_row, col};
                forward_gt_boxes = gt_boxes{forward_row,col};
                
                
                forward_results(row,col,:) = density_calculations(cur_rec_boxes,forward_rec_boxes,...
                                                            cur_gt_boxes, forward_gt_boxes, ...
                                                            iou_threshold);
            end
            
            right_col = col + res;
            if(right_col  <= size(rec_boxes,2))
                right_rec_boxes = rec_boxes{row, right_col};
                right_gt_boxes = gt_boxes{row,right_col};
                
                
                right_results(row,col,:) = density_calculations(cur_rec_boxes,forward_rec_boxes,...
                                                            cur_gt_boxes, forward_gt_boxes, ...
                                                            iou_threshold);
            end
            
            
           
             
             
             
         else% ~compare_to_first
        %% do forward stuff
        

            %go forward(increase row position) as far as you can
            %for each forward row, get some data
            for k=(row+1):grid_size


                forward_rec_boxes = rec_boxes{k,col};   
                if(size(forward_rec_boxes,2) == 5)
                    forward_rec_boxes = forward_rec_boxes(forward_rec_boxes(:,5) > score_threshold,:);
                end

                forward_gt_boxes = gt_boxes{k,col};


                %% show all the current boxes AND the forward boxes  on the FORWARD IMAGE
                if(debug)
                    hold off;
                    figure;
                    next_image_name = strcat(  sprintf('%06d',image_index+1 + (k-row)),'0101.png');

                    %display the forward image
                    imshow(imread(fullfile(scene_path,'rgb',next_image_name)));
                    hold on;
                    title(strcat('(forward - direct(blue):   ', next_image_name));

                    %display all the forward boxes
                    for kk=1:size(forward_rec_boxes,1)
                        bbox = double(forward_rec_boxes(kk,:));
                        rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',1, 'EdgeColor','b');
                    end%for kk  

                    click_through = 1;
                    %display all the current boxes
                    for kk=1:size(rec_dets,1)
                        bbox = double(rec_dets(kk,:));
                        a = rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], 'LineWidth',3, 'EdgeColor','r');

                        %click through each box
                        if(click_through)
                            [~,~,but] = ginput(1);

                            if(but ~=1)
                                click_through = 0;
                            end
                            set(a,'Visible','off'); 
                        end
                    end%for k  

                    %just pause to allow visualization
                    temp = ginput(1);
                end%if debug


                %% GET DATA
                result =  density_calculations(cur_rec_boxes,forward_rec_boxes, ...
                                                cur_gt_boxes, forward_gt_boxes, ...
                                                iou_threshold);

                forward_totals_by_res(q,:,(k-row)) = forward_totals_by_res(q,:,(k-row)) + result;
                forward_num_used_by_res(q,(k-row)) = forward_num_used_by_res(q,(k-row)) + 1;

            end%do forward stuff



            %% do move right stuff
            for k=(col+1):grid_size

                right_rec_boxes = rec_boxes{row,k};
                right_gt_boxes = gt_boxes{row,k};

                result =  density_calculations(cur_rec_boxes,right_rec_boxes, ...
                                                cur_gt_boxes, right_gt_boxes, ...
                                                iou_threshold);

                right_totals_by_res(q,:,(k-col)) = right_totals_by_res(q,:,(k-col)) + result;
                right_num_used_by_res(q,(k-col)) = right_num_used_by_res(q,(k-col)) + 1;


            end%for right side
            
         end%if cmopare to first
    end % for j, each image name
        
    
    
     %% compute average stats
     if(~compare_to_first && ~get_all_results_per_res)
         forward_avgs_by_res(q,:,:) = squeeze(forward_totals_by_res(q,:,:)) ./ repmat(forward_num_used_by_res(q,:),[5,1]);
        right_avgs_by_res(q,:,:) = squeeze(right_totals_by_res(q,:,:)) ./ repmat(right_num_used_by_res(q,:),[5,1]);
     end
    
    
    %% make figure
    if(length(all_score_thresholds) ==1)
        
        
        if(compare_to_first)
            %%
            bwip_fig = figure;
            imagesc(squeeze(results_grid(:,:,BOXES_MISSING_IOU_PERCENT)));
            hold on;
            h = colorbar;
            
            if(use_rec_boxes)
                title(strcat('FIRST POINT: Fast RCNN Boxes ', gt_instance, ...
                       ' ', category_name,' Missing IOU  > ',  ...
                        num2str(iou_threshold)));
            else
                title(strcat('FIRST POINT: Selective Search Boxes ', gt_instance, ...
                   ' ', category_name, ' Missing IOU  > ',  ...
                    num2str(iou_threshold)));
            end
            xlabel('X Poisiton (1 = 10cm)');
            xlabel('Y Poisiton (1 = 10cm)');
            hold off;
            if(save_figs)
                if(use_rec_boxes)
                    saveas(bwip_fig,fullfile(scene_path,'density_experiments', strcat('compare_to_first_', ...
                           gt_instance, ' ', category_name, '_fast_rcnn_bwip_IOU_',  ...
                            num2str(iou_threshold), '_Score_' , num2str(score_threshold),'.jpg')));
                else
                    saveas(bwip_fig,fullfile(scene_path,'density_experiments', strcat('compare_to_first_', ...
                       gt_instance, ' ', category_name, '_ss_bwip_IOU_',  ...
                        num2str(iou_threshold),'.jpg')));
                  
                end
            end
            
            if(use_gt_boxes)
                gwip_fig = figure;
                imagesc(squeeze(results_grid(:,:,GT_MISSING_IOU_PERCENT)));
                hold on;
                h = colorbar;
                title(strcat('Compared to FIRST POINT: GT Missing IOU  > ',  ...
                        num2str(iou_threshold)));
                xlabel('X Poisiton (1 = 10cm)');
                xlabel('Y Poisiton (1 = 10cm)');
                hold off;
                if(save_figs)
                    saveas(gwip_fig,fullfile(scene_path,'density_experiments', strcat('compare_to_first_', ...
                             gt_instance, '_fast_rcnn_bwip_IOU_',  ...
                            num2str(iou_threshold),'.jpg')));
                end
            
           
                scores_fig = figure;
                title(strcat('SCORES fast rcnn   IOU > ', num2str(iou_threshold)));
                for j=1:length(gt_instances)
                    subplot(2,4,j);


                    imagesc(scores_grid(:,:,j));
                    hold on;
                    caxis([0,1]);
                    title(gt_instances{j});
    %                 xlabel('X Poisiton (1 = 10cm)');
    %                 xlabel('Y Poisiton (1 = 10cm)');
                    hold off;
                end
                if(save_figs)
                    saveas(scores_fig,fullfile(scene_path,'density_experiments', strcat('compare_to_first_', ...
                            gt_instance,'_fast_rcnn_scores_IOU_',  ...
                            num2str(iou_threshold),'.jpg')));        
                end     
            end
                
            
            
            
            
            
            
            
            
             
        elseif(get_all_results_per_res)
             %%  
            bwip_forward_fig = figure;
            imagesc(squeeze(forward_results(:,:,BOXES_MISSING_IOU_PERCENT)));
            hold on;
            h = colorbar;
            
            if(use_rec_boxes)
                title(strcat('MOVE: ', num2str(res),' Fast RCNN Boxes ', gt_instance, ...
                       ' ', category_name,' Missing IOU  > ',  ...
                        num2str(iou_threshold)));
            else
                title(strcat('MOVE: ', num2str(res),' Selective Search Boxes ', gt_instance, ...
                   ' ', category_name, ' Missing IOU  > ',  ...
                    num2str(iou_threshold)));
            end
            xlabel('X Poisiton (1 = 10cm)');
            xlabel('Y Poisiton (1 = 10cm)');
            hold off;
            if(save_figs)
                if(use_rec_boxes)
                    saveas(bwip__forward_fig,fullfile(scene_path,'density_experiments', strcat('move_',num2str(res),'_', ...
                            category_name, '_fast_rcnn_bwip_IOU_',  ...
                            num2str(iou_threshold),'.jpg')));
                else
                    saveas(bwip_forward_fig,fullfile(scene_path,'density_experiments', strcat('move_',num2str(res),'_', ...
                        category_name, '_ss_bwip_IOU_',  ...
                        num2str(iou_threshold),'.jpg')));
                  
                end
            end
            
%             if(use_gt_boxes)
%                 gwip_fig = figure;
%                 imagesc(squeeze(results_grid(:,:,GT_MISSING_IOU_PERCENT)));
%                 hold on;
%                 h = colorbar;
%                 title(strcat('Compared to FIRST POINT: GT Missing IOU  > ',  ...
%                         num2str(iou_threshold)));
%                 xlabel('X Poisiton (1 = 10cm)');
%                 xlabel('Y Poisiton (1 = 10cm)');
%                 hold off;
%                 if(save_figs)
%                     saveas(gwip_fig,fullfile(scene_path,'density_experiments', strcat('compare_to_first_', ...
%                              gt_instance, '_fast_rcnn_bwip_IOU_',  ...
%                             num2str(iou_threshold),'.jpg')));
%                 end
%             
%            
%                 scores_fig = figure;
%                 title(strcat('SCORES fast rcnn   IOU > ', num2str(iou_threshold)));
%                 for j=1:length(gt_instances)
%                     subplot(2,4,j);
% 
% 
%                     imagesc(scores_grid(:,:,j));
%                     hold on;
%                     caxis([0,1]);
%                     title(gt_instances{j});
%     %                 xlabel('X Poisiton (1 = 10cm)');
%     %                 xlabel('Y Poisiton (1 = 10cm)');
%                     hold off;
%                 end
%                 if(save_figs)
%                     saveas(scores_fig,fullfile(scene_path,'density_experiments', strcat('compare_to_first_', ...
%                             gt_instance,'_fast_rcnn_scores_IOU_',  ...
%                             num2str(iou_threshold),'.jpg')));        
%                 end     
%             end   
            
                
         
        else%not compare to first
            %%       sdfa
            forward_totals_by_res = squeeze(forward_totals_by_res);
            forward_avgs_by_res =  squeeze(forward_avgs_by_res);
            forward_num_used_by_res =  squeeze(forward_num_used_by_res);


            right_totals_by_res =  squeeze(right_totals_by_res);
            right_avgs_by_res =  squeeze(right_avgs_by_res);
            right_num_used_by_res =  squeeze(right_num_used_by_res);




            bwip_fig = figure;
            plot(1:length(forward_avgs_by_res),forward_avgs_by_res(BOXES_MISSING_IOU_PERCENT,:),'r.-','MarkerSize',15);
            hold on;
            plot(1:length(right_avgs_by_res),right_avgs_by_res(BOXES_MISSING_IOU_PERCENT,:),'b.-','MarkerSize',15);

            if(use_rec_boxes)
                title(strcat('Fast RCNN Boxes Missing IOU  > ',  ...
                    num2str(iou_threshold), ' Score > ' , num2str(score_threshold)));
            else
                title(strcat('Seletive Search Boxes Missing IOU  > ',  ...
                    num2str(iou_threshold)));
            end

            xlabel('Distance (10 cm)');
            ylabel('Percent Boxes without IOU');
            legend('forward','right');

            if(save_figs)
                if(use_rec_boxes)
                    saveas(bwip_fig,fullfile(scene_path,'density_experiments', strcat('fast_rcnn_bwip_IOU_',  ...
                        num2str(iou_threshold), '_Score_' , num2str(score_threshold),'.jpg')));
                else
                    saveas(bwip_fig,fullfile(scene_path,'density_experiments', strcat('ss_bwip_IOU_',  ...
                        num2str(iou_threshold),'.jpg')));

                end
            end




            if(use_gt_boxes)
                gwip_fig = figure;
                plot(1:length(forward_avgs_by_res),forward_avgs_by_res(GT_MISSING_IOU_PERCENT,:),'r.-','MarkerSize',15);
                hold on;
                plot(1:length(right_avgs_by_res),right_avgs_by_res(GT_MISSING_IOU_PERCENT,:),'b.-','MarkerSize',15);

                if(use_rec_boxes)
                   title(strcat('Fast RCNN GT Missing IOU  > ',  ...
                     num2str(iou_threshold), ' Score > ' , num2str(score_threshold)));
                else
                    title(strcat('Selective Search GT Missing IOU  > ',  ...
                        num2str(iou_threshold)));
                end
                xlabel('Distance (10 cm)');
                ylabel('Percent GT Boxes without IOU');
                legend('forward','right');

                if(save_figs)
                    saveas(gwip_fig,fullfile(scene_path,'density_experiments', strcat('ss_gwip_IOU_',  ...
                        num2str(iou_threshold),'.jpg')));
                end

            end%if use gt boxes
        end%if compare to first
        
    end%if just 1 threshold
   end %for q, each score_threshold
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   if(length(all_score_thresholds) > 1)
       
        bwip_fig = figure;

        x_dist = ones(1,grid_size*length(all_score_thresholds));
        for qq=1:grid_size
            start_i = (length(all_score_thresholds)*(qq-1) + 1);
            end_i = start_i + length(all_score_thresholds)-1;
            x_dist(start_i:end_i) = qq;
        end%for qq

        y_score = repmat(all_score_thresholds,[1,grid_size]);

        z_percent = squeeze(forward_avgs_by_res(:,BOXES_MISSING_IOU_PERCENT,:));
        z_percent = reshape(z_percent,[1,size(z_percent,1)*size(z_percent,2)]);


        z_percent_R = squeeze(right_avgs_by_res(:,BOXES_MISSING_IOU_PERCENT,:));
        z_percent_R = reshape(z_percent_R,[1,size(z_percent_R,1)*size(z_percent_R,2)]);


        scatter(x_dist,y_score,50,z_percent,'filled','s');
        h = colorbar;
        ylabel(h,'percent without iou');

        hold on;
        scatter(x_dist+.25,y_score,50,z_percent_R,'filled','d');

        title(strcat('Fast RCNN Boxes Missing IOU  > ',  ...
            num2str(iou_threshold)));
        xlabel('Distance (10 cm)');
        ylabel('Score threshold');
        legend('forward','right');

        if(save_figs)
        saveas(bwip_fig,fullfile(scene_path,'density_experiments', strcat('fast_rcnn_bwip_IOU_',  ...
           num2str(iou_threshold), '_Score_all','.jpg')));
        end
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        gwip_fig = figure;

        x_dist = ones(1,grid_size*length(all_score_thresholds));
        for qq=1:grid_size
            start_i = (length(all_score_thresholds)*(qq-1) + 1);
            end_i = start_i + length(all_score_thresholds)-1;
            x_dist(start_i:end_i) = qq;
        end%for qq

        y_score = repmat(all_score_thresholds,[1,grid_size]);

        z_percent = squeeze(forward_avgs_by_res(:,GT_MISSING_IOU_PERCENT,:));
        z_percent = reshape(z_percent,[1,size(z_percent,1)*size(z_percent,2)]);


        z_percent_R = squeeze(right_avgs_by_res(:,GT_MISSING_IOU_PERCENT,:));
        z_percent_R = reshape(z_percent_R,[1,size(z_percent_R,1)*size(z_percent_R,2)]);


        scatter(x_dist,y_score,50,z_percent,'filled','s');
        h = colorbar;
        ylabel(h,'percent without iou');

        hold on;
        scatter(x_dist+.25,y_score,50,z_percent_R,'filled','d');

        title(strcat('Fast RCNN GT Missing IOU  > ',  ...
            num2str(iou_threshold)));
        xlabel('Distance (10 cm)');
        ylabel('Score threshold');
        legend('forward','right');

        if(save_figs)
        saveas(gwip_fig,fullfile(scene_path,'density_experiments', strcat('fast_rcnn_gwip_IOU_',  ...
           num2str(iou_threshold), '_Score_all','.jpg')));
        end
   end  %if > 1 score_threshold
   
    
end  %for i, each scene
    
    

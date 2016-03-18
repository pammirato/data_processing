function [result] = ...
                density_calculations(rec_boxes1, rec_boxes2,gt_boxes1,gt_boxes2, ...
                iou_threshold,gt_score)

    bwip = 0;
    gwip = 0;
    total_boxes_diff = size(rec_boxes2,1);
    boxes_without_iou = 0;
    gt_without_iou_diff = 0;
    if(size(rec_boxes1,1) == 0)
        result = [total_boxes_diff,boxes_without_iou,bwip,gt_without_iou_diff,gwip];
        return;
    end
            
            
    
    
    
    %% just rec stuff
    total_boxes_diff = abs(size(rec_boxes1,1) - size(rec_boxes2,1));
    
    results_ious = iou_many_to_many(rec_boxes1,rec_boxes2);
    
    [rows, ~] = find(results_ious > .5);
    
    boxes_without_iou = size(rec_boxes1,1) - length(unique(rows));
    
    bwip = boxes_without_iou / (size(rec_boxes1,1));
    
    if(~(bwip < 1.000000000001))
        breakp = 1;
    end
    assert(bwip < 1.000000000001);
    assert(bwip > -0.0000001)
    
    
    
    
    %% using gt stuff
    
    if(strcmp(class(gt_boxes1),'double'))%make sure we are using gt_boxes
        if(~(gt_boxes1 == -1))
            gtwi1 = 0;
            gtwi2 = 0;
            ious = iou_one_to_many(gt_boxes1,rec_boxes1);

            if(isempty(find(ious > iou_threshold,1)))
               gtwi1  = 1;
            end



            ious = iou_one_to_many(gt_boxes2,rec_boxes2);

            if(isempty(find(ious > iou_threshold,1)))
                gtwi2  = 1;
            end
            
            gt_without_iou_diff = (gtwi1 ~= gtwi2);
            gwip = gt_without_iou_diff;
        end
            
        
        
        
        
        
        
        
        
        
        
        
        
    else
        
        
        
        
        
        
        
        categories1 = fields(gt_boxes1);

        gt_without_iou_indicators1 = zeros(1,length(categories1)); 
        gt_without_iou_indicators2 = zeros(1,length(categories1)); 

        total_gt_boxes_compared = 0;
        for i=1:length(categories1)
            try
                gt_box1 = gt_boxes1.(categories1{i});
                gt_box2 = gt_boxes2.(categories1{i});
            catch
                continue;
            end

            total_gt_boxes_compared = total_gt_boxes_compared +1;

            ious = iou_one_to_many(gt_box1,rec_boxes1);

            if(isempty(find(ious > iou_threshold,1)))
                gt_without_iou_indicators1(i)  = 1;
            end



            ious = iou_one_to_many(gt_box2,rec_boxes2);

            if(isempty(find(ious > iou_threshold,1)))
                gt_without_iou_indicators2(i)  = 1;
            end
        end%for i, each box in gt_boxes1

        gt_without_iou_diff = pdist([gt_without_iou_indicators1; gt_without_iou_indicators2], ...
                                    'hamming');

        gwip = gt_without_iou_diff/total_gt_boxes_compared;

    end
    
    
    result = [total_boxes_diff,boxes_without_iou,bwip,gt_without_iou_diff,gwip];
end
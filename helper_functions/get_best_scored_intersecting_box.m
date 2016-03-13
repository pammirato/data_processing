function [score] = get_best_scored_intersecting_box(box,rec_boxes,iou_threshold)
%takes a given bounding box, and a bunch of other bounding boxes
%with scores, and finds returns the box with the highest score that
%also has intersection over union > .5 with the given box.



    score = 0;
    
    
    ious = iou_one_to_many(box, rec_boxes(:,1:4));
    
    [~,index] = max(ious);
    
    if(ious(index) > iou_threshold)
        score = rec_boxes(index,5);
    end


end

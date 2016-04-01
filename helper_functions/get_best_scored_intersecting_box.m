function [best_box] = get_best_scored_intersecting_box(box,rec_boxes,iou_threshold)
%takes a given bounding box, and a bunch of other bounding boxes
%with scores, and finds returns the box with the highest score that
%also has intersection over union > .5 with the given box.

    %format
    box = double(box);
    rec_boxes = double(rec_boxes);

    %get the iou of the given box with all the rec boxes
    ious = get_bboxes_iou(box, rec_boxes(:,1:4));
    
    %get all rec boxes with iou > iou_threshold
    valid_rec_boxes = rec_boxes(ious > iou_threshold, :);
    
    %get the valid box with the highest score
    [~,index] = max(valid_rec_boxes(:,5));
    best_box = valid_rec_boxes(index,:); 
   


end

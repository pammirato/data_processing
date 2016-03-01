function [result_ious] = iou_many_to_many (boxes1, boxes2)
%calculates intersection over union for two rectangles, given ttop left
%and bottom right points


%     x1 = box1(1);
%     y1 = box1(2);
%     x2s = boxes(:,1);
%     y2s = boxes(:,2);


    if(isempty(boxes1) || isempty(boxes2))
        result_ious = [];
        return;
    end
        

    width1s = boxes1(:,3) - boxes1(:,1); 
    height1s = boxes1(:,4) - boxes1(:,2); 
    
    
    width2s = boxes2(:,3) - boxes2(:,1); 
    height2s = boxes2(:,4) - boxes2(:,2); 

    intersection_areas=rectint([boxes1(:,1:2) width1s height1s], ...
                            [boxes2(:,1:2) width2s height2s]);



%     unionCoords=[min(x2,x1),min(y2,y1),max(x2+width2-1,x1+width1-1), ...
%                     max(y2+height2-1,y1+height1-1)];
%
% 
%     unionArea=(unionCoords(3)-unionCoords(1)+1)*(unionCoords(4)-unionCoords(2)+1);


    union_areas = repmat(width1s.*height1s,[1,size(intersection_areas,2)]) + repmat((width2s.*height2s)',[size(intersection_areas,1),1]) - intersection_areas;

    result_ious= intersection_areas ./ union_areas;

end
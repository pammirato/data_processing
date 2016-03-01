function [result_ious] = iou_one_to_many (box1, boxes)
%calculates intersection over union for two rectangles, given ttop left
%and bottom right points


%     x1 = box1(1);
%     y1 = box1(2);
%     x2s = boxes(:,1);
%     y2s = boxes(:,2);

    width1 = box1(3) - box1(1); 
    height1 = box1(4) - box1(2); 
    
    
    width2s = boxes(:,3) - boxes(:,1); 
    height2s = boxes(:,4) - boxes(:,2); 

    intersection_areas=rectint([boxes(:,1:2) width2s height2s], ...
                            [box1(1:2) width1 height1]);



%     unionCoords=[min(x2,x1),min(y2,y1),max(x2+width2-1,x1+width1-1), ...
%                     max(y2+height2-1,y1+height1-1)];
%
% 
%     unionArea=(unionCoords(3)-unionCoords(1)+1)*(unionCoords(4)-unionCoords(2)+1);


    union_areas = repmat(width1*height1,size(width2s)) + width2s.*height2s - intersection_areas;

    result_ious= intersection_areas ./ union_areas;

end
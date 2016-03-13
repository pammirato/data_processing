function [result_ious] = get_bboxes_iou (boxes1, boxes2)
%calculates intersection over union for two rectangles,
% given 'top left' and 'bottom right' points
%**** (top left and bottom right in image, actually bottom left and top right) ****

    %make sure the boxes are not empty
    if(isempty(boxes1) || isempty(boxes2))
        result_ious = [];
        return;
    end
        

    %get widths and heights of all the boxes in each set
    widths_1 = boxes1(:,3) - boxes1(:,1); 
    heights_1 = boxes1(:,4) - boxes1(:,2); 
    widths_2 = boxes2(:,3) - boxes2(:,1); 
    heights_2 = boxes2(:,4) - boxes2(:,2); 

    %calculate the interstion areas between each pair of boxes from each set
    intersection_areas=rectint([boxes1(:,1:2) widths_1 heights_1], ...
                            [boxes2(:,1:2) widths_2 heights_2]);

    %calculate the union areas between each pair of boxes from each set
    union_areas = repmat(widths_1.*heights_1,[1,size(intersection_areas,2)]) + repmat((widths_2.*heights_2)',[size(intersection_areas,1),1]) - intersection_areas;


    %do the division(union areas should never be 0 if correct boxes were given)
    result_ious= intersection_areas ./ union_areas;
end

function [result_iou] = iou (box1, box2)
%calculates intersection over union for two rectangles, given ttop left
%and bottom right points


    x1 = box1(1);
    y1 = box1(2);
    x2 = box2(1);
    y2 = box2(2);

    width1 = box1(3) - box1(1); 
    height1 = box1(4) - box1(2); 
    width2 = box2(3) - box2(1); 
    height2 = box2(4) - box2(2); 

    intersectionArea=rectint([box2(1:2) width2 height2], ...
                            [box1(1:2) width1 height1]);



    unionCoords=[min(x2,x1),min(y2,y1),max(x2+width2-1,x1+width1-1),max(y2+height2-1,y1+height1-1)];


    unionArea=(unionCoords(3)-unionCoords(1)+1)*(unionCoords(4)-unionCoords(2)+1);

    result_iou=intersectionArea/unionArea;

end
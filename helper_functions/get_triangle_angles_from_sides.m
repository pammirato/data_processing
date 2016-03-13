function [A, B, C] = get_triangle_angles(a,b,c)
%returns the angles of a triangle, given the sides
    C = acosd( (a^2 +b^2 -c^2) / (2*a*b));
    B = acosd( (a^2 +c^2 -b^2) / (2*a*c));
    A = acosd( (c^2 +b^2 -a^2) /( 2*c*b));
end%get triangle angles

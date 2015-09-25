function [R] = quaternion_to_matrix2(quat)

    w = quat(1);
    x = quat(2);
    y = quat(3);
    z = quat(4);

    n = sqrt(w*w + x*x + y*y + z*z);

    w = w*n;
    x = x*n;
    y = y*n;
    z = z*n;


    R = [1.0 - 2*y^2 - 2*z^2,  2*x*y - 2*z*w,        2*x*z + 2*y*w;
         2*x*y + 2*z*w,        1.0 - 2*x^2 - 2*z^2,  2*y*z - 2*x*w;
         2*x*z - 2*y*w,        2*y*z + 2*x*w,        1.0 - 2*x^2 - 2*y^2];

end

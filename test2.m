
l_filter = [-1 1 0];
r_filter = [0 1 -1];
u_filter = l_filter';
d_filter = r_filter';



ul_fil = zeros(5,5);
ul_fil(1:3,1:3) = 1;
ur_fil = zeros(5,5);
ur_fil(1:3,3:5) = 1;
dl_fil = zeros(5,5);
dl_fil(3:5,1:3) = 1;
dr_fil = zeros(5,5);
dr_fil(3:5,3:5) = 1;



%y = x;
%y(y>750) = 0;
%
%cul = imfilter(y,ul_fil);
%cur = imfilter(y,ur_fil);
%cdl = imfilter(y,dl_fil);
%cdr = imfilter(y,dr_fil);
%
%
%to_interp = (((cul>0) + (cdr>0)) >1) | (((cdl>0) +(cur>0)) > 1);
%to_interp = to_interp & (y == 0);
%
%m_fil = fspecial('average', 11);
%
%avged = imfilter(y,m_fil);




slice_dists = [500, 750, 1000];



slice_img = zeros(size(pc_depth_img));

for kl=1:length(slice_dists)
  kl_dist = slice_dists(kl);

  temp_img = pc_depth_img;
  temp_img(temp_img > kl_dist) = 0;
  temp_mask = temp_img == 0;
  temp_img = temp_img + (temp_mask .* slice_img);     

  cul = imfilter(temp_img,ul_fil);
  cur = imfilter(temp_img,ur_fil);
  cdl = imfilter(temp_img,dl_fil);
  cdr = imfilter(temp_img,dr_fil);


  to_interp = (((cul>0) + (cdr>0)) >1) | (((cdl>0) +(cur>0)) > 1);
  to_interp = to_interp & (temp_img == 0);

  slice_img = regionfill(temp_img, to_interp);

end%for kl

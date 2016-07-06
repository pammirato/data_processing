




ts1 = [shared_structs1.t];
ts2 = [shared_structs2.t];



center_1 = mean(ts1')';
center_2 = mean(ts2')';



H = zeros(3,3);
for il=1:length(ts1)

  a = (ts1(:,il) - center_1)*(ts2(:,il)-center_2)';


  H = H+a;
end


[U,S,V] = svd(H);



R = V*U';


if det(R) < 0
  disp('error');
end



t = -R * center_1 + center_2;



M = zeros(length(ts1)*3, 12);

for il=1:3:3*length(ts1)

  tsi = floor((il-1)/3) + 1;

  M(il,1:4) = [ts1(:,tsi)', 1];
  M(il+1,5:8) = [ts1(:,tsi)', 1];
  M(il+2,9:12) = [ts1(:,tsi)', 1];

end%for il


proj = zeros(3*length(ts2), 1);

for il=1:length(proj)
 
  tsi = floor((il-1)/3) + 1;
  proj(il) = ts2(mod(il+2,3)+1,tsi);

end%for il





trans = pinv(M) * proj;


transf = [reshape(trans, [4,3])'; 0,0,0,1];



for il=1:length(ts1)


  t1 = [ts1(:,1);1]';

  t2 = [ts2(:,2)];

  t1_trans = t1 * transf;


  t1t = t1_trans ./ t1_trans(4);

  t1t = t1t(1:3);

  diff = abs(t1t - t2');

  if(max(diff) < .01)
    disp('found')
  end
end






w1 = zeros(3,length(a));
w2 = w1;

for il=1:length(defining_structs)

  cs = defining_structs(il);

  w1(:,il) = -(cs.R)' * cs.t;
  w2(:,il) = -(cs.R) * cs.t;
  
end



plot(w1(1,:), w1(3,:), 'r.');
axis equal
figure
plot(w2(1,:), w2(3,:),'k.');
axis equal
hold on


dirs = [defining_structs.direction];

quiver(w2(1,:), w2(3,:), dirs(1,:), dirs(3,:), 'ShowArrowHead', 'on','Color', 'b');

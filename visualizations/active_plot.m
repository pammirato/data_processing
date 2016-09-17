


T = [0 3 5 10 20];
Ts = {'0', '3', '5', '10', '20'};



our_acc = [0.3921334923,0.4612634088,0.5208581645,0.568533969,0.5804529201; ...
          0.3263888889,0.4920634921,0.5823412698,0.6537698413,0.6736111111; ...
          0.2389463782,0.4063969897,0.4976481656,0.549388523,0.5634995296];


rand_acc = [0.3921334923,0.3241954708,0.3694874851,0.3504171633,0.3706793802;...
            0.3263888889,0.2916666667,0.3110119048,0.349702381,0.3978174603;...
            0.2389463782,0.252116651,0.2793979304,0.3132643462,0.3311382879];

forward_acc = [0.3921334923,0.3992848629,0.4064362336,0.4266984505,0.4266984505;...
              0.3263888889,0.3655753968,0.3849206349,0.3918650794,0.3928571429;...
              0.2389463782,0.3019755409,0.326434619,0.338664158,0.338664158];





our_acc_improve = (our_acc(:,2:end) - our_acc(:,1:end-1)) ./ our_acc(:,1:end-1);
our_acc_improve2 = (our_acc - repmat(our_acc(:,1),1,size(our_acc,2))) ./ ...
                              repmat(our_acc(:,1),1,size(our_acc,2));


rand_acc_improve = (rand_acc(:,2:end) - rand_acc(:,1:end-1)) ./ rand_acc(:,1:end-1);
rand_acc_improve2 = (rand_acc - repmat(rand_acc(:,1),1,size(rand_acc,2))) ./ ...
                              repmat(rand_acc(:,1),1,size(rand_acc,2));



forward_acc_improve = (forward_acc(:,2:end) - forward_acc(:,1:end-1)) ./ forward_acc(:,1:end-1);
forward_acc_improve2 = (forward_acc - repmat(forward_acc(:,1),1,size(forward_acc,2))) ./ ...
                              repmat(forward_acc(:,1),1,size(forward_acc,2));



mean_ours = mean(our_acc_improve2);
mean_rand = mean(rand_acc_improve2);
mean_forward = mean(forward_acc_improve2);

std_ours = std(our_acc_improve2);
std_rand = std(rand_acc_improve2);
std_forward = std(forward_acc_improve2);


f = figure;
hold on;


plot(mean_ours, 'r-');
plot(mean_rand, 'b-x');
plot(mean_forward, 'g-o');
legend({'Our method', 'Forward Baseline', 'Random Baseline'});

%plot(min(our_acc_improve2), 'r.');
%plot(min(rand_acc_improve2), 'bx');
%plot(min(forward_acc_improve2), 'go');
%plot(max(our_acc_improve2), 'r.');
%plot(max(rand_acc_improve2), 'bx');
%plot(max(forward_acc_improve2), 'go');

plot(mean_ours - std_ours, 'r.');
plot(mean_rand - std_ours, 'bx');
plot(mean_forward - std_ours, 'go');
plot(mean_ours + std_ours, 'r.');
plot(mean_rand + std_ours, 'bx');
plot(mean_forward + std_ours, 'go');






%set(gca, 'ColorOrder', [1 0 0; 0 1 0; 0 0 1]);
%plot(our_acc_improve2');
%
%plot(rand_acc_improve2', '--');
%plot(forward_acc_improve2', ':');
%
%legend({'Our S1', 'Our S2','Our S3','Random S1','Random S2','Random S3', ...
%            'Forward S1','Forward S2','Forward S3'});


set(gca, 'XTick', 1:length(Ts));
set(gca, 'XTickLabel', Ts);
%set(gca, 'XTick', T);

xlabel('T (number of moves)');
%ylabel('Percent increase over single image');
ylabel('average percent increase over single image');
title('Active Vision Classification Performance');

hold off;


%print('/playpen/ammirato/Pictures/icra_2016_figures/ab_active_plot.jpg');
%saveas(f, '/playpen/ammirato/Pictures/icra_2016_figures/ab_active_plot.jpg');
saveas(f, '/playpen/ammirato/Pictures/icra_2016_figures/ac_active_plot.jpg');




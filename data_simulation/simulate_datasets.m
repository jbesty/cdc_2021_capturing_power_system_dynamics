clear all

global  R L  Kpw Kiw Ta Tp Tq
global Pext Qext E wref

global c d Vmin % partial tripping parameters

global f e Vint % partial tripping parameters

global u1 Tint T2

global m n Inom % reactive power contributions and limits

global Krci Krcv n_s f1 iq_sup

% if the training data shall be create, set flag to true, otherwise a
% validation dataset is created
training_data_set = true;

parameters_transformers
parameters_VSC
addpath('Power Flow Initialization')

Pref = 0.8;
Qref = 0.2;

theta_g = 0;
E = 1;

Power_flow_1VSC

find_equilibrium

iQsupp = 0;

d_x0 = [x0_2 z0_2];

x_init = d_x0;   

M = eye(17);
M(6:end,6:end)=0;

options = odeset('Mass',M,'RelTol',1e-9,'AbsTol',1e-9*ones(1,17));

u=0;
Tall = [];
Xall = [];

list_disturbance_duration = linspace(0.1,0.25,4);

E_post_fault = 1;

% X1 =[];
% E1 = [];
% E2 = [];

list_E_disturbed_training = linspace(0.8, 0.2, 10);
list_E_disturbed_testing = [0.75, 0.7, 0.65, 0.55, 0.5, 0.45, 0.35, 0.3, 0.25];


if training_data_set == true
    list_E_disturbed = list_E_disturbed_training;
else
    list_E_disturbed = list_E_disturbed_testing;
end


%%
Ev1=[];
X1 =[];
Ev2 = [];
Tv = [];
X2 = [];
k = 1;
EE1 = [];
EE2 = [];
DT1 = [];
DT2 = [];
DV1 = [];
DV2 = [];

min_voltage = zeros(length(list_E_disturbed), length(list_disturbance_duration));
lvrt_index = zeros(length(list_E_disturbed), length(list_disturbance_duration));
final_power = zeros(length(list_E_disturbed), length(list_disturbance_duration));

for ii=1:length(list_E_disturbed)
    %% pre state 
    Tall = [];
    Xall = [];
    for jj=1:length(list_disturbance_duration)
        % tspan
        f1 = 1;
        iq_sup = 0;
        t_span_fault = 0:0.001:list_disturbance_duration(jj);
        E = list_E_disturbed(ii);
        [T,X]=ode23t(@(t,x)compute_state_update(t,x,u),t_span_fault,x_init,options);
        
        EE1{jj} = E*ones(size(T,1),1);
        DT1{jj} = list_disturbance_duration(jj)*ones(size(T,1),1);
        DV1{jj} = (1-list_E_disturbed(ii))*ones(size(T,1),1);
        
        Ev1(ii) = E;
        
        Tall = T;
        Xall = X;

        X1{jj} = X;
        T1t{jj} = T;
        
        t_span_post_fault = (list_disturbance_duration(jj)+0.00001):0.001:1;
        E = E_post_fault;
        [T,X]=ode23t(@(t,x)compute_state_update(t,x,u),t_span_post_fault,X(end,:),options);
        
        EE2{jj} = E*ones(size(T,1),1);
        DT2{jj} = (list_disturbance_duration(jj))*ones(size(T,1),1);
        DV2{jj} = (1-list_E_disturbed(ii))*ones(size(T,1),1);
        
        T2t{jj} = T;
        Tall=[Tall;T];
        Xall=[Xall;X];

        X2{jj} = X;
        Ev2(k) = E;
        X12{k} = [X1{jj}; X2{jj}];
        T12{k} = [T1t{jj}; T2t{jj}];
        E12{k} = [EE1{jj}; EE2{jj}];
        DV12{k} = [DV1{jj}; DV2{jj}];
        DT12{k} = [DT1{jj}; DT2{jj}];
        k =k+1;
        min_voltage(ii, jj) = Xall(length(t_span_fault),5);
        final_power(ii, jj) = Xall(1001,16);
        
        if min(Xall(:,5)) < 0.7
            lvrt_index(ii, jj) = find( Xall(:,5) < 0.7, 1 );
        end
    end
end

if training_data_set == true
    save('training_data.mat','T12','E12', 'DV12', 'DT12', 'X12')
else
    save('validation_data.mat','T12','E12', 'DV12', 'DT12', 'X12')
end
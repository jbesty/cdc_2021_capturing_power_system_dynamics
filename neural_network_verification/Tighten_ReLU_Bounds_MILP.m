% Compute the tightening of the bounds on the MILP formulation
% First: Interval Arithmetic with bounds on the input
% Second: LP relaxation to tighten bounds
% Third: Full MILP to tighten bounds

close all;
clear all;

% add Gurobi to path
addpath(genpath('C:\gurobi911\win64'));

Time_Scalability = [] ;

tElapsed=tic(); 
       
% Load the neural network weights and biases
W_input = csvread('W0.csv').';
W_output = csvread('W3.csv').';
W{1} = csvread('W1.csv').';
W{2} = csvread('W2.csv').';
bias{1} = csvread('b0.csv');
bias{2} = csvread('b1.csv');
bias{3} = csvread('b2.csv');
bias{4} = csvread('b3.csv');
        
% number of inputs to the NN
nr_inputs = 3;
% number of hidden layers
ReLU_layers = 3;
% number of neurons per layer
nr_neurons = 50;
             
zk_hat_max = ones(nr_neurons,1,ReLU_layers)*(1000000);% upper bound on zk_hat (Here we will need to use some bound tightening)
zk_hat_min = ones(nr_neurons,1,ReLU_layers)*(-1000000);% lower bound on zk_hat (Here we will need to use some bound tightening)
        
% use interval arithmetic to compute tighter bounds
% initial input bounds
input_upper_bound = [1.0; 0.8; 0.25];
input_lower_bound = [0.0; 0.2; 0.1];
zk_hat_max(:,1,1) = max(W_input,0)*input_upper_bound+min(W_input,0)*input_lower_bound+bias{1};
zk_hat_min(:,1,1) = min(W_input,0)*input_upper_bound+max(W_input,0)*input_lower_bound+bias{1};
for jj = 1:ReLU_layers-1
    zk_hat_max(:,1,jj+1) = max(W{jj},0)*max(zk_hat_max(:,1,jj),0)+min(W{jj},0)*max(zk_hat_min(:,1,jj),0)+bias{jj+1};
    zk_hat_min(:,1,jj+1) = min(W{jj},0)*max(zk_hat_max(:,1,jj),0)+max(W{jj},0)*max(zk_hat_min(:,1,jj),0)+bias{jj+1};
end

fprintf('\n Tightening of the ReLU bounds \n')

zk_hat_max_cur = zk_hat_max;
zk_hat_min_cur = zk_hat_min;
        
for run = 1:2
    tic();
    % build relaxed/MILP optimization problem
    if run == 1
        % first solve LP relaxation
        LP_relax = true;
    else
        % second solve full MILP formulation
        LP_relax = false;
    end
    % construct otpimization problem of neural network
    NN_input = sdpvar(nr_inputs,1);
    if LP_relax == true %integer relaxation
        ReLU = sdpvar(nr_neurons,1,ReLU_layers);
    else
        ReLU = binvar(nr_neurons,1,ReLU_layers);
    end
    
    zk_hat = sdpvar(nr_neurons,1,ReLU_layers);
    zk = sdpvar(nr_neurons,1,ReLU_layers);
                
    constraints_tightening = [];
    
    % input restrictions
    constraints_tightening = [constraints_tightening;...
        input_lower_bound <= NN_input];
    constraints_tightening = [constraints_tightening;...
        NN_input <= input_upper_bound];
    
    % input layer
    constraints_tightening = [constraints_tightening; ...
        zk_hat(:,:,1) == W_input*NN_input + bias{1}];
    
    % hidden layers
    for ii = 1:ReLU_layers-1
        constraints_tightening = [constraints_tightening; ...
            zk_hat(:,:,ii+1) == W{ii}*zk(:,:,ii) + bias{ii+1}];
    end
    if LP_relax == true %integer relaxation
        % % integer relaxation
        constraints_tightening = [constraints_tightening; ...
            0<= ReLU <=1 ];
    end
    for kk = 2:ReLU_layers
        for mm = 1:nr_neurons
            constr_tightening_cur = constraints_tightening;
            for ii = 1:ReLU_layers
                for jj = 1:nr_neurons
                    % ReLU (rewriting the max function)
                    constr_tightening_cur = [constr_tightening_cur; ...
                        zk(jj,1,ii) <= zk_hat(jj,1,ii) - zk_hat_min_cur(jj,1,ii).*(1-ReLU(jj,1,ii));...1
                        zk(jj,1,ii) >= zk_hat(jj,1,ii);...
                        zk(jj,1,ii) <= zk_hat_max_cur(jj,1,ii).*ReLU(jj,1,ii);...
                        zk(jj,1,ii) >= 0];
                end
            end
            % solve for lower bound, i.e. minimize
            obj = zk_hat(mm,1,kk);
            options = sdpsettings('solver','gurobi','verbose',0, 'debug', 1);
            diagnostics = optimize(constr_tightening_cur,obj,options);
            if diagnostics.problem ~= 0 
                error('some issue with solving MILP 1');
            else
                zk_hat_min_cur(mm,1,kk)=min(value(zk_hat(mm,1,kk)), zk_hat_max_cur(mm,1,kk)-10^-3);
            end                    
            % solve for upper bound, i.e. maximize
            obj = -zk_hat(mm,1,kk);
            diagnostics = optimize(constr_tightening_cur,obj,options);
            if diagnostics.problem ~= 0 
                error('some issue with solving MILP 2');
            else
                % we need to avoid having both 0 because then we get numerical problems
                zk_hat_max_cur(mm,1,kk)=max(value(zk_hat(mm,1,kk)),zk_hat_min_cur(mm,1,kk)+10^-3);
            end
        end
        fprintf('\n Layer finished\n')
    end
    % this shows by how much we reduced the bounds
    tightening_improvement = mean((zk_hat_max_cur-zk_hat_min_cur)./(zk_hat_max-zk_hat_min));
    zk_hat_max = zk_hat_max_cur;
    zk_hat_min = zk_hat_min_cur;
    fprintf('Tightening layer: %5.2f %% \n', squeeze(tightening_improvement)'*100)
    toc();
end

fprintf('\n Tightening of the ReLU bounds finished \n')
        
save('zk_hat_min','zk_hat_min');
save('zk_hat_max','zk_hat_max');
        
Time_Scalability=toc(tElapsed);
% Time for scalability computations
fprintf('Time to compute the tightened bounds for the MILP reformulation of the trained neural network: %5.2f minutes. \n', Time_Scalability/60)

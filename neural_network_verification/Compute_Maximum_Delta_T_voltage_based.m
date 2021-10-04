function [max_delta_T] = Compute_Maximum_Delta_T_voltage_based(voltage_disturbance, conservativeness)

nr_neurons = 50;
nr_inputs = 3;
ReLU_layers = 3;

% Load the neural network weights and biases
W_input = csvread('W0.csv').';
W_output = csvread('W3.csv').'; % not clear how the indexing works here (going from layer 1 to layer 2)
W{1} = csvread('W1.csv').';
W{2} = csvread('W2.csv').';
bias{1} = csvread('b0.csv'); %net.b; % bias
bias{2} = csvread('b1.csv');
bias{3} = csvread('b2.csv');
bias{4} = csvread('b3.csv');

load('zk_hat_min');
load('zk_hat_max');

% Build mixed-integer linear represenation of trained neural networks
LP_relax = false;
NN_input = sdpvar(nr_inputs,1);

if LP_relax == true %integer relaxation
    ReLU = sdpvar(nr_neurons,1,ReLU_layers);
else
    ReLU = binvar(nr_neurons,1,ReLU_layers);
end

zk_hat = sdpvar(nr_neurons,1,ReLU_layers);
zk = sdpvar(nr_neurons,1,ReLU_layers);
NN_ouput = sdpvar(17,1);

constraints = [];

% input bounds for t, Delta V, Delta T
input_lower_bound = [0.0; 0.2; 0.1];
input_upper_bound = [1.0; 0.8; 0.25];
constraints = [constraints;...
    input_lower_bound <= NN_input];
constraints = [constraints;...
    NN_input <= input_upper_bound];
% t = Delta T at the largest voltage deviation
constraints = [constraints;...
    NN_input(1) == NN_input(3)];
% voltage disturbance magnitude
constraints = [constraints;...
    NN_input(2) == voltage_disturbance];

%input layer constraint
constraints = [constraints; ...
    zk_hat(:,:,1) == W_input*NN_input + bias{1}];

% hidden layer calculations and constraints
for i = 1:ReLU_layers
    for jj = 1:nr_neurons           
            % ReLU (rewriting the max function)
            constraints = [constraints; ...
                zk(jj,1,i) <= zk_hat(jj,1,i) - zk_hat_min(jj,1,i).*(1-ReLU(jj,1,i));...1
                zk(jj,1,i) >= zk_hat(jj,1,i);...
                zk(jj,1,i) <= zk_hat_max(jj,1,i).*ReLU(jj,1,i);...
                zk(jj,1,i) >= 0];
    end
end
for i = 1:ReLU_layers-1
    constraints = [constraints; ...
        zk_hat(:,:,i+1) == W{i}*zk(:,:,i) + bias{i+1}];
end

if LP_relax == true
    % integer relaxation
    constraints = [constraints; ...
        0<= ReLU <=1 ];
end
% output layer
constraints = [constraints; ...
    NN_ouput == W_output * zk(:,:,end) + bias{end}];

% output constraints - maximum allowable voltage deviation 0.7 + epsilon
% p.u.
constraints = [constraints; 
    NN_ouput(5) >= 0.7 + conservativeness];

options = sdpsettings('solver','gurobi','verbose',0,'savesolveroutput',1);

% objective function - maximise Delta T -> minimise -Delta T
objective_function = -(NN_input(3));
diagnostics = optimize(constraints,objective_function,options);
 
% MILP_TIME
if  diagnostics.problem == 12
    max_delta_T = NaN(1);
    return
else
    if diagnostics.problem ~= 0 && diagnostics.problem ~= -1
    % rerun the simulation with presolve set to conservative
        options.gurobi.Presolve = 1;
        diagnostics = optimize(constraints,objective_function,options);
        % if issues persist abort
        if diagnostics.problem ~= 0 && diagnostics.problem ~= 3 && diagnostics.problem ~= -1
            error('some issue with solving MILP PGMAX');
        end
    end

    output_prediction_NN = Predict_NN_Output(value(NN_input).',W_input,bias,W,W_output,ReLU_layers);
    if sum(abs(output_prediction_NN-value(NN_ouput))) > 10^-3
        error('Mismatch in neural network prediction ');
    end

    if diagnostics.solveroutput.result.mipgap>10^-4
        error('MILP gap larger than 10^-4')
    end

    max_delta_T = value(NN_input(3));
    value(objective_function);
end

end


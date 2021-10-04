function NN_output = Predict_NN_Output(NN_input,W_input,bias,W,W_output,nr_ReLU_layers)
% compute the neural network prediction
zk_hat = W_input*(NN_input.') + bias{1};
zk = max(zk_hat,0);
for j = 1:nr_ReLU_layers-1
    zk_hat = W{j}*zk + bias{j+1};
    zk = max(zk_hat,0);
end
NN_output = W_output*zk + bias{end};
end
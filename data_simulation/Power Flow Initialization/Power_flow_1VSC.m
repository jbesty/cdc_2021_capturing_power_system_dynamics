
% clear all;
% close all;
% clc;

global max_iter 
global errortol
max_iter=100000; 
errortol=1e-3;

% Load the Network Data, carry out the power flow and display results
System_matrix_1;
[V, success, n] = PowerFlowNewton(Ybus,Sbus,V0,ref,pv_index,pq_index);
if (success)   
    DisplayResults(V,Ybus,Y_from,Y_to,br_f,br_t,buscode);
end
S_inj = V.*conj(Ybus*V);
    S_to   = V(br_t).*conj(Y_to*V);
    S_from = V(br_f).*conj(Y_from*V); 
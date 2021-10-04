function [V,success,n]=PowerFlowNewton(Ybus,Sbus,V0,ref,pv_index,pq_index)

global max_iter
success=0;
n=0;   %initialize a flag and a counter
V=real(V0)+imag(V0)*1i; % Complex bus voltage vector
% evaluate F(x0)

F = calculate_F(Ybus,Sbus,V,pv_index,pq_index);

fprintf('\n iteration   max P and Q mismatch (p.u.)');
fprintf(' \n --------  ---------------------------');

F
%Check wether tolerance is reached
success = CheckTolerance(F,n);


% Start the Newton Iteration

while (~success) && (n < max_iter)
   n=n+1; % update iteration counter
   % Generate the Jacobian
   [J_dS_dVm, J_dS_dTheta] = generate_Derivatives(Ybus, V);
   J = generate_Jacobian(J_dS_dVm, J_dS_dTheta, pv_index,pq_index);
   % Compute the update step
   dx = (J \ F);
   %Update the voltages, calculate F and check whether tolerence is reached
   [V,Vm,Theta] = Update_Voltages(dx,V,pv_index,pq_index);
   F = calculate_F(Ybus,Sbus,V,pv_index,pq_index);
   success = CheckTolerance(F,n); 
    
end

if ~success
fprintf('\n Newton''s method did not converge in %d iterations.\n', n);
end


if success
fprintf('\n OK.\n', n);
end


end
function [J_dS_dVm,J_dS_dTheta] = generate_Derivatives(Ybus,V)

J_dS_dVm = diag(V./abs(V))*diag(conj(Ybus*V)) + diag(V)*conj(Ybus*diag(V./abs(V)));

J_dS_dTheta = 1i*diag(V)*conj(diag(Ybus*V) - Ybus*diag(V));

end
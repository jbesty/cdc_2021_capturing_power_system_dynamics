function J=generate_Jacobian(J_dS_dVm,J_dS_dTheta,pv_index,pq_index)


J_11 = real(J_dS_dTheta([pv_index; pq_index], [pv_index; pq_index]));
J_12 = real(J_dS_dVm([pv_index; pq_index], pq_index));
J_21 = imag(J_dS_dTheta(pq_index, [pv_index; pq_index]));
J_22 = imag(J_dS_dVm(pq_index, pq_index));

J = [ J_11 J_12; J_21 J_22; ];


end
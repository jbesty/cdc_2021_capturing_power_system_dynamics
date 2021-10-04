function F = calculate_F(Ybus,Sbus,V,pv_index,pq_index)


Delta_S = Sbus - V .* conj(Ybus * V);

F = [real(Delta_S([pv_index; pq_index])); imag(Delta_S(pq_index))];

end
function [V,Vm,Theta] = Update_Voltages(dx,V,pv_index,pq_index)

N1 = 1; N2 = length(pv_index); %% dx(N1:N2)-ang. on the pv buses
N3 = N2 + 1; N4 = N2+length(pq_index); %% dx(N3:N4)-ang. on the pq buses
N5 = N4 + 1; N6 = N4+length(pq_index); %% dx(N5:N6)-mag. on the pq buses



Theta = angle(V); 
Vm = abs(V); 

if ~isempty(pv_index)
Theta(pv_index) = Theta(pv_index) + dx(N1:N2);
end
if ~isempty(pq_index)
Theta(pq_index) = Theta(pq_index) + dx(N3:N4);
Vm(pq_index) = Vm(pq_index) + dx(N5:N6);
end


V = Vm .* exp(1i * Theta);


end
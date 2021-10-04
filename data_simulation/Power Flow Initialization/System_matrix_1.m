
Zfvsc1 = R+1i*L; Yfvsc1=1/Zfvsc1;





Ybus = [Yfvsc1       -Yfvsc1 ;
    -Yfvsc1          Yfvsc1];


Sbus = [Pref+1i*Qref; 0+1i*0];
V0 = 1*ones(length(Sbus),1);
V0(1) = 1;
V0(2) = 1; 
buscode = [1; 3];

pq_index = find(buscode==1);% Find indices for all PQ-busses
pv_index = find(buscode==2); % Find indices for all PV-busses
ref = find(buscode==3); % Find index for ref bus

% Create branch matrices
n_br = 1; n_bus = 2; % number of branches , number of busses
Y_from = zeros(n_br,n_bus); % Create the two branch admittance matrices
Y_to = zeros(n_br,n_bus);

br_f = [1]; % The from busses
br_t = [2]; % The to busses
br_Y = [Yfvsc1]; % The series admittance of each branch

for k = 1:length(br_f) % Fill in the matrices
Y_from(k,br_f(k)) = br_Y(k);
Y_from(k,br_t(k)) = -br_Y(k);
Y_to(k,br_f(k)) = -br_Y(k);
Y_to(k,br_t(k)) = br_Y(k);
end


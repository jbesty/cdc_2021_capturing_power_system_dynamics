omegab = 2*pi*50;
wref = omegab;

%     PLL PI controller:
Kpw = 0.1;
Kiw =0;

%     Current outer controller
Tq = 0.05;
Ta = 0.1;
Tp = 0.1;


c = 0.6;
d = 0.8;

e = 0.4;
f = 0.8;

u1 = 0.8;

Vmin = 0.3;
Vint = 0.7;

Tint = 0.7;
T1 = 0.3;

T2 = Tint/u1+0.05;

Krci = 4;

Krcv= 4;

Inom = 1;
m = 0.2;
n_s = 0.1;



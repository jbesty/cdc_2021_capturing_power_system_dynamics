
vq = 0;
omega_pll =1;
E = 1;
Mw = omega_pll;

Vref = abs(V(1));

Pvsc = real(S_inj(1));
Pref = Pvsc;
vd = Vref;
id = Pref/vd;
idref = id;
Qvsc = imag(S_inj(1));
Qref = Qvsc;
iq = -Qvsc/vd;


theta_pll = atan(imag(V(1))/real((V(1))));

iPcmd = id;
iQcmq = iq;

V_pcc = Vref;

Vmf = V_pcc;
E_x = E;
E_y = 0;

E_d = (E_x*cos(theta_pll));
E_q = (-E_x*sin(theta_pll));

Pext = Pref;
Qext = Qref;


i_x = id*cos(theta_pll) - iq*sin(theta_pll);
i_y = id*sin(theta_pll) + iq*cos(theta_pll);

P_total = E_d*id+ E_q*iq;
Q_total = E_q*id - E_d*iq;

% x0_1 = [theta_pll, Mw, id, iq, Vmf];
% z0_1 = [vd, vq, omega_pll, Pvsc, V_pcc, Qvsc, E_d, E_q, iPcmd, iQcmq, i_x, i_y, P_total, Q_total];

x0_2 = [theta_pll, Mw, id, iq, Vmf];
z0_2 = [vd, vq, omega_pll, Pvsc, V_pcc, Qvsc, E_d, E_q, i_x, i_y, P_total, Q_total];





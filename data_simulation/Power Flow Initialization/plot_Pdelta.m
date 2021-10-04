function plot_Pdelta(Es,Er,ZLN)

R=real(ZLN);
X=imag(ZLN);
ZLN_m=abs(ZLN);
phi=atan(X/R);

delta=linspace(0,pi);

Psd = (Es^2/ZLN_m)*cos(phi)-(Es*Er/ZLN_m)*cos(delta+phi);

Prd = -(Es^2/ZLN_m)*cos(phi)+(Es*Er/ZLN_m)*cos(delta-phi);

Ps = Es*Er/ZLN_m;
Pr = Ps;

Ps_delta = (Es^2/ZLN_m) + (Es*Er/ZLN_m)*cos(phi);
Pr_delta = -(Es^2/ZLN_m)*cos(phi)+(Es*Er/ZLN_m);

plot(180*delta/pi,Psd)
hold on
plot(180*delta/pi,Prd)
plot(180*(pi-phi)/pi,Ps_delta,'p')
plot(180*phi/pi,Pr_delta,'p')
plot(90,Ps,'O')
plot(90,Pr,'O')


end
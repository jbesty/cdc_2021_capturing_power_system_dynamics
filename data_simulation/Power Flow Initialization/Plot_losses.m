
c = categorical({'0.2 f_{n}','0.5 f_{n}','0.8 f_{n}', 'f_{n}' ,' f_{n}'});
PQlos = [Plosses(1) Qlosses(1);Plosses(2) Qlosses(2);Plosses(3) Qlosses(3);Plosses(4) Qlosses(4);Plosses(5) Qlosses(5)];

figure()
bar(n,PQlos)
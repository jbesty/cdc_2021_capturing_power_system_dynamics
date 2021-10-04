function DisplayResults(V,Ybus,Y_from,Y_to,br_f,br_t,buscode)

 n=length(buscode);
 
    S_to   = V(br_t).*conj(Y_to*V);
    S_from = V(br_f).*conj(Y_from*V); 
 
 
S_inj = V.*conj(Ybus*V);


 fprintf(' \n ============================================================================= \n'); 
 fprintf('                            BUS RESULTS'); 
 fprintf(' \n ============================================================================= \n');
  
 fprintf(' \n Bus              Voltage                Generation               Load         \n');
 fprintf(' \n  #          Mag(pu)  Ang(deg)         P(pu)    Q(pu)        P(pu)       Q(pu) \n')
 fprintf(' \n ----        -----------------         ---------------       ----------------- \n');
 for i=1:n
 if real(S_inj(i))>0  
 fprintf('\n  %d           %.3f     %.2f           %.2f       %.2f        -             -   \n', i , abs(V(i)), angle(V(i))*180/pi,  real(S_inj(i)) ,imag(S_inj(i)));
 end
 if real(S_inj(i))<=0
 fprintf('\n  %d           %.3f     %.2f            -          -         %.2f        %.2f   \n', i , abs(V(i)), angle(V(i))*180/pi,  abs(real(S_inj(i))) ,(imag(S_inj(i))));
 end
 end
 
 fprintf(' \n ============================================================================= \n'); 
 fprintf('                                    BRANCH FLOW'); 
 fprintf(' \n ============================================================================= \n');
 
 fprintf(' \n Branch   From    To       From Bus   Injection        To Bus        Injection \n');
 fprintf(' \n   #      Bus     Bus      P(pu)      Q(pu)            P(pu)         Q(pu)     \n')
 fprintf(' \n ------  ------  -----     --------  ----------      --------       ---------- \n');
 for i=1:n-1
 fprintf(' \n   %d      %d     %.d           %.2f          %.2f        %.2f           %.2f\n',i,br_f(i),br_t(i),real(S_from(i)),imag(S_from(i)),real(S_to(i)),imag(S_to(i)));
 end

end

 function dx = compute_state_update(t,x,u)

global  R L  Kpw Kiw Ta Tp Tq
global Pext Qext E wref
global c d Vmin % partial tripping parameters

global f e Vint % partial tripping parameters

global u1 Tint T2

global m n_s Inom % reactive power contributions and limits

global Krci Krcv f1 iq_sup

     theta_pll = x(1);  Mw = x(2); i_d = x(3); i_q = x(4);
     V_mf = x(5);  v_d = x(6);  v_q = x(7);

    omega_pll = x(8);   P_vsc = x(9); 
     V_pcc = x(10); Q_vsc = x(11);  E_d = x(12); E_q = x(13);% iPcmd = x(14) ; iQcmq = x(15);
    i_x = x(14); i_y = x(15); P_total = x(16); Q_total = x(17); %iQsupp = x(20);
     
    
    persistent f2 f3 Pflag %iq_sup
    persistent t1 t2 t3 
    if isempty(f2)
        f2 = 1; f3 = 1;
        t1 = 0; t2 = 0; t3 = 0;
%         iq_sup = 0;
    end

   if 0.9<=V_mf && V_mf<=1.1
       Pflag = 1;
   else
       Pflag = 0;
   end
   
   if V_mf <= Vint
        a1 = c/(Vint - 0.2)*(V_mf - 0.2);
        
        if f1>=a1
            f1=a1;
        end
        
        if V_mf <= 0.2
            f1 =0;
        end

   end
   
   F = f1*f2*f3;

   if V_mf <= 0.9
       
       iq_sup = -(Krci*(0.9 - V_mf) + m*Inom);
      
       
    
   elseif V_mf >=1.1 
       iq_sup = - (Krcv*(1.1 - V_mf) + n_s*Inom);
   else
       iq_sup = 0 ;
   end
    
     res1 = (omega_pll - 1)*wref;
     res2 = Kiw*v_q;

     res5 = (V_pcc - V_mf)/Ta;

      
     res6 =( - i_d*R  + omega_pll*L*i_q + v_d - E_d);
     res7 =( - i_q*R  - omega_pll*L*i_d + v_q - E_q);
        
     res8 = - omega_pll + Kpw*v_q + 1;

     res9 = -P_vsc + (v_d*i_d + v_q*i_q);

     res10 = - V_pcc + sqrt(v_d^2 + v_q^2);
     res11 = -Q_vsc + (v_q*i_d - v_d*i_q);

     res12 = -E_d + E*cos(theta_pll);
     res13 = -E_q - E*sin(theta_pll);
     
     res16 = -i_x + (i_d*cos(theta_pll) - i_q*sin(theta_pll));
     res17 = -i_y + (i_d*sin(theta_pll) + i_q*cos(theta_pll));
     
     res18 = -P_total + E*i_x;
     res19 = -Q_total - E*i_y;
     
     iq_inst = - Qext/V_mf + iq_sup;
     
     ip_inst = Pext/V_mf;

     if abs(iq_inst)>=Inom
         iq_inst = Inom;
     end
     
     if abs(ip_inst)>=Inom
         ip_inst = Inom;
     end
             
   Ipmax = Pflag*Inom + (1 - Pflag)*sqrt(Inom^2 - iq_inst^2);
   Iqmax = Pflag*sqrt(Inom^2 - ip_inst^2) + (1 - Pflag)*Inom;

    if (Pext/V_mf) > Ipmax
        res3 = (Ipmax*F-i_d)/Tp;
    elseif -(Pext/V_mf) <-Ipmax
        res3 = (-Ipmax*F -i_d)/Tp;
    else
        res3 = (Pext/V_mf*F-i_d)/Tp;
    end
    
    if (- Qext/V_mf + iq_sup) > Iqmax
        res4 = (Iqmax*F-i_q)/Tq;
    elseif (-Qext/V_mf*F + iq_sup) <-Iqmax
        res4 = (-Iqmax*F -i_q)/Tq;
    else
        res4 = ((- Qext/V_mf + iq_sup)*F-i_q)/Tq;
    end
         
    eqTotal_dam = [res1; res2; res3; res4; res5; res6; res7;res8; res9; res10; res11; res12;...
    res13; res16; res17; res18; res19];
        
    dx = eqTotal_dam;

 end
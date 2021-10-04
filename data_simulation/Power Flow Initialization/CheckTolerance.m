function success = CheckTolerance(F,n)

normF = norm(F, inf);

global max_iter 
global errortol

if normF<errortol && n<max_iter
   success=1;
else
   success=0;
end

end
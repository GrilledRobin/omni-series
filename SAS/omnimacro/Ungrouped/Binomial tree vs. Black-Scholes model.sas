proc fcmp outlib = myfunc.finance.price;
    function Eurocall(E, t, F, r, sigma, N);
        deltaT=T/N;
        u=exp(sigma*sqrt(deltaT));
        d=1/u;
        p=(exp(r*deltaT)-d)/(u-d);
        array tree[1]/ nosymbols;
        call dynamic_array(tree, n+1, n+1);
        call zeromatrix(tree);
        
        do i=0 to N;
            tree[i+1,N+1]=max(0 , E*(u**i)*(d**(N-i)) - F);
        end;
        do j=(N-1) to 0 by -1;
            do  i=0 to j by 1;
                tree[i+1,j+1] = exp(-r*deltaT)* 
                        (p * tree[i+2,j+2] + (1-p) * tree[i+1,j+2]);
            end;  
        end;
        price = tree[1,1];
        return(price);
    endsub;
run;


*****(2)Use Binomial tree model and Black-Scholes model functions *****;
options cmplib = (myfunc.finance);
data test;
    BSprice=blkshclprc(50, 5/12, 50, 0.05, 0.3);
    do n=1 to 100;
        Treeprice=eurocall(50, 5/12, 50, 0.05, 0.3, n);
        output;
    end;
run;

***********(3)Display the comparision between the two functions***************;
proc sgplot data=test;
    title 'The comparison between Black-Sholes model and Binomial tree model';
    needle x=n y=Treeprice/baseline=4;
    series x=n y=BSprice/ lineattrs=(color=red);
    yaxis label='Option price';
run;
***************END***************TEST PASSED 12DEC2010**************;
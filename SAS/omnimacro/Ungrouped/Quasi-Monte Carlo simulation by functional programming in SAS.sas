/*******************READ ME*********************************************
* - QUASI-MONTE CARLO SIMULATION BY FUNCTIONAL PROGRAMMING -
*
* VERSION:     SAS 9.2(ts2m0), windows 64bit
* DATE:        02apr2011
* AUTHOR:      hchao8@gmail.com
*
****************END OF READ ME*****************************************/

****************(1) MODULE-BUILDING STEP******************;
******(1.1) COMPILE USER-DEFINED FUNCTIONS*************;
proc fcmp outlib = sasuser.qmc.funcs;
   /***********************************************************
   *   FUNCTION:    h = halton(n, b)
   *      INPUT:    n = the nth number  |  b =  the base number
   *     OUTPUT:    h = the halton's low-discrepancy number
   ***********************************************************/
   function halton(n, b);
      n0 = n;
      h = 0;
      f = 1 / b;
       do while (n0 > 0);
         n1 = floor(n0 / b);
         r   = n0 - n1*b;
         h  = h + f*r;
         f  =  f / b;
         n0 = n1;
      end;
      return(h);
   endsub;

   /***********************************************************
   *   FUNCTION:    z = surface1(x, y)
   *      INPUT:    x, y = independent variables 
   *     OUTPUT:    z = response variable 
   ***********************************************************/
   function surface1(x, y);
      pi = constant("PI");
      z = exp((-x)*y) * (sin(6*pi*x) + cos(8*pi*y));
      return(z);
   endsub;
run;

******(1.2) BUILD A 3D PLOTTING MACRO*************;
%macro plot3d(ds = , x = , y = , z = , width = , height = , zangle = );
   /***********************************************************
   *  MACRO:      plot3d()
   *  PARAMETERS: ds = input dataset
   *              x = x-axis variable
   *              y = y-axis variable
   *              z = z-axis variable
   *              width = width of ouput graph
   *              height =  height of output graph
   *              zangle = z-axis angle of output graph
   ***********************************************************/
   ods html style = money;
   ods graphics / width = &width.px height = &height.px imagefmt = png;
   proc template;
     define statgraph surfaceplotparm;
       begingraph;
         layout overlay3d / cube = true rotate = &zangle;
           surfaceplotparm x = &x y = &y z = &z 
                        / surfacetype = fill surfacecolorgradient = &z;
         endlayout;
       endgraph;
     end;
   run;

   proc sgrender data = &ds
                 template = surfaceplotparm;
   run;
   ods graphics off;
   ods html close;
%mend;

****************END OF STEP (1)******************;

****************(2) PROGRAMMING STEP**********************;
******(2.1) IMPORT USER-DEFINED FUNCTIONS*************;
option cmplib = (sasuser.qmc);

******(2.2) DISTRIBUTIONS BETWEEN HALTON AND UNIFORM RANDOM NUMBERS*;
data test;
    do n = 1 to 100;
      do b = 2, 7;
         halton_random_number  = halton(n, b);
         uniform_random_number = ranuni(20110401);
         output;
      end;
   end;
run; 
   
proc transpose data = test out = test1;
   by n;
   var halton_random_number uniform_random_number;
   id b;
run;

******(2.3) GENERATE DATA FOR PLOTTING FUNCTION'S SURFACE****;
data surface;
   do x = 0 to 1 by 0.01;
      do y = 0 to 1 by 0.01;
         z = surface1(x, y);
         output;
      end;
   end;
run;

******(2.4) CONDUCT QUASI-MONTE CARLO SIMULATION***;
data simuds;
   do i = 1 to 50;
       do n = 1 to 100*i;
         do b = 2, 7;
            halton_random_number = halton(n, b);
            uniform_random_number = ranuni(20110401);
            output;
         end;
      end;
   end;
run; 

proc transpose data = simuds out = simuds_t;
   by i n;
   id b;
   var halton_random_number uniform_random_number;
run;

data simuds1;
   set simuds_t;
   x = surface1(_2, _7);
run;

proc sql;
   create table simuds2 as
   select i, _name_, mean(x) as area label = 'Area by simulation'
   from simuds1
   group by i, _name_
;quit;

****************END OF STEP (2)******************;

****************(3) VISUALIZATION STEP*******************************;
******(3.1) PLOT DATA BY STEP 2.2*************;
ods html style = money;
proc sgscatter data = test1;
   plot _2*_7 / grid group = _name_;
   label _2 = 'Sequences with 2 as base'
         _7 = 'Sequences with 7 as base' 
         _name_ = 'Methods';
run;
ods html close;

******(3.2) PLOT DATA BY STEP 2.3*************;
%plot3d(ds = surface, x = x , y = y, z = z, width = 800, height = 800, zangle = 60)

******(3.3) PLOT DATA BY STEP 2.4*************;
ods html style = ocean;
proc sgplot data = simuds2;
   series x = i y = area / group = _name_ ;
   refline 0.0199 / axis = y label = ('Real area');
   xaxis label = 'Random numbers --- ¡Á100'; 
   label _name_ = 'Methods';
run;
ods html close;

****************END OF STEP (3)******************;

****************END OF ALL CODING***************************************;
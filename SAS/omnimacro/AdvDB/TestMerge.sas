data a;
	a	=	1;	c	=	5;	output;
	a	=	2;	c	=	6;	output;
	a	=	3;	c	=	7;	output;
	a	=	3;	c	=	8;	output;
run;
data b;
	a	=	1;	b	=	1;	output;
	a	=	1;	b	=	2;	output;
	a	=	2;	b	=	3;	output;
	a	=	2;	b	=	4;	output;
	a	=	3;	b	=	5;	output;
	a	=	3;	b	=	6;	output;
	a	=	3;	b	=	7;	output;
run;
proc sort
	data=a
;
	by	a descending c;
run;
proc sort
	data=b
;
	by	a	descending b;
run;

data c;
	merge a b;
	by	a;
run;

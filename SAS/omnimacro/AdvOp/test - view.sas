libname	tt	"C:\www\omnimacro\Model";

data
	vtt
	/ view= vtt
;
	if 0 then set tt.Rm4csstd ;
	if	_N_	=	1	then do;
		%*100.	Declare the hash object storing the Group-objects for each byVAR.;
		%*Each element in the array "hGrpByVar" stores a group of records under the same byVAR.;
		%* the array is instantiated using the usual "combined" method.;
		dcl	hash	h1(ordered: 'a');
		dcl	hiter	hi1('h1');
		h1.DefineKey("C_SC_SCH_TYPE");
		h1.DefineData('h2', 'hi2');
		h1.DefineDone();

		%*200.	Declare the hash object storing the records for each byVAR.;
		%*Its future instances are intended to hold group of byVAR-related data from the input file.;
		%*It is declared, but not yet instantiated.;
		dcl	hash	h2();
		dcl	hiter	hi2;
	end;

	%*200.	Instantiate the hash objects of all groups of byVAR.;
	do	RID	=	1	by	1	until	( eof );
		%*100.	Read each record from base data into the hash.;
		set
			tt.Rm4csstd(
				keep=
					C_SC_SCH_TYPE
					C_PO_PW
			)
			end = eof
		;

		%*200.	For each newly encountered byVAR, instantiate its corresponding hash table.;
		%*.FIND() method searches hGrpByVar table using the current ID as a key. If it does not find an hByVar hash object with this key,;
		%* it has not been instantiated yet. Hence, it is now instantiated and stored in hGrpByVar by means of the hGrpByVar.REPLACE();
		%* method. Otherwise, an existing hash instance is copied from hGrpByVar into its 'host variable' hByVar to be reused.;
		if	h1.find()	ne	0	then do;
			h2	=	_new_	hash(ordered: 'd');
			hi2	=	_new_	hiter('h2');
			h2.DefineKey('C_PO_PW');
			h2.DefineData('C_PO_PW', 'RID');
			h2.DefineDone();
			h1.add();
		end ;

		%*300.	Store the records into current hByVar instance.;
		%*The values from the record are inserted via hByVar.REPLACE() method into the hash table whose instance hByVar currently holds.;
		h2.add();
	end ;

	first.h1	=	hi1.first();
	do while (first.h1 = 0) ;
		first.h2	=	hi2.first();
		do while (first.h2 = 0);
			set tt.Rm4csstd point = RID ;
			output ;
			first.h2 = hi2.next();
		end;
		first.h1 = hi1.next() ;
	end ;
	stop ;

run ;

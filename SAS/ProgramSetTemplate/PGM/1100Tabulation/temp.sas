options
	mlogic
	symbolgen
	sortsize	=	2000M
	sumsize		=	2000M
;

%*Below statements could not be executed with other statements.;
%*include	"&curroot.\Run000.sas";
%*include	"&curroot.\Run100.sas";
%*include	"&curroot.\Run200.sas";
%*include	"&curroot.\Run300.sas";
%*include	"&curroot.\Run400.sas";
%*include	"&curroot.\Run500.sas";
%*include	"&curroot.\Run600.sas";
%*include	"&curroot.\Run700.sas";
%*include	"&curroot.\Run800.sas";
%*include	"&curroot.\Run900.sas";

%******************Below is for the retrieval of the general data.;


%*include	"&curroot.\&L_curMon.\001_Create_MappingTable.sas";



%KillLib(
	inLIB	=	work2
)
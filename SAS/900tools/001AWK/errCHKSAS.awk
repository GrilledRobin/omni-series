BEGIN{
}
# Below for marking the SAS "WARNING" output, for print in the next row
($0 ~ /^WARNING.*$/){
	printf("[SASWARNING]	:	%s\r\n",$0);
	next;
}
# Below for retrieving the first error message
($0 ~ /^ERROR.*$/){
	printf("[SASERROR]	:	%s\r\n",$0);
	exit;
#	show_all();
}
# Below for retrieving the "Uninitialized variables" message if no error is found
($0 ~ /^.*uninitialized.*$/){
	printf("[SASSPEC]	:	%s\r\n",$0);
#	show_all();
}
END{
	exit;
}

###################### Function Area ######################
function show_all(){
	for(i=0;i<=NF;i++){
		printf("[%d] : $%d = %s.\r\n",NR,i,$i);
	};
}
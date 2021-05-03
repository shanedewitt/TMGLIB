START ;
  WRITE "Hello World 2!",!
  QUIT
  ;
LOOP ;
  NEW I
  ;
  FOR I=1:1:10 DO
  . WRITE I,!
  ;
  QUIT
  ;
SHOWDATA ;
  NEW IDX SET IDX=0
  FOR  SET IDX=$ORDER(^DIC(19,IDX)) QUIT:+IDX'>0  DO
  . NEW ZN SET ZN=$GET(^DIC(19,IDX,0))
  . WRITE ZN,!
  QUIT

HELLO(TMGDFN) ;
  QUIT TMGDFN
  
GETFNAME(TMGDFN) ;
  NEW ARR
  DO DEM^TIULO(TMGDFN,.ARR)
  NEW FNAME
  SET FNAME=$PIECE(ARR(1),",",2)
  QUIT FNAME
  
GETMARRIED() ;
  NEW NAME
  NEW MSTATUS
  NEW IEN SET IEN=0
  FOR  SET IEN=$ORDER(^DPT(IEN)) QUIT:IEN'>0  DO
  . SET NAME=$PIECE(^DPT(IEN,0),"^",1) ;"^DPT is the PATIENT file
  . SET MSTATUS=$$GET1^DIQ(2,IEN,.05) ;"file 2 is the PATIENT file
  . IF MSTATUS="" QUIT
  . WRITE $$LJ^XLFSTR(NAME,25),MSTATUS,!
  . ;WRITE NAME,$CHAR(9),MSTATUS,! ;"$char(9) is a tab, see ascii table
  QUIT

SHOWZZPROG() ;
  NEW NAME SET NAME="ZY"
  NEW DONE SET DONE=0
  FOR  SET NAME=$ORDER(^DPT("B",NAME)) QUIT:(DONE=1)!(NAME="")  DO
  . IF $EXTRACT(NAME,1,2)'="ZZ" QUIT
  . WRITE NAME,!
  . NEW IEN2 SET IEN2=0
  . FOR  SET IEN2=$ORDER(^DPT("B",NAME,IEN2)) QUIT:IEN2'>0  DO  ;"more than one patient may have same name
  . . NEW DATE SET DATE=0
  . . FOR  SET DATE=$ORDER(^TIU(8925,"ZTMGPTDT",IEN2,DATE)) QUIT:DATE'>0  DO
  . . . NEW IEN8925 SET IEN8925=0
  . . . FOR  SET IEN8925=$ORDER(^TIU(8925,"ZTMGPTDT",IEN2,DATE,IEN8925)) QUIT:IEN8925'>0  DO
  . . . . WRITE IEN2," ",DATE," ",IEN8925," - "
  . . . . WRITE $$GET1^DIQ(8925,IEN8925,.01),! ;".01 field is the DOCUMENT TYPE field
  . WRITE !
  ;
  QUIT

KILLZZPROG() ;
  ;" TO KILL A RECORD, SET THE .01 FIELD TO @
  NEW NAME SET NAME="ZY"
  NEW DONE SET DONE=0
  FOR  SET NAME=$ORDER(^DPT("B",NAME)) QUIT:(DONE=1)!(NAME="")  DO
  . IF $EXTRACT(NAME,1,2)'="ZZ" QUIT
  . NEW IEN2 SET IEN2=0
  . FOR  SET IEN2=$ORDER(^DPT("B",NAME,IEN2)) QUIT:IEN2'>0  DO  ;"more than one patient may have same name
  . . NEW DATE SET DATE=0
  . . FOR  SET DATE=$ORDER(^TIU(8925,"ZTMGPTDT",IEN2,DATE)) QUIT:DATE'>0  DO
  . . . NEW IEN8925 SET IEN8925=0
  . . . FOR  SET IEN8925=$ORDER(^TIU(8925,"ZTMGPTDT",IEN2,DATE,IEN8925)) QUIT:IEN8925'>0  DO
  . . . . WRITE "Killing: ",$$GET1^DIQ(8925,IEN8925,.01)," (",NAME,")",!
  . . . . DO PROGKILLER(IEN8925)
  ;
  QUIT

PROGKILLER(IEN) ;"Kill one record
  IF IEN=418123 QUIT ;"There is a problem deleting documents without an associated visit record
  ;
  NEW TMGFDA SET TMGFDA(8925,IEN_",",.01)="@" ;"Needs IENS, so we add a comma to IEN
  NEW TMGMSG
  DO FILE^DIE("E","TMGFDA","TMGMSG")
  IF $DATA(TMGMSG) ZWRITE TMGMSG
  QUIT


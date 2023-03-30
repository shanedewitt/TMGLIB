TMGTIUT3 ;TMG/kst-TIU-related code ; 5/20/15, 4/11/17, 3/15/23
   ;;1.0;TMG-LIB;**1**;5/20/15
  ;
  ;"Various TIU / text related code modules
  ;"Especially with TOPICS in TIU notes
  ;
  ;"~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--
  ;"Copyright (c) 6/23/2015  Kevin S. Toppenberg MD
  ;"
  ;"This file is part of the TMG LIBRARY, and may only be used in accordence
  ;" to license terms outlined in separate file TMGLICNS.m, which should 
  ;" always be distributed with this file.
  ;"~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--
  ;
  ;"=======================================================================
  ;" RPC -- Public Functions.
  ;"=======================================================================
  ;"TOPICS(OUT,CMD,ADFN,SECTION,TOPICLST,SDT,EDT)-- High level entry point for functions below
  ;"TOPRBLNK(OUT,IN)  --TOPIC-PROBLEM LINK entry point
  ;"TOPICLST(OUT,ADFN,STARTING,DIR,MAX) -- List all topics in file 22719.51 (a subfile), or subset thereof.
  ;"LKSUGEST(OUT,TOPIC)  -- Suggest info for problems to create for given topic
  ;"DXLIST(OUT,ADFN,CMD,SDT) -- Get list of possible diagnoses for user to pick from, during patient encounter
  ;"SUMNOTE(IEN8925,ARRAY) -- Get back summary data from prior parsing and storage. 
  ;"THREADS(OUT,ADFN,IEN8925,ARRAY) -- Get THREADS info for note
  ;"UNUSEDTOPICS(OUT,ARRAY,THREADINFO) -- Get list of topics that do NOT have corresponding thread text  
  ;"PROBLST(OUT,ADFN,SDT)  -- Get listing of patient's defined problem list
  ;"ICDLIST(OUT,ADFN,SDT) -- Get listing of ICD's used for patient in past  
  ;"=======================================================================
  ;"PRIVATE API FUNCTIONS
  ;"=======================================================================
  ;"TESTLST ;
  ;"GETFTOP(OUT,ADFN,SECTION,SDT,EDT)  ;"GET FORMATTED TOPICS LIST for a patient
  ;"GETTOPL(OUT,ADFN,SECTION,SDT,EDT,FILTER)  ;"GET TOPICS LIST for a patient
  ;"GETFULL(OUT,ADFN,SECTION,TOPIC,SDT,EDT) ;"Get cumulative, full text for problem
  ;"HNDLSET(LINE) -- Handle SET command from TOPRBLNK
  ;"HNDLGET(LINE) -- Handle GET command from TOPRBLNK
  ;"HNDLKILL(LINE)-- Handle KILL command from TOPRBLNK
  ;
  ;"=======================================================================
  ;"DEPENDENCIES: 
  ;"=======================================================================
  ;
TESTLST ;
  NEW DIC,X,Y SET DIC=2,DIC(0)="MAEQ"
  DO ^DIC WRITE !
  IF +Y'>0 QUIT
  NEW OUT DO GETFTOP(.OUT,+Y,"HPI")
  IF $DATA(OUT) DO ZWRITE^TMGZWR("OUT")
  QUIT
  ;
TOPICS(OUT,CMD,ADFN,SECTION,TOPICLST,SDT,EDT,OPTION) ;"High level entry point for functions below
  ;"INPUT: OUT -- AN OUT PARAMETER.  PASS BY REFERENCE.  Format depends on CMD
  ;"        If CMD="LIST", then 
  ;"          OUT(0)="1^OK" or "-1^Error message"
  ;"          OUT(#)=<TOPIC NAME>^<IEN8925>^<FM DT>
  ;"        If CMD="SUM1", then 
  ;"          OUT(0)="1^OK" or "-1^Error message"
  ;"          OUT(#)=FMDT^line#^line of text
  ;"       CMD -- The mode of the function.  Should be: 'LIST', or 'SUM1'
  ;"       ADFN -- PATIENT IEN NUMBER 
  ;"       SECTION -- 'HPI', or 'A&P'  OPTIONAL.  Default is 'HPI'
  ;"       TOPICLST -- +/-OPTIONAL. if CMD="SUM1", then this should be name of desired topic for summary.
  ;"            To provide multiple topic names, separate by "," character.  E.g. 
  ;"             "HTN,HYPERTENSION.,HYPERTENSION"
  ;"       SDT -- FM date for starting date range.  OPTIONAL.  Default = 0;
  ;"       EDT -- FM date for ENDING date range.  OPTIONAL.  Default = 9999999;
  ;"       OPTION -- OPTIONAL.  Used when CMD="SUM1"
  ;"         OPTION("LAST")=5  <-- example.  Means return the 5 most recent matches
  ;"         OPTION("FIRST")=3 <-- example.  Means return the 3 first/oldest matches
  ;"         If not provided, then ALL matches are returned.  
  ;"Result: none
  NEW ZZDEBUG SET ZZDEBUG=0
  IF ZZDEBUG=1 DO
  . SET CMD=$GET(^TMP("TMG","TOPICS","CMD"))
  . SET ADFN=$GET(^TMP("TMG","TOPICS","ADFN"))               
  . SET SECTION=$GET(^TMP("TMG","TOPICS","SECTION"))
  . SET TOPICLST=$GET(^TMP("TMG","TOPICS","TOPICLST"))
  . SET SDT=$GET(^TMP("TMG","TOPICS","SDT"))
  . SET EDT=$GET(^TMP("TMG","TOPICS","EDT"))
  ELSE  DO
  . KILL ^TMP("TMG","TOPICS")
  . SET ^TMP("TMG","TOPICS","CMD")=CMD
  . SET ^TMP("TMG","TOPICS","ADFN")=ADFN
  . SET ^TMP("TMG","TOPICS","SECTION")=SECTION
  . SET ^TMP("TMG","TOPICS","TOPICLST")=$GET(TOPICLST)
  . SET ^TMP("TMG","TOPICS","SDT")=$GET(SDT)
  . SET ^TMP("TMG","TOPICS","EDT")=$GET(EDT)
  SET SECTION=$GET(SECTION,"HPI")
  SET CMD=$GET(CMD)
  SET SDT=$GET(SDT) IF (SDT="")!(SDT="-1") SET SDT=0
  SET EDT=$GET(EDT) IF EDT="" SET EDT=9999999
  IF CMD="LIST" DO
  . DO GETFTOP(.OUT,.ADFN,.SECTION,SDT,EDT)  ;"GET FORMATTED TOPICS LIST for a patient  
  ELSE  IF CMD="SUM1" DO
  . DO GETFULL(.OUT,.ADFN,.SECTION,.TOPICLST,SDT,EDT,.OPTION) ;"Get cumulative, full text for problem
  ELSE  DO
  . SET OUT(0)="-1^Invalid CMD (command) parameter provided."
  QUIT
  ;
GETFTOP(OUT,ADFN,SECTION,SDT,EDT)  ;"GET FORMATTED TOPICS LIST for a patient
  ;"INPUT: OUT -- AN OUT PARAMETER.  PASS BY REFERENCE.  Format:
  ;"        OUT(0)="1^OK" or "-1^Error message"
  ;"        OUT(#)=<TOPIC NAME>^<IEN8925>^<FM DT>
  ;"       ADFN -- PATIENT IEN NUMBER
  ;"       SECTION -- 'HPI', or 'A&P'
  ;"       SDT -- FM date for starting date range.  OPTIONAL.  Default = 0;
  ;"       EDT -- FM date for ENDING date range.  OPTIONAL.  Default = 9999999;
  ;"Result: none
  NEW TEMP 
  SET SDT=$GET(SDT) IF SDT="" SET SDT=0
  SET EDT=$GET(EDT) IF EDT="" SET EDT=9999999
  SET TEMP(0)=$$GETTOPL(.OUT,.ADFN,.SECTION,SDT,EDT)
  KILL OUT(ADFN,"C")
  NEW TOPIC SET TOPIC=""
  ;"FOR  SET TOPIC=$ORDER(OUT(ADFN,"B",TOPIC)) QUIT:TOPIC=""  DO
  ;". NEW IEN8925 SET IEN8925=$ORDER(OUT(ADFN,"B",TOPIC,SECTION,""),-1)
  ;". FOR  SET IEN8925=$ORDER(OUT(ADFN,"B",TOPIC,SECTION,IEN8925),-1) QUIT:+IEN8925'>0  DO
  ;". . KILL OUT(ADFN,"B",TOPIC,SECTION,IEN8925)
  NEW IDX SET IDX=1  
  SET TOPIC=""
  FOR  SET TOPIC=$ORDER(OUT(ADFN,"B",TOPIC)) QUIT:TOPIC=""  DO
  . NEW IEN8925 SET IEN8925=0
  . FOR  SET IEN8925=$ORDER(OUT(ADFN,"B",TOPIC,SECTION,IEN8925)) QUIT:+IEN8925'>0  DO
  . . NEW DT SET DT=$GET(OUT(ADFN,"B",TOPIC,SECTION,IEN8925))
  . . SET TEMP(IDX)=TOPIC_"^"_IEN8925_"^"_DT SET IDX=IDX+1
  KILL OUT MERGE OUT=TEMP
GFTLDN ;  
  QUIT  
  ;
GETTOPL(OUT,ADFN,SECTION,SDT,EDT,FILTER)  ;"GET TOPICS LIST for a patient
  ;"INPUT: OUT -- AN OUT PARAMETER.  PASS BY REFERENCE.  Format:
  ;"         OUT(ADFN,"B",<TOPIC NAME>,SECTION,IEN8925)=<FM DATE OF NOTE>
  ;"         OUT(ADFN,"C",<FM DATE OF NOTE>,<TOPIC NAME>,SECTION,IEN8925)=""
  ;"       ADFN -- PATIENT IEN NUMBER
  ;"       SECTION -- 'HPI', or 'A&P'
  ;"       SDT -- FM date for starting date range.  OPTIONAL.  Default = 0;
  ;"       EDT -- FM date for ENDING date range.  OPTIONAL.  Default = 9999999;
  ;"       FILTER -- OPTIONAL.  Pass by reference.  List of TOPICS that are allowed
  ;"           Format:  FILTER(<Allowed Topic Name>)=""
  ;"           If some data is passed in FILTER, then ONLY those names given are 
  ;"               included in output.  Otherwise all entries are output. 
  ;"Result: "1^OK", or "-1^Error message"
  NEW RESULT SET RESULT="1^OK"
  SET ADFN=+$GET(ADFN) IF ADFN'>0 DO  GOTO GTLDN
  . SET RESULT="-1^Patient record number (DFN) not provided."
  SET SECTION=$GET(SECTION)
  IF (SECTION'="HPI")&(SECTION'="A&P") DO  GOTO GFTLDN
  . SET RESULT="-1^Section name of 'HPI' or 'A&P' not provided."
  SET SDT=$GET(SDT) IF SDT="" SET SDT=0
  SET EDT=$GET(EDT) IF EDT="" SET EDT=9999999
  NEW NODE SET NODE=$SELECT(SECTION="HPI":2,SECTION="A&P":3,1:0) IF NODE'>0 GOTO GTLDN
  NEW IEN SET IEN=0
  FOR  SET IEN=$ORDER(^TMG(22719,"DFN",ADFN,IEN)) QUIT:+IEN'>0  DO
  . NEW IEN8925 SET IEN8925=+$PIECE($GET(^TMG(22719,IEN,0)),"^",1)
  . NEW NOTEDT SET NOTEDT=$PIECE($GET(^TIU(8925,IEN8925,0)),"^",7)
  . IF (NOTEDT<SDT)!(NOTEDT>EDT) QUIT
  . NEW SUBIEN SET SUBIEN=0 
  . FOR  SET SUBIEN=$ORDER(^TMG(22719,IEN,NODE,SUBIEN)) QUIT:+SUBIEN'>0  DO
  . . NEW TOPIC SET TOPIC=$PIECE($GET(^TMG(22719,IEN,NODE,SUBIEN,0)),"^",1) 
  . . IF TOPIC="" QUIT
  . . IF $DATA(FILTER),'$DATA(FILTER(TOPIC)) QUIT
  . . SET OUT(ADFN,"B",TOPIC,SECTION,IEN8925)=NOTEDT  
  . . SET OUT(ADFN,"C",NOTEDT,TOPIC,SECTION,IEN8925)=""
GTLDN ;
  QUIT RESULT
  ;
GETFULL(OUT,ADFN,SECTION,TOPIC,SDT,EDT,OPTION) ;"Get cumulative, full text for problem
  ;"Input:  OUT -- AN OUT PARAMETER.  PASS BY REFERENCE.  Format:
  ;"         OUT(0)="1^OK" or "-1^Error message"
  ;"         OUT(#)=FMDT^line#^line of text
  ;"       ADFN -- patient IEN
  ;"       SECTION -- 'HPI', or 'A&P'
  ;"       TOPIC -- the topic, or paragraph title name.  Should exactly match
  ;"              that returned in output from GETTOPL() or GETFTOP()
  ;"              May contain multiple names, separated by commas, e.g.:
  ;"                 "HTN,HYPERTENSION.,HYPERTENSION"
  ;"       SDT -- FM date for starting date range.  OPTIONAL.  Default = 0;
  ;"       EDT -- FM date for ENDING date range.  OPTIONAL.  Default = 9999999;
  ;"       OPTION -- OPTIONAL.  
  ;"           OPTION("LAST")=5  <-- example.  Means return the 5 most recent matches
  ;"           OPTION("FIRST")=3 <-- example.  Means return the 3 first/oldest matches
  ;"           If not provided, then ALL matches are returned.  
  ;"Result: none.
  ;
  ;"NOTE: I once had RPC take 50 seconds(!) to return.  I think this was choke point
  ;"      Later I will see if I can rewrite with data from file 22719.2  //kt 3/5/23
  ;
  SET OUT(0)="1^OK"
  SET TOPIC=$GET(TOPIC)                   
  IF TOPIC="" DO  GOTO GFDN
  . SET OUT(0)="-1^Topic name not provided"
  SET SDT=$GET(SDT) IF SDT="" SET SDT=0
  SET EDT=$GET(EDT) IF EDT="" SET EDT=9999999
  NEW DATA,IDX,TOPICARR
  FOR IDX=1:1:$LENGTH(TOPIC,",") DO
  . NEW ATOPIC SET ATOPIC=$PIECE(TOPIC,",",IDX) QUIT:ATOPIC=""
  . SET TOPICARR($$TRIM^XLFSTR(ATOPIC))=""  
  SET IDX=1
  SET OUT(0)=$$GETTOPL(.DATA,.ADFN,.SECTION,SDT,EDT,.TOPICARR)  ;"GET FORMATTED TOPICS LIST for a patient
  IF +OUT(0)'=1 GOTO GFDN
  NEW DIR SET DIR=1
  NEW LIMITCT SET LIMITCT=9999
  IF $DATA(OPTION("LAST")) SET DIR=-1,LIMITCT=+$GET(OPTION("LAST"))
  ELSE  IF +$GET(OPTION("FIRST")) SET LIMITCT=+$GET(OPTION("FIRST"))
  IF LIMITCT'>0 SET LIMITCT=1  
  NEW ATOPIC SET ATOPIC=""
  FOR  SET ATOPIC=$ORDER(TOPICARR(ATOPIC)) QUIT:ATOPIC=""  DO
  . NEW DATA2 MERGE DATA2=DATA(ADFN,"B",ATOPIC,SECTION)  ;"-->DATA2(IEN8925)=FMDT
  . NEW IEN8925 SET IEN8925=""
  . FOR  SET IEN8925=$ORDER(DATA2(IEN8925),-1) QUIT:(+IEN8925'>0)!(LIMITCT<1)  DO
  . . SET LIMITCT=LIMITCT-1
  . . NEW FMDT SET FMDT=$GET(DATA2(IEN8925))
  . . NEW PARSEDNOTE
  . . DO SUMNOTE^TMGTIUP1(.IEN8925,.PARSEDNOTE) 
  . . NEW LINENUM SET LINENUM=""
  . . FOR  SET LINENUM=$ORDER(PARSEDNOTE(IEN8925,"FULL",SECTION,ATOPIC,LINENUM)) QUIT:+LINENUM'>0  DO
  . . . NEW STR SET STR=$GET(PARSEDNOTE(IEN8925,"FULL",SECTION,ATOPIC,LINENUM))
  . . . SET OUT(IDX)=FMDT_"^"_LINENUM_"^"_STR,IDX=IDX+1
GFDN ;  
  QUIT
  ;
  ;"==========================================================
  ;
TOPRBLNK(OUT,IN)  ;"TOPIC-PROBLEM LINK entry point
  ;"RPC ENTRY POINT FOR: TMG CPRS TOPIC LINKS    ... was TMG CPRS TOPIC PROBLEM LINK
  ;"Input: OUT -- PASS BY REFERENCE, AN OUT PARAMETER.  Format as per Output below
  ;"       IN --  PASS BY REFERENCE, Format:
  ;"          NOTE: one or many lines can be passed.  Each is a separate command,
  ;"              and are executed in the number order #
  ;"          IN(#)='<CMD>^<Info>...'
  ;"            <CMD> can be:
  ;"               'SET', in which case <Info> should be as follows:
  ;"                   'SET^<DFN>^<TopicName>^<ProblemIEN>^<ICD_INFO*>^<SCTIEN>'  <-- can have any combo of IENS's    
  ;"                   'SET^1234^A-fib^5678'
  ;"                   NOTE: ProblemIEN is IEN in 9000011, SCT is snowmed code in ____ (to do!)
  ;"                   NOTE: *For ICD_INFO: Should be:
  ;"                        '<ICD_IEN>;<ICD_CODE>;<ICD_CODING_SYS>;<AS-OF FMDT>' 
  ;"                        ICD_IEN is IEN in 80.   If valid IEN provided, then rest is optional and ignored
  ;"                        ICD_CODE e.g. I10 for Essential HTN
  ;"                        ICD_CODING_SYS.  e.g. 10D for ICD 10
  ;"                        AS-OF FMDT: FMDT for date lookup.  Default is NOW 
  ;"               'GET', in which case <Info> should be as follows:
  ;"                   'GET^<DFN>^PROB=<ProblemIEN>'
  ;"                or 'GET^<DFN>^TOPIC=<TopicName>'
  ;"                or 'GET^<DFN>^ICD=<ICDIEN>'
  ;"                or 'GET^<DFN>^SCT=<SCTIEN>'  <-- to do! 
  ;"                or 'GET^<DFN>^ALL'
  ;"               'KILL', in which case <Info> should be as follows:
  ;"                   'KILL^<DFN>^<TopicName>'
  ;"Results: none
  ;"Output: Out(0)=1^OK   <-- only if all filings were OK, otherwise -1^Problem
  ;"        Out(#)=1^OK  or -1^ErrorMessage  <-- if line command was a SET or KILL command
  ;"        Out(#)=<result value>   <-- if line command was a GET command.
  ;"         e.g.   1^OK^DFN^PROB=<ProblemIEN>^TOPIC=<Name>,<Name>,<Name>,....   <-- if input was PROB=<IEN>
  ;"          or    1^OK^DFN^ICD=<ICDIEN>^^TOPIC=<Name>,<Name>,<Name>,....       <-- if input was ICD=<IEN>
  ;"          or    1^OK^DFN^TOPIC=<TopicName>^PROB=<IEN>                        <-- if input was TOPIC=<Name>
  ;"          or    1^OK^DFN^TOPIC=<TopicName>^PROB=<IEN>^ICD=<ICDIEN>^SCT=<SCTIEN> <-- if input was ALL  (SCT IS STILL TO DO...)
  ;"          or   -1^Error Message
  ;"        The # will match the # from the IN array
  NEW TMGZZDB SET TMGZZDB=0
  IF TMGZZDB=0 DO
  . KILL ^TMG("TMP","RPC","TOPRBLNK^TMGTIUT3")
  . MERGE ^TMG("TMP","RPC","TOPRBLNK^TMGTIUT3","IN")=IN
  ELSE  DO
  . KILL IN
  . MERGE IN=^TMG("TMP","RPC","TOPRBLNK^TMGTIUT3","IN")
  KILL OUT NEW RESULT SET RESULT="1^OK"  ;"default to success 
  NEW IDX SET IDX=""
  FOR  SET IDX=$ORDER(IN(IDX)) QUIT:+IDX'>0  DO
  . NEW LINE SET LINE=$GET(IN(IDX))
  . NEW CMD SET CMD=$PIECE(LINE,"^",1)
  . NEW ONERESULT SET ONERESULT="1^OK"
  . IF CMD="SET" DO
  . . SET ONERESULT=$$HNDLSET(LINE)
  . ELSE  IF CMD="GET" DO
  . . SET ONERESULT=$$HNDLGET(LINE)
  . ELSE  IF CMD="KILL" DO
  . . SET ONERESULT=$$HNDLKILL(LINE)
  . ELSE  DO
  . . SET ONERESULT="-1^Invalid command ["_CMD_"] received."
  . SET OUT(IDX)=ONERESULT
  . IF +ONERESULT'=1 SET RESULT="-1^Problem"
  SET OUT(0)=RESULT
  QUIT
  ;
HNDLSET(LINE)  ;"Handle SET command
  ;"Input: LINE -- 'SET^<DFN>^<TopicName>^<ProblemIEN>^<ICD_INFO*>^<SCTIEN>'  <-- can have any combo of IENS's / info    
  ;"               'SET^1234^A-fib^5678'
  ;"               NOTE: ProblemIEN is IEN in 9000011, SCT is snowmed code in ____ (to do!)
  ;"               NOTE: *For ICD_INFO: Should be:
  ;"                    '<ICD_IEN>;<ICD_CODE>;<ICD_CODING_SYS>;<AS-OF FMDT>' 
  ;"                    ICD_IEN is IEN in 80.   If valid IEN provided, then rest is optional and ignored
  ;"                    ICD_CODE e.g. I10 for Essential HTN
  ;"                    ICD_CODING_SYS.  e.g. 10D for ICD 10
  ;"                    AS-OF FMDT: FMDT for date lookup.  Default is NOW 
  ;"Result: '1^OK' or '-1^Error message'
  NEW RESULT SET RESULT="1^OK"
  NEW TMGFDA,TMGIEN,TMGMSG
  SET LINE=$GET(LINE)
  NEW ADFN SET ADFN=+$PIECE(LINE,"^",2) IF ADFN'>0 DO  GOTO HNDSDN
  . SET RESULT="-1^Numeric DFN not provided in piece #2 of '"_LINE_"'"
  IF '$DATA(^DPT(ADFN)) DO  GOTO HNDSDN
  . SET RESULT="-1^DFN provided in piece #2 doesn't exist in PATIENT file (#2).  Input: '"_LINE_"'"
  NEW TOPIEN SET TOPIEN=+$ORDER(^TMG(22719.5,"B",ADFN,0))
  IF TOPIEN>0 GOTO HNDS2
  SET TMGFDA(22719.5,"+1,",.01)=ADFN
  SET TMGIEN(1)=ADFN   ;"<--- RECORD NUMBER SHOULD MATCH PATIENT IEN (DFN)
  DO UPDATE^DIE("","TMGFDA","TMGIEN","TMGMSG")
  IF $DATA(TMGMSG) DO  GOTO HNDSDN
  . SET RESULT="-1^"_$$GETERRST^TMGDEBU2(.TMGMSG)
  SET TOPIEN=$GET(TMGIEN(1))
  IF TOPIEN'>0 DO  GOTO HNDSDN
  . SET RESULT="-1^Unable to determine IEN of added record in file 22719.5"  
HNDS2 ;"Add subrecord or modify existing subrecord. 
  NEW TOPIC SET TOPIC=$PIECE(LINE,"^",3)
  IF TOPIC="" DO  GOTO HNDSDN
  . SET RESULT="-1^Topic name not provide in piece #3.  Input: '"_LINE_"'"
  NEW PROBIEN SET PROBIEN=$PIECE(LINE,"^",4)
  NEW ICDINFO SET ICDINFO=$PIECE(LINE,"^",5)
  NEW ICDIEN SET ICDIEN=0
  IF ICDINFO'="" DO  GOTO:(+RESULT=-1) HNDSDN
  . SET ICDIEN=+$PIECE(ICDINFO,";",1)
  . IF (+ICDIEN>0),$DATA(^ICD9(ICDIEN))'>0 DO  QUIT
  . . SET RESULT="-1^ICD IEN provided in piece #5 doesn't exist in ICD DIAGNOSIS file (#80).  Input: '"_LINE_"'"
  . NEW ICDCODE SET ICDCODE=$PIECE(ICDINFO,";",2) 
  . IF ICDCODE="@" SET ICDIEN="@" QUIT
  . NEW CSYS SET CSYS=$PIECE(ICDINFO,";",3)
  . NEW CDT SET CDT=$PIECE(ICDINFO,";",4)
  . SET ICDIEN=+$$ICDDATA^ICDXCODE(CSYS,ICDCODE,CDT,"E")
  . IF ICDIEN'>0 DO  QUIT
  . . SET RESULT="-1^Invalid ICD info provided in piece#4: ["_ICDINFO_"]"
  NEW SCTIEN SET SCTIEN=+$PIECE(LINE,"^",6)  ;"<-- needs to be added to fileman file still!!
  IF (+PROBIEN'>0)&((ICDIEN'>0)&(ICDIEN'="@"))&(SCTIEN'>0) DO  GOTO HNDSDN
  . SET RESULT="-1^Numeric PROBLEM or ICD or Snowmed IEN not provided in piece #4 or #5 or #6 of '"_LINE_"'"
  IF (+PROBIEN>0),'$DATA(^AUPNPROB(PROBIEN)) DO  GOTO HNDSDN
  . SET RESULT="-1^PROBLEM IEN provided in piece #4 doesn't exist in PROBLEM file (#9000011).  Input: '"_LINE_"'"
  ;"IF (+SCTIEN>0),'$DATA(^?????(SCTIEN)) DO  GOTO HNDSDN
  ;". SET RESULT="-1^SNOWMED IEN provided in piece #6 doesn't exist in ?????????????.  Input: '"_LINE_"'"
  IF +PROBIEN>0 DO  GOTO:+RESULT<0 HNDSDN  
  . NEW P2DFN SET P2DFN=+$PIECE($GET(^AUPNPROB(+PROBIEN,0)),"^",2)
  . IF P2DFN'=ADFN DO  
  . . SET RESULT="-1^PROBLEM IEN points to a record for a PATIENT `"_P2DFN_", which is different from that provided in piece #2.  Input: '"_LINE_"'"  
  NEW SUBIEN SET SUBIEN=+$ORDER(^TMG(22719.5,TOPIEN,1,"B",$EXTRACT(TOPIC,1,30),0))
  IF SUBIEN>0 GOTO HNDS3  ;"sub record already exists.
  ;"Add new subrecord
  KILL TMGFDA,TMGIEN,TMGMSG
  NEW IENS SET IENS="+1,"_TOPIEN_","
  SET TMGFDA(22719.51,IENS,.01)=TOPIC
  IF PROBIEN>0 SET TMGFDA(22719.51,IENS,.02)=+PROBIEN 
  IF ICDIEN>0 SET TMGFDA(22719.51,IENS,.03)=+ICDIEN
  ;"IF SCTIEN>0 SET TMGFDA(22719.51,IENS,.04)=+SCTIEN   <-- TO DO!!
  DO UPDATE^DIE("","TMGFDA","TMGIEN","TMGMSG")
  IF $DATA(TMGMSG) DO  GOTO HNDSDN
  . SET RESULT="-1^"_$$GETERRST^TMGDEBU2(.TMGMSG)
  GOTO HNDSDN
HNDS3 ;"Overwrite .02 and/or .03 field of existing record.  
  NEW IENS SET IENS=SUBIEN_","_TOPIEN_","
  IF PROBIEN>0 SET TMGFDA(22719.51,IENS,.02)="`"_+PROBIEN 
  ELSE  IF PROBIEN="@" SET TMGFDA(22719.51,IENS,.02)=PROBIEN 
  IF ICDIEN>0 SET TMGFDA(22719.51,IENS,.03)="`"_+ICDIEN
  ELSE  IF ICDIEN="@" SET TMGFDA(22719.51,IENS,.03)=ICDIEN
  ;"IF SCTIEN>0 SET TMGFDA(22719.51,IENS,.04)="`"_+SCTIEN
  ;"ELSE  IF ICDIEN="@" SET TMGFDA(22719.51,IENS,.04)=SCTIEN
  DO FILE^DIE("E","TMGFDA","TMGMSG")
  IF $DATA(TMGMSG) DO  GOTO HNDSDN
  . SET RESULT="-1^"_$$GETERRST^TMGDEBU2(.TMGMSG)
  GOTO HNDSDN
HNDSDN ;  
  QUIT RESULT
  ;
HNDLGET(LINE)  ;"Handle GET command.
  ;"Input: LINE.  Format
  ;"          'GET^<DFN>^PROB=<ProblemIEN>'
  ;"       or 'GET^<DFN>^ICD=<ICDIEN>'
  ;"       or 'GET^<DFN>^SCT=<SCTIEN>'
  ;"       or 'GET^<DFN>^TOPIC=<TopicName>'
  ;"Result: 1^OK^DFN^PROB=<ProblemIEN>^TOPIC=<Name>,<Name>,<Name>,....   <-- if input was PROB=<IEN>
  ;"  or    1^OK^DFN^ICD=<ICDIEN>^^TOPIC=<Name>,<Name>,<Name>,....       <-- if input was ICD=<IEN>
  ;"  or    1^OK^DFN^SCT=<SCTIEN>^^TOPIC=<Name>,<Name>,<Name>,....       <-- if input was SCT=<IEN>
  ;"  or    1^OK^DFN^TOPIC=<TopicName>^PROB=<IEN>^ICD=<IEN>              <-- if input was TOPIC=<Name> OR ALL
  ;"  or   -1^Error Message
  NEW RESULT SET RESULT="1^OK"
  NEW TMGFDA,TMGIEN,TMGMSG
  SET LINE=$GET(LINE)
  NEW ADFN SET ADFN=+$PIECE(LINE,"^",2) IF ADFN'>0 DO  GOTO HNDGDN
  . SET RESULT="-1^Numeric DFN not provided in piece #2 of '"_LINE_"'"
  IF '$DATA(^DPT(ADFN)) DO  GOTO HNDGDN
  . SET RESULT="-1^DFN provided in piece #2 doesn't exist in PATIENT file (#2).  Input: '"_LINE_"'"
  SET RESULT=RESULT_"^"_ADFN
  NEW TOPIEN SET TOPIEN=+$ORDER(^TMG(22719.5,"B",ADFN,0))  
  IF TOPIEN'>0 DO  GOTO HNDGDN
  . SET RESULT="-1^Record in file 22719.5 doesn't exist for DFN of "_ADFN_".  Input: '"_LINE_"'"
  NEW MODE SET MODE=$PIECE(LINE,"^",3)
  SET RESULT=RESULT_"^"_MODE
  NEW VALUE SET VALUE=$PIECE(MODE,"=",2)
  NEW MODECMD SET MODECMD=$PIECE(MODE,"=",1)
  NEW SUBIEN SET SUBIEN=0
  IF ((MODECMD="PROB")!(MODECMD="ICD")!(MODECMD="SCT"))&(+VALUE>0) DO
  . NEW XREF SET XREF=$SELECT(MODE="ICD":"DX",1=1:"AC")  ;"<--- TO DO!!  ADD XREF FOR SCT
  . SET RESULT=RESULT_"^TOPIC="
  . FOR  SET SUBIEN=$ORDER(^TMG(22719.5,TOPIEN,1,XREF,+VALUE,SUBIEN)) QUIT:+SUBIEN'>0  DO
  . . NEW ATOPIC SET ATOPIC=$PIECE($GET(^TMG(22719.5,TOPIEN,1,SUBIEN,0)),"^",1)
  . . IF $EXTRACT(RESULT,$LENGTH(RESULT))'="=" SET RESULT=RESULT_","
  . . SET RESULT=RESULT_ATOPIC
  ELSE  IF ((MODECMD="TOPIC")!(MODECMD="ALL"))&(VALUE'="") DO
  . SET SUBIEN=$ORDER(^TMG(22719.5,TOPIEN,1,"B",$EXTRACT(VALUE,1,30),0))
  . IF SUBIEN'>0 DO  QUIT
  . . SET RESULT="-1^Topic '"_VALUE_"' not found in record #"_TOPIEN_".    Input: '"_LINE_"'"
  . NEW ZN SET ZN=$GET(^TMG(22719.5,TOPIEN,1,SUBIEN,0))
  . SET RESULT=RESULT_"^PROB="_$PIECE(ZN,"^",2)
  . SET RESULT=RESULT_"^ICD="_$PIECE(ZN,"^",3)
  . ;"SET RESULT=RESULT_"^SCT="_$PIECE(ZN,"^",4)  <-- TO DO!!
  ;"ELSE  IF (MODECMD="ALL") DO
  ;". SET RESULT=RESULT_"^ALL:"
  ;". FOR  SET SUBIEN=$ORDER(^TMG(22719.5,TOPIEN,1,SUBIEN)) QUIT:+SUBIEN'>0  DO
  ;". . NEW ZN SET ZN=$GET(^TMG(22719.5,TOPIEN,1,SUBIEN,0))
  ;". . IF $EXTRACT(RESULT,$LENGTH(RESULT))'=":" SET RESULT=RESULT_","
  ;". . SET RESULT=RESULT_$PIECE(ZN,"^",1)_"="_$PIECE(ZN,"^",2)
  ELSE  DO
  . SET RESULT="-1^Invalid mode in piece #3.  Expected 'PROB=<IEN>' or 'ICD=<IEN>' or 'TOPIC=<Name>' or 'ALL'.  Input: '"_LINE_"'"
HNDGDN  
  QUIT RESULT
  ;
HNDLKILL(LINE)  ;"Handle KILL command.
  ;"Input: LINE.  Format
  ;"         'KILL^<DFN>^<TopicName>'
  ;"Result: 1^OK  or -1^Error Message
  NEW RESULT SET RESULT="1^OK"
  SET LINE=$GET(LINE)
  NEW ADFN SET ADFN=+$PIECE(LINE,"^",2) IF ADFN'>0 DO  GOTO HNDKDN
  . SET RESULT="-1^Numeric DFN not provided in piece #2 of '"_LINE_"'"
  IF '$DATA(^DPT(ADFN)) DO  GOTO HNDKDN
  . SET RESULT="-1^DFN provided in piece #2 doesn't exist in PATIENT file (#2).  Input: '"_LINE_"'"
  NEW TOPIEN SET TOPIEN=+$ORDER(^TMG(22719.5,"B",ADFN,0))  
  IF TOPIEN'>0 DO  GOTO HNDKDN
  . SET RESULT="-1^Record in file 22719.5 doesn't exist for DFN of "_ADFN_".  Input: '"_LINE_"'"
  NEW TOPIC SET TOPIC=$PIECE(LINE,"^",3)
  IF TOPIC["TOPIC=" SET TOPIC=$PIECE(TOPIC,"TOPIC=",2)
  IF TOPIC="" DO  GOTO HNDKDN
  . SET RESULT="-1^Topic name not provide in piece #3.  Input: '"_LINE_"'"
  NEW SUBIEN SET SUBIEN=$ORDER(^TMG(22719.5,TOPIEN,1,"B",$EXTRACT(TOPIC,1,30),0))
  IF SUBIEN'>0 GOTO HNDKDN  ;"Don't raise error if record doesn't exist to kill 
  NEW IENS SET IENS=SUBIEN_","_TOPIEN_","
  SET TMGFDA(22719.51,IENS,.01)="@"
  DO FILE^DIE("E","TMGFDA","TMGMSG")
  IF $DATA(TMGMSG) DO  GOTO HNDKDN
  . SET RESULT="-1^"+$$GETERRST^TMGDEBU2(.TMGMSG)
HNDKDN ;  
  QUIT RESULT
  ;
TOPICLST(OUT,ADFN,STARTING,DIR,MAX)  ;"List all topics in file 22719.51 (a subfile)
  ;"RPC ENTRY POINT FOR: TMG CPRS TOPIC SUBSET
  ;"Input: OUT -- PASS BY REFERENCE, an OUT PARAMETER.
  ;"       ADFN -- Patient IEN to retrieve results for
  ;"       STARTING -- Optional.  If provided, then list returns starts right AFTER this via $ORDER
  ;"       DIR -- Optional.  Default=1.  If -1, then direction is reversed
  ;"       MAX -- Optional.  Default=42.  Max number of results to return
  ;"Results: none
  ;"Output: OUT is filled as follows.
  ;"        OUT(0)="1^OK" or "-1^Error Message"
  ;"        OUT(#)=<IENS>^Name^<ProbIEN>^<ICDIEN>
  KILL OUT
  NEW RESULT SET RESULT="1^OK"
  SET ADFN=$GET(ADFN) IF ADFN'>0 DO  GOTO TPLSTDN
  . SET RESULT="-1^Patient DFN not provided"
  IF '$DATA(^DPT(ADFN)) DO  GOTO TPLSTDN
  . SET RESULT="-1^DFN provided doesn't exist in PATIENT file (#2)"
  NEW TOPIEN SET TOPIEN=+$ORDER(^TMG(22719.5,"B",ADFN,0))  
  IF TOPIEN'>0 DO  GOTO TPLSTDN
  . SET RESULT="-1^Record in file 22719.5 doesn't exist for DFN of "_ADFN
  SET DIR=+$GET(DIR) IF (DIR'=1)&(DIR'=-1) SET DIR=1
  SET MAX=+$GET(MAX) IF MAX'>0 SET MAX=42
  NEW CT SET CT=1
  NEW TOPIC SET TOPIC=$$UP^XLFSTR($GET(STARTING))
  FOR  SET TOPIC=$ORDER(^TMG(22719.5,TOPIEN,1,"B",TOPIC),DIR) QUIT:(TOPIC="")!(CT>MAX)  DO
  . NEW SUBIEN SET SUBIEN=+$ORDER(^TMG(22719.5,TOPIEN,1,"B",TOPIC,0)) QUIT:+SUBIEN'>0
  . NEW ZN SET ZN=$GET(^TMG(22719.5,TOPIEN,1,SUBIEN,0))
  . SET OUT(CT)=SUBIEN_","_TOPIEN_",^"_$PIECE(ZN,"^",1,3),CT=CT+1  
TPLSTDN ;
  SET OUT(0)=RESULT
  QUIT
  ;
LKSUGEST(OUT,TOPIC)  ;"Suggest info for problems to create for given topic  
  ;"RPC ENTRY POINT FOR: TMG CPRS TOPIC PROB SUGGEST
  ;"Input: OUT -- PASS BY REFERENCE, an OUT PARAMETER.
  ;"       TOPIC -- Topic name to suggest from
  ;"Results: none
  ;"Output: OUT is filled as follows.
  ;"        OUT(0)="1^OK" or "-1^Error Message"
  ;"        OUT(#)=<"ICD" OR "10D">^<ICD CODE>^<ICD NAME>^"SCT"^<SCT CODE>^<SCT NAME>   <-- multiple entries, for each suggestion.  
  ;"        if no entries are found, then none returned.  but OUT(0) will still be "1^OK"
  ;"Code below taken (and modified heavily) from LIST^ORQQPL3
  SET TOPIC=$GET(TOPIC)
  IF TOPIC="" DO  QUIT
  . SET OUT(0)="-1^No topic name supplied"
  SET OUT(0)="1^OK"
  NEW CNT SET CNT=0
  NEW IMPLDT SET IMPLDT=$$IMPDATE^LEXU("10D")
  NEW ORIDT SET ORIDT=$$NOW^XLFDT
  NEW TMGLN SET TMGLN=""
  NEW TEMP
  NEW IEN SET IEN=0
  FOR  SET IEN=$ORDER(^TMG(22719.5,"TOPIC",TOPIC,IEN)) QUIT:+IEN'>0  DO
  . NEW SUBIEN SET SUBIEN=0
  . FOR  SET SUBIEN=$ORDER(^TMG(22719.5,"TOPIC",TOPIC,IEN,SUBIEN)) QUIT:+SUBIEN'>0  DO
  . . NEW PROBIEN SET PROBIEN=+$PIECE($GET(^TMG(22719.5,IEN,1,SUBIEN,0)),"^",2)
  . . QUIT:PROBIEN'>0
  . . ;"NOTE: PROBIEN is pointer to file 9000011
  . . NEW GMPL0,GMPL1,GMPL800,GMPL802,I,SCT,ST,ICD,DTREC,ICDD,ORDTINT,ORPLCSYS
  . . NEW ORTOTAL,LIN,INACT
  . . SET (ICDD,INACT)=""
  . . SET GMPL0=$GET(^AUPNPROB(PROBIEN,0)),GMPL1=$GET(^AUPNPROB(PROBIEN,1))
  . . SET GMPL800=$GET(^AUPNPROB(PROBIEN,800)),GMPL802=$GET(^AUPNPROB(PROBIEN,802))
  . . SET SCT=$PIECE(GMPL800,U)
  . . NEW SCTNAME SET SCTNAME=""
  . . IF SCT'="" DO
  . . . NEW IEN757D02 SET IEN757D02=$ORDER(^LEX(757.02,"APCODE",SCT_" ",0)) QUIT:IEN757D02'>0
  . . . NEW IEN757D01 SET IEN757D01=+$GET(^LEX(757.02,IEN757D02,0)) QUIT:IEN757D01'>0
  . . . SET SCTNAME=$$UP^XLFSTR($PIECE($GET(^LEX(757.01,IEN757D01,0)),"^",1))
  . . SET ST=$PIECE(GMPL0,U,12) ;" .12 STATUS: A=ACTIVE I=INACTIVE
  . . IF ST'="A" QUIT  ;"//kt added
  . . NEW LEX
  . . SET ORDTINT=$SELECT(+$PIECE(GMPL802,U,1):$PIECE(GMPL802,U,1),1:$PIECE(GMPL0,U,8))
  . . NEW ICDIEN SET ICDIEN=+GMPL0
  . . SET ORPLCSYS=$SELECT($PIECE(GMPL802,U,2)]"":$PIECE(GMPL802,U,2),1:$$SAB^ICDEX($$CSI^ICDEX(80,ICDIEN),ORDTINT))
  . . IF ORPLCSYS="" SET ORPLCSYS="ICD"  ;"//kt added
  . . SET ICD=$PIECE($$ICDDATA^ICDXCODE(ORPLCSYS,+GMPL0,ORDTINT,"I"),U,2)
  . . IF (ORIDT<IMPLDT),(+$$STATCHK^ICDXCODE($$CSI^ICDEX(80,+GMPL0),ICD,ORIDT)'=1) SET INACT="#"
  . . IF +$GET(SCT),(+$$STATCHK^LEXSRC2(SCT,ORIDT,.LEX)'=1) SET INACT="$"
  . . IF INACT'="" QUIT  ;"//kt added
  . . IF $DATA(^AUPNPROB(PROBIEN,803)) DO
  . . . NEW I SET I=0
  . . . FOR   SET I=$ORDER(^AUPNPROB(PROBIEN,803,I)) QUIT:+I'>0   SET $PIECE(ICD,"/",(I+1))=$PIECE($GET(^AUPNPROB(PROBIEN,803,I,0)),U)
  . . IF +ICD'="" SET ICDD=$$ICDDESC^GMPLUTL2(ICD,ORIDT,ORPLCSYS)
  . . SET DTREC=$PIECE(GMPL1,U,9)  ;"DATE RECORDED
  . . NEW PROBTXT SET PROBTXT=$$PROBTEXT^GMPLX(PROBIEN)
  . . ;"SET LIN=PROBIEN_U_PROBTXT_U_ICD_U_DTREC_U_INACT_U_ICDD_U_ORPLCSYS
  . . SET TMGLN=ORPLCSYS_U_ICD_U_ICDD_U_"SCT"_U_SCT_U_SCTNAME
  . . ;"SET CNT=CNT+1
  . . ;"SET OUT(CNT)=TMGLN
  . . SET TEMP(TMGLN)=""
  . ;"SET GMPL(0)=CNT
  SET TMGLN=""
  FOR  SET TMGLN=$ORDER(TEMP(TMGLN)) QUIT:TMGLN=""  DO
  . SET CNT=CNT+1,OUT(CNT)=TMGLN
  QUIT
  ;
TESTSGST ;
  NEW TOPIC SET TOPIC=""
  FOR  SET TOPIC=$ORDER(^TMG(22719,"HPIALL",TOPIC)) QUIT:TOPIC=""  DO
  . NEW OUT DO LKSUGEST(.OUT,TOPIC)
  . IF $GET(OUT(0))'="1^OK" DO  QUIT
  . . WRITE "ERROR: ",$PIECE(OUT(0),"^",2),! 
  . KILL OUT(0)
  . IF $DATA(OUT)=0 QUIT
  . WRITE "==============",!,TOPIC,!,"==============",!
  . ZWR OUT
  QUIT
  ;
  ;"==========================================================
  ;
DXLIST(OUT,ADFN,CMD,SDT)  ;"Get list of possible diagnoses for user to pick from, during patient encounter
  ;"RPC NAME:  TMG CPRS ENCOUNTER GET DX LIST
  ;"Input:  OUT  -- output.  Format depends on command
  ;"        ADFN
  ;"        CMD -- (can extend in future if needed)
  ;"            CMD = "LIST FOR NOTE^<IEN8925>"
  ;"        SDT -- OPTIONAL.  Starting DT.  Default = 0.  Data prior to SDT can be ignored
  ;"OUTPUT:  OUT -- if CMD='LIST FOR NOTE'
  ;"           OUT(0)="1^OK", OR "-1^<ErrorMessage>"
  ;"           OUT(#)="1^<TOPIC NAME>^<THREAD TEXT>^<LINKED PROBLEM IEN>^<LINKED ICD>^<LINKED ICD LONG NAME>^<LINKED SNOWMED NAME>^<ICD_CODE_SYS>"
  ;"               NOTES:
  ;"                 PIECE#1 = 1 means discussed this visit in note
  ;"                 Topic name is title of section, e.g. 'Back pain'.
  ;"                 Thread text is text that was ADDED to topic paragraph in TIU NOTE
  ;"                 Linked values only returned if Topic name previously linked to a PROBLEM
  ;"                 If Linked ICD's ect not present, then values will be filled with Topic name, and ICDSYS will be 'TMGTOPIC'
  ;"           OUT(#)="2^<TOPIC NAME>^<SUMMARY TEXT>^<LINKED PROBLEM IEN>^<LINKED ICD>^<LINKED ICD LONG NAME>^<LINKED SNOWMED NAME>^<ICD_CODE_SYS>"  
  ;"               NOTES:
  ;"                 PIECE#1 = 2 means NOT discussed this visit, so no THREAD TEXT returned
  ;"                 SummaryText is a fragment from the BEGINNING of the topic paragraph.
  ;"                 Linked values only returned if Topic name previously linked to a PROBLEM
  ;"                 If Linked ICD's ect not present, then values will be filled with Topic name, and ICDSYS will be 'TMGTOPIC'
  ;"           OUT(#)="3^<PROBLEM INFORMATION>  <--- format as created by LIST^ORQQPL3
  ;"               FORMAT of PROBLEM INFORMATION by pieces.  
  ;"                  1    2       3         4   5       6          7   8      9       10    11      12     13      14       15             16           17              18                19                 20                    
	;"                 ifn^status^description^ICD^onset^last modified^SC^SpExp^Condition^Loc^loc.type^prov^service^priority^has comment^date recorded^SC condition(s)^inactive flag^ICD long description^ICD coding system
	;"                   NOTE: ifn = Pointer to Problem #9000011
  ;"               NOTES:
  ;"                 PIECE#1 = 3 means node is a listing of PROBLEM
  ;"                 If problem already listed in a 1 or 2 node, then it will NOT be listed here
  ;"           OUT(#)="4^<PRIOR ICD>^<ICD LONG NAME>^<FMDT LAST USED>^<ICDCODESYS>" 
  ;"               NOTES:
  ;"                 PIECE#1 = 4 means that information is for an ICD code that was previously set for a patient visit.
  ;"                 If ICD has already been included in a piece#1=1 node, then it will NOT be listed here.  
  ;"           OUT(#)="5^HEADER^<Section Name>" 
  ;"        or OUT(#)="5^ENTRY^<ICD CODE>^<DISPLAY NAME>^<ICD LONG NAME>^<ICDCODESYS>" 
  ;"               NOTES:
  ;"                 PIECE#1 = 5 means that information is for a listing of common ICD code from a defined encounter form. 
  ;"                 PIECE#2 is either 'HEADER' or 'ENTRY'
  ;"                        Examples of HEADER nodes would be 'Cardiovascular', or 'Musculoskeletal'.  This is title of section for grouping of codes
  ;"                        ENTRY nodes will be the actual returned data. 
  ;"RESULT: none. But OUT(0) = 1^OK, or -1^ErrorMessage
  ;
  NEW TMGZZDB SET TMGZZDB=0
  IF TMGZZDB=1 DO
  . SET ADFN=$GET(^TMG("TMP","DXLIST^TMGTIIUT3","ADFN"))
  . SET CMD=$GET(^TMG("TMP","DXLIST^TMGTIIUT3","CMD"))
  . SET SDT=$GET(^TMG("TMP","DXLIST^TMGTIIUT3","SDT"))
  ELSE  DO
  . KILL ^TMG("TMP","DXLIST^TMGTIIUT3")
  . SET ^TMG("TMP","DXLIST^TMGTIIUT3","ADFN")=$GET(ADFN)
  . SET ^TMG("TMP","DXLIST^TMGTIIUT3","CMD")=$GET(CMD)
  . SET ^TMG("TMP","DXLIST^TMGTIIUT3","SDT")=$GET(SDT)
  ;    
  SET OUT(0)="1^OK"  ;"default
  SET ADFN=+$GET(ADFN)
  SET SDT=+$GET(SDT)
  NEW IDX SET IDX=1
  NEW CMD1 SET CMD1=$PIECE(CMD,"^",1)
  IF CMD1="LIST FOR NOTE" DO
  . NEW IEN8925 SET IEN8925=+$PIECE(CMD,"^",2)
  . NEW ARRAY DO SUMNOTE(IEN8925,.ARRAY)
  . KILL ARRAY(IEN8925,"FULL"),ARRAY(IEN8925,"SEQ#")
  . NEW PROBLIST DO PROBLST(.PROBLIST,ADFN,SDT)
  . NEW THREADINFO DO THREADS(.THREADINFO,ADFN,IEN8925,.ARRAY)
  . NEW TOPICS DO UNUSEDTOPICS(.TOPICS,.ARRAY,.THREADINFO)
  . NEW ICDLIST DO ICDLIST(.ICDLIST,ADFN,SDT)
  . ;"-------Items discussed this visit in note ----------------
  . NEW JDX SET JDX=0
  . FOR  SET JDX=$ORDER(THREADINFO(JDX)) QUIT:JDX'>0  DO
  . . NEW LINE SET LINE=$GET(THREADINFO(JDX)) QUIT:JDX=""
  . . NEW TOPIC SET TOPIC=$PIECE(LINE,"^",1)
  . . NEW THREADTXT SET THREADTXT=$PIECE(LINE,"^",2)
  . . NEW PROBIEN SET PROBIEN=$PIECE(LINE,"^",3)
  . . NEW LINKIDX SET LINKIDX=$GET(PROBLST("PROBLEM",PROBIEN))
  . . NEW PROBINFO SET PROBINFO=$GET(PROBLST(LINKIDX))
  . . NEW ICD,ICDNAME,ICDCODESYS SET (ICD,ICDDAME,ICDCODESYS)=""
  . . SET ICD=$PIECE(PROBINFO,"^",4) IF ICD'="" DO
  . . . SET ICDNAME=$PIECE(PROBINFO,"^",19)
  . . . SET ICDCODESYS=$PIECE(PROBINFO,"^",20)
  . . SET ICDINFO=$PIECE(LINE,"^",4) IF ICDINFO'=""  DO   ;"Only if linked ICD in 22719.5 
  . . . ;"ICDINFO format: '<ICD_IEN>;<ICD_CODE>;<ICD_TEXT>;<ICD_CODING_SYS>'
  . . . SET ICD=$PIECE(ICDINFO,";",2)
  . . . SET ICDNAME=$PIECE(ICDINFO,";",3)
  . . . SET ICDCODESYS=$PIECE(ICDINFO,";",4)
  . . IF ICD="",ICDCODESYS="" SET (ICE,ICDNAME)=TOPIC,ICDCODESYS="TMGTOPIC"
  . . NEW SNOMED SET SNOMED=$PIECE(PROBINFO,"^",3)
  . . NEW RESULT SET RESULT=TOPIC_"^"_THREADTXT_"^"_PROBIEN_"^"_ICD_"^"_ICDNAME_"^"_SNOMED_"^"_ICDCODESYS
  . . SET OUT(IDX)="1^"_RESULT,IDX=IDX+1
  . ;"------- NOT discussed this visit ----------------------------
  . SET JDX=0
  . FOR  SET JDX=$ORDER(TOPICS(JDX)) QUIT:JDX'>0  DO
  . . NEW LINE SET LINE=$GET(TOPICS(JDX)) QUIT:JDX=""
  . . NEW TOPIC SET TOPIC=$PIECE(LINE,"^",1)
  . . IF $DATA(THREADINFO("TOPIC",TOPIC))>0 QUIT
  . . NEW THREADTXT SET THREADTXT=$PIECE(LINE,"^",2)
  . . NEW PROBIEN SET PROBIEN=$PIECE(LINE,"^",3)
  . . NEW LINKIDX SET LINKIDX=$GET(PROBLST("PROBLEM",PROBIEN))
  . . NEW PROBINFO SET PROBINFO=$GET(PROBLST(LINKIDX))
  . . NEW ICD SET ICD=$PIECE(PROBINFO,"^",4)
  . . NEW ICDDAME SET ICDNAME=$PIECE(PROBINFO,"^",19)
  . . NEW ICDCODESYS SET ICDCODESYS=$PIECE(PROBINFO,"^",20)
  . . IF ICD="",ICDCODESYS="" SET (ICE,ICDNAME)=TOPIC,ICDCODESYS="TMGTOPIC"
  . . NEW SNOMED SET SNOMED=$PIECE(PROBINFO,"^",3)
  . . NEW RESULT SET RESULT=TOPIC_"^"_THREADTXT_"^"_PROBIEN_"^"_ICD_"^"_ICDNAME_"^"_SNOMED_"^"_ICDCODESYS
  . . SET OUT(IDX)="2^"_LINE,IDX=IDX+1
  . ;"------- listing of PROBLEMs ----------------------------  
  . SET JDX=0
  . FOR  SET JDX=$ORDER(PROBLIST(JDX)) QUIT:JDX'>0  DO
  . . NEW LINE SET LINE=$GET(PROBLIST(JDX)) QUIT:JDX=""
  . . NEW IEN SET IEN=+LINE QUIT:IEN'>0
  . . IF $DATA(THREADINFO(IEN)) QUIT
  . . IF $DATA(TOPICS(IEN)) QUIT
  . . SET OUT(IDX)="3^"_LINE,IDX=IDX+1
  . ;"------- Listing of prior ICD codes -----------------------  
  . SET JDX=0
  . FOR  SET JDX=$ORDER(ICDLIST(JDX)) QUIT:JDX'>0  DO
  . . NEW LINE SET LINE=$GET(ICDLIST(JDX)) QUIT:JDX=""
  . . SET OUT(IDX)="4^"_LINE,IDX=IDX+1
  . ;"--------Suspect medical conditions -----
  . ;"DO SUSMCENC^TMGSUSMC(.OUT,.IDX,ADFN)                  
  . NEW SDT SET SDT=$$TODAY^TMGDATE
  . NEW THISYEAR SET THISYEAR=$EXTRACT(SDT,1,3)+1700
  . NEW SUSARR DO GET1PAT^TMGSUSMC(.SUSARR,ADFN,THISYEAR)
  . IF $DATA(SUSARR) DO
  . . SET OUT(IDX)="5^HEADER^Suspect Medical Conditions",IDX=IDX+1
  . . NEW MCIDX SET MCIDX=9999
  . . FOR  SET MCIDX=$ORDER(SUSARR(MCIDX),-1) QUIT:MCIDX'>0  DO
  . . . NEW ICD,DESC,ZN,CONDITION
  . . . SET ZN=$GET(SUSARR(MCIDX))
  . . . SET ICD=$PIECE(ZN,"^",2),DESC=$PIECE(ZN,"^",4)
  . . . SET ICD=$$FIXICD^TMGSUSMC(ICD)
  . . . SET CONDITION=$PIECE(ZN,"^",3)
  . . . SET OUT(IDX)="5^ENTRY^"_ICD_"^"_DESC_"^"_CONDITION_"^10D",IDX=IDX+1
  . ;"--------common ICD code from file -----
  . NEW ALLARRAY,USEDARR
  . SET JDX=0 FOR  SET JDX=$ORDER(^TMG(22753,"ASEQ",JDX)) QUIT:JDX'>0  DO
  . . NEW IEN SET IEN=0
  . . FOR  SET IEN=$ORDER(^TMG(22753,"ASEQ",JDX,IEN)) QUIT:IEN'>0  DO
  . . . DO ADDENTRY(.OUT,.IDX,IEN,.USEDARR,.ALLARRAY) 
  . ;"Now get subentries for which SEQ was not specified
  . NEW IEN SET IEN=0
  . FOR  SET IEN=$ORDER(^TMG(22753,IEN)) QUIT:IEN'>0  DO
  . . IF $DATA(USEDARR(IEN)) QUIT
  . . DO ADDENTRY(.OUT,.IDX,IEN,.USEDARR,.ALLARRAY) 
  . SET OUT(IDX)="5^HEADER^All Encounter Dx's",IDX=IDX+1
  . NEW DISPNAME SET DISPNAME=""
  . FOR  SET DISPNAME=$ORDER(ALLARRAY(DISPNAME)) QUIT:DISPNAME=""  DO
  . . SET OUT(IDX)="5^ENTRY^"_$GET(ALLARRAY(DISPNAME)),IDX=IDX+1  
  . ;"-------------------------------------------------------------  
  QUIT
  ;
ADDENTRY(OUT,IDX,IEN,USEDARR,ALLARRAY) ;"utility function for common ICD's above
  IF $DATA(USEDARR(IEN)) QUIT
  SET USEDARR(IEN)=""
  NEW SECTNAME SET SECTNAME=$PIECE($GET(^TMG(22753,IEN,0)),"^",1) QUIT:SECTNAME=""
  SET OUT(IDX)="5^HEADER^"_SECTNAME,IDX=IDX+1
  NEW KDX SET KDX=0
  FOR  SET KDX=$ORDER(^TMG(22753,IEN,1,"ASEQ",KDX)) QUIT:KDX'>0  DO
  . NEW SUBIEN SET SUBIEN=0
  . FOR  SET SUBIEN=$ORDER(^TMG(22753,IEN,1,"ASEQ",KDX,SUBIEN)) QUIT:SUBIEN'>0  DO
  . . SET USEDARR(IEN,"SUB",SUBIEN)=""
  . . DO ADDSUBENTRY(.OUT,.IDX,IEN,SUBIEN,.ALLARRAY)
  ;"Now get subentries for which SEQ was not specified
  NEW SUBIEN SET SUBIEN=0
  FOR  SET SUBIEN=$ORDER(^TMG(22753,IEN,1,SUBIEN)) QUIT:SUBIEN'>0  DO
  . IF $DATA(USEDARR(IEN,"SUB",SUBIEN)) QUIT  ;"already used
  . SET USEDARR(IEN,"SUB",SUBIEN)=""
  . DO ADDSUBENTRY(.OUT,.IDX,IEN,SUBIEN,.ALLARRAY)
  QUIT
  ;
ADDSUBENTRY(OUT,IDX,IEN,SUBIEN,ALLARRAY) ;"utility function for common ICD's above  
  NEW ZN SET ZN=$GET(^TMG(22753,IEN,1,SUBIEN,0)) QUIT:ZN=""
  NEW IEN80 SET IEN80=+$PIECE(ZN,"^",1) QUIT:IEN80'>0
  NEW ICDCODE SET ICDCODE=$PIECE($GET(^ICD9(IEN80,0)),"^",1)
  NEW ICDNAME SET ICDNAME=$$VSTD^ICDEX(IEN80)
  NEW DISPNAME SET DISPNAME=$PIECE(ZN,"^",3)
  NEW ICDCODESYS SET ICDCODESYS="10D"   ;"HARD CODE FOR NOW
  SET OUT(IDX)="5^ENTRY^"_ICDCODE_"^"_DISPNAME_"^"_ICDNAME_"^"_ICDCODESYS,IDX=IDX+1
  NEW TEMPNAME SET TEMPNAME=DISPNAME
  IF TEMPNAME'="" SET TEMPNAME=DISPNAME_"("_ICDNAME_")" 
  ELSE  SET TEMPNAME=ICDNAME
  SET ALLARRAY(TEMPNAME)=ICDCODE_"^"_DISPNAME_"^"_ICDNAME_"^"_ICDCODESYS
  QUIT
  ;   
SUMNOTE(IEN8925,ARRAY) ;"Get back summary data from prior parsing and storage. 
  ;"Input: IEN8925 -- note IEN
  ;"       ARRAY -- PASS BY REFERENCE, AN OUT PARAMETER.  Format: 
  ;"            ARRAY(<IEN8925>,"THREAD",#)=<TOPIC NAME>^<THREAD TEXT>
  ;"            ARRAY(<IEN8925>,"HPI",#)=<TOPIC NAME>^<SUMMARY TEXT>    
  SET IEN8925=+$GET(IEN8925)
  NEW ADFN SET ADFN=0
  FOR  SET ADFN=$ORDER(^TMG(22719.2,"ATIU",IEN8925,ADFN)) QUIT:ADFN'>0  DO
  . NEW TOPICREC SET TOPICREC=0
  . FOR  SET TOPICREC=$ORDER(^TMG(22719.2,"ATIU",+IEN8925,ADFN,TOPICREC)) QUIT:TOPICREC'>0  DO
  . . NEW TOPICNAME SET TOPICNAME=$PIECE($GET(^TMG(22719.2,ADFN,1,TOPICREC,0)),"^",1)
  . . NEW DTREC SET DTREC=0
  . . FOR  SET DTREC=$ORDER(^TMG(22719.2,"ATIU",+IEN8925,ADFN,TOPICREC,DTREC)) QUIT:DTREC'>0  DO
  . . . NEW LINE SET LINE=""
  . . . NEW IDX SET IDX=0
  . . . FOR  SET IDX=$ORDER(^TMG(22719.2,ADFN,1,TOPICREC,1,DTREC,1,IDX)) QUIT:IDX'>0  DO
  . . . . SET LINE=LINE_$GET(^TMG(22719.2,ADFN,1,TOPICREC,1,DTREC,1,IDX,0))
  . . . SET ARRAY(IEN8925,"THREAD",DTREC)=TOPICNAME_"^"_LINE
  NEW TOPICREC SET TOPICREC=0
  FOR  SET TOPICREC=$ORDER(^TMG(22719,IEN8925,2,TOPICREC)) QUIT:TOPICREC'>0  DO
  . NEW ZN SET ZN=$GET(^TMG(22719,IEN8925,2,TOPICREC,0))
  . SET ARRAY(IEN8925,"HPI",TOPICREC)=ZN
  IF $DATA(ARRAY)=0 DO SUMNOTE^TMGTIUP1(IEN8925,.ARRAY)
  QUIT
  ;
THREADS(OUT,ADFN,IEN8925,ARRAY)  ;"Get THREADS info for note
  ;"INPUT:  OUT -- PASS BY REFERENCE, AN OUT PARAMETER.  Format:
  ;"           OUT(#)='<TOPIC NAME>^<THREAD TEXT>^<LINKED PROBLEM IEN>^<ICD_INFO>'
  ;"           OUT("TOPIC",<TOPIC NAME>)=#
  ;"           OUT("PROBLEM",<PROBLEM IEN>)=#
  ;"           NOTE: *For ICD_INFO, format is:
  ;"                '<ICD_IEN>;<ICD_CODE>;<ICD_TEXT>;<ICD_CODING_SYS>' 
  ;"                ICD_IEN is IEN in #80.  
  ;"                ICD_CODE e.g. I10 for Essential HTN
  ;"                ICD_CODING_SYS.  e.g. 10D for ICD 10
	;"        ADFN -- patient IEN
  ;"        IEN8925 -- NOTE IEN
  ;"        ARRAY -- note info as could be created by SUMNOTE() or SUMNOTE^TMGTIUP1
  ;"            ARRAY(<IEN8925>,"THREAD",#)=<TOPIC NAME>^<THREAD TEXT>
  NEW IDX SET IDX=1  
  NEW JDX SET JDX=0  
  FOR  SET JDX=$ORDER(ARRAY(IEN8925,"THREAD",JDX)) QUIT:JDX'>0  DO
  . NEW LINE SET LINE=$GET(ARRAY(IEN8925,"THREAD",JDX)) QUIT:LINE=""
  . NEW TOPIC SET TOPIC=$$UP^XLFSTR($PIECE(LINE,"^",1))
  . NEW THREADTXT SET THREADTXT=$PIECE(LINE,"^",2,9999)
  . SET THREADTXT=$$REPLSTR^TMGSTUT3(THREADTXT,"^","-[/\]-")  ;"Ensure threadtxt doesn't contain any "^"s
  . NEW PTIEN SET PTIEN=+$ORDER(^TMG(22719.5,"B",ADFN,0))
  . NEW LINKIEN SET LINKIEN=+$ORDER(^TMG(22719.5,PTIEN,1,"B",$EXTRACT(TOPIC,1,30),0))
  . NEW ZN SET ZN=$GET(^TMG(22719.5,PTIEN,1,LINKIEN,0))
  . NEW PROBIEN SET PROBIEN=+$PIECE(ZN,"^",2)
  . NEW ICDIEN SET ICDIEN=+$PIECE(ZN,"^",3)
  . NEW ICDINFO SET ICDINFO="" IF ICDIEN>0 DO
  . . NEW N0 SET N0=$GET(^ICD9(ICDIEN,0))
  . . NEW N1 SET N1=$GET(^ICD9(ICDIEN,1))
  . . NEW CS SET CS=""
  . . NEW CODESYSIEN SET CODESYSIEN=$PIECE(N1,"^",1)  ;" 1;1  --> 1.1  CODING SYSTEM <-Pntr  [*P80.4']
  . . IF CODESYSIEN>0 DO  
  . . . NEW ZN SET ZN=$GET(^ICDS(CODESYSIEN,0))
  . . . NEW CSABRV SET CSABRV=$PIECE(ZN,"^",2) 
  . . . NEW CSYS SET CSYS=$PIECE(ZN,"^",1) 
  . . . SET CS=CSABRV
  . . NEW TEMP SET TEMP=$$ICDDATA^ICDXCODE(CS,ICDIEN)  ;"e.g. 504605^G47.30^^Sleep apnea, unspecified^^3^^0^^1^^^^^^^3151001^^0^30^0^
  . . SET ICDINFO=ICDIEN_";"_$PIECE(TEMP,"^",2)_";"_$PIECE(TEMP,"^",4)_";"_CS
  . NEW RESULT SET RESULT=TOPIC_"^"_THREADTXT_"^"_PROBIEN_"^"_ICDINFO
  . SET OUT(IDX)=RESULT
  . SET OUT("TOPIC",TOPIC)=IDX
  . SET OUT("PROBLEM",+PROBIEN)=IDX
  . SET IDX=IDX+1
  QUIT
  ;
UNUSEDTOPICS(OUT,ARRAY,THREADINFO)  ;"Get list of topics that do NOT have corresponding thread text  
  ;"INPUT:  OUT -- PASS BY REFERENCE, AN OUT PARAMETER.  Format:
  ;"           OUT(#)="<TOPIC NAME>^<SUMMARY TEXT>^<LINKED PROBLEM IEN>
  ;"           OUT("TOPIC",<TOPIC NAME>)=#
  ;"           OUT("PROBLEM",<PROBLEM IEN>)=#
  ;"           OUT("ICD",<ICD COD>)=#
  ;"        ARRAY -- note info as could be created by SUMNOTE() or SUMNOTE^TMGTIUP1
  ;"            ARRAY(<IEN8925>,"HPI",#)=<TOPIC NAME>^<SUMMARY TEXT>
  ;"        THREADINFO -- ARRAY as created by THREADS()
  NEW IDX SET IDX=1
  NEW TOPIC SET TOPIC=""
  NEW JDX SET JDX=0
  FOR  SET JDX=$ORDER(ARRAY(IEN8925,"HPI",JDX)) QUIT:(JDX'>0)  DO
  . NEW LINE SET LINE=$GET(ARRAY(IEN8925,"HPI",JDX)) QUIT:LINE=""
  . NEW TOPIC SET TOPIC=$$UP^XLFSTR($PIECE(LINE,"^",1))
  . IF $DATA(THREADINFO("TOPIC",TOPIC)) QUIT
  . NEW SUMMTXT SET SUMMTXT=$PIECE(LINE,"^",2,9999)
  . SET SUMMTXT=$$REPLSTR^TMGSTUT3(SUMMTXT,"^","-[/\]-")  ;"Ensure text doesn't contain any "^"s
  . NEW PTIEN SET PTIEN=+$ORDER(^TMG(22719.5,"B",ADFN,0))
  . NEW LINKIEN SET LINKIEN=+$ORDER(^TMG(22719.5,PTIEN,1,"B",TOPIC,0))
  . NEW ZN SET ZN=$GET(^TMG(22719.5,PTIEN,1,LINKIEN,0))
  . NEW PROBIEN SET PROBIEN=+$PIECE(ZN,"^",2)
  . NEW RESULT SET RESULT=TOPIC_"^"_SUMMTXT_"^"_PROBIEN
  . SET OUT(IDX)=RESULT,IDX=IDX+1
  QUIT
  ;
PROBLST(OUT,ADFN,SDT)  ;"Get listing of patient's defined problem list
  ;"Input: OUT -- PASS BY REFERENCE, AN OUT PARAMETER.  Format:      
  ;"           OUT(0) = COUNT
  ;"           OUT(#)="<PROBLEM INFORMATION>  <--- format as created by LIST^ORQQPL3
  ;"               FORMAT of PROBLEM INFORMATION by pieces.  
  ;"                  1    2       3         4   5       6          7   8      9       10    11      12     13      14       15             16           17              18                19                 20                    
	;"                 ifn^status^description^ICD^onset^last modified^SC^SpExp^Condition^Loc^loc.type^prov^service^priority^has comment^date recorded^SC condition(s)^inactive flag^ICD long description^ICD coding system
	;"                   NOTE: ifn = Pointer to Problem #9000011
	;"       ADFN -- patient IEN
	;"       SDT -- Starting date for returned problems.
	;"Result: none
  SET SDT=+$GET(SDT)
  NEW STATUS SET STATUS="A"  ;"A=ACTIVE
  DO LIST^ORQQPL3(.OUT,ADFN,STATUS,SDT)
  NEW IDX SET IDX=0
  FOR  SET IDX=$ORDER(OUT(IDX)) QUIT:IDX'>0  DO
  . NEW LINE SET LINE=$GET(OUT(IDX)) QUIT:LINE=""
  . NEW IEN SET IEN=+LINE QUIT:IEN'>0
  . SET OUT("PROBLEM",IEN)=IDX
  QUIT
  ;
ICDLIST(OUT,ADFN,SDT) ;"Get listing of ICD's used for patient in past
  ;"Input: OUT -- PASS BY REFERENCE, AN OUT PARAMETER.  Format:
  ;"        OUT(#)=<ICD CODE>^<ICD NAME>^<LAST USED FMDT>^<ICDCODESYS>
	;"       ADFN -- patient IEN
	;"       SDT -- Starting date for returned problems.
	;"Result: none
  NEW TEMP,XREF
  NEW EDT SET EDT=9999999
  NEW OPTION SET OPTION("ICDSYS")=1
  DO GETICD^TMGRPT4(.TEMP,ADFN,.SDT,.EDT,.OPTION)  ;"Gather ICD's for patient into array
  NEW IDX SET IDX=1
  NEW SORTARR  ;"<-- Used to remove duplicate ICD entries and alpha sort by NAME
  NEW ADT SET ADT=0  
  FOR  SET ADT=$ORDER(TEMP("ICD",ADT)) QUIT:ADT'>0  DO
  . NEW LINE SET LINE=""
  . FOR  SET LINE=$ORDER(TEMP("ICD",ADT,LINE)) QUIT:LINE=""  DO
  . . NEW ICD SET ICD=$PIECE(LINE,"^",1)
  . . NEW ICDNAME SET ICDNAME=$PIECE(LINE,"^",2)
  . . NEW CODESYS SET CODESYS=$PIECE(LINE,"^",3)
  . . SET SORTARR(ICDNAME,ADT)=ICD_"^"_CODESYS
  NEW ICDNAME SET ICDNAME=""
  FOR  SET ICDNAME=$ORDER(SORTARR(ICDNAME)) QUIT:ICDNAME=""  DO
  . NEW LDT SET LDT=$ORDER(SORTARR(ICDNAME,""),-1)  ;"get just the last entry
  . NEW ICD SET ICD=$GET(SORTARR(ICDNAME,LDT))
  . NEW CODESYS SET CODESYS=$PIECE(ICD,"^",2)
  . SET ICD=$PIECE(ICD,"^",1)
  . SET OUT(IDX)=ICD_"^"_ICDNAME_"^"_LDT_"^"_CODESYS
  . SET IDX=IDX+1
  ;" FOR  SET ADT=$ORDER(TEMP("ICD",ADT)) QUIT:ADT'>0  DO
  ;" . NEW LINE SET LINE=""
  ;" . FOR  SET LINE=$ORDER(TEMP("ICD",ADT,LINE)) QUIT:LINE=""  DO
  ;" . . NEW ICD SET ICD=$PIECE(LINE,"^",1)
  ;" . . NEW ICDNAME SET ICDNAME=$PIECE(LINE,"^",2)
  ;" . . SET XREF(ICD,ADT)=IDX
  ;" . . SET OUT(IDX)=ICD_"^"_ICDNAME,IDX=IDX+1
  ;" ;"Now determine last used date.
  ;" NEW ICD SET ICD=""
  ;" FOR  SET ICD=$ORDER(XREF(ICD)) QUIT:ICD=""  DO
  ;" . NEW LASTDT SET LASTDT=+$ORDER(XREF(ICD,""),-1) QUIT:LASTDT=0 
  ;" . SET IDX=+$GET(XREF(ICD,LASTDT))
  ;" . SET $PIECE(OUT(IDX),"^",3)=LASTDT
  QUIT
  ;
TESTDX ;
  NEW IEN8925 SET IEN8925=743345
  NEW ADFN SET ADFN=75985
  NEW CMD SET CMD="LIST FOR NOTE^"_IEN8925
  NEW SDT SET SDT=""
  NEW OUT DO DXLIST(.OUT,ADFN,CMD,SDT)
  ZWR OUT
  QUIT
  ;
  ;"==========================================================
  ;
PROCLIST(OUT,ADFN,CMD,SDT)  ;"Get list of possible procedures for user to pick from, during patient encounter
  ;"RPC NAME:  TMG CPRS ENCOUNTER GET CPT LST
  ;"Input:  OUT  -- output.  Format depends on command
  ;"        ADFN
  ;"        CMD -- (can extend in future if needed)
  ;"            CMD = "LIST FOR USER^<USER_IEN/DUZ>"   
  ;"        SDT -- OPTIONAL.  Starting DT.  Default = 0.  Data prior to SDT can be ignored
  ;"OUTPUT:  OUT -- if CMD='LIST FOR USER'
  ;"           OUT(0)="1^OK", OR "-1^<ErrorMessage>"
  ;"           OUT(#)="1^<PRIOR CPT>^<CPT LONG NAME>^<FMDT LAST USED>" 
  ;"               NOTES:
  ;"                 PIECE#1 = 1 means that information is for an ICD code that was previously set for a patient visit.
  ;"           OUT(#)="2^HEADER^<Section Name>" 
  ;"        or OUT(#)="2^ENTRY^<CPT CODE>^<DISPLAY NAME>^<CPT LONG NAME>" 
  ;"               NOTES:
  ;"                 PIECE#1 = 2 means that information is for a listing of common CPT code from a defined encounter form. 
  ;"                 PIECE#2 is either 'HEADER' or 'ENTRY'
  ;"                        Examples of HEADER nodes would be 'Injections', or 'Skin Bx'.  This is title of section for grouping of codes
  ;"                        ENTRY nodes will be the actual returned data. 
  ;"RESULT: none. But OUT(0) = 1^OK, or -1^ErrorMessage
  ;
  NEW TMGZZDB SET TMGZZDB=0
  IF TMGZZDB=1 DO
  . SET ADFN=$GET(^TMG("TMP","PROCLIST^TMGTIIUT3","ADFN"))
  . SET CMD=$GET(^TMG("TMP","PROCLIST^TMGTIIUT3","CMD"))
  . SET SDT=$GET(^TMG("TMP","PROCLIST^TMGTIIUT3","SDT"))
  ELSE  DO
  . KILL ^TMG("TMP","PROCLIST^TMGTIIUT3")
  . SET ^TMG("TMP","PROCLIST^TMGTIIUT3","ADFN")=$GET(ADFN)
  . SET ^TMG("TMP","PROCLIST^TMGTIIUT3","CMD")=$GET(CMD)
  . SET ^TMG("TMP","PROCLIST^TMGTIIUT3","SDT")=$GET(SDT)
  ;    
  SET OUT(0)="1^OK"  ;"default
  SET ADFN=+$GET(ADFN)
  SET SDT=+$GET(SDT)      ;"may use later
  NEW IDX SET IDX=1
  NEW CMD1 SET CMD1=$PIECE(CMD,"^",1)
  NEW ADUZ SET ADUZ=$PIECE(CMD,"^",2)  ;"may use later
  IF CMD1="LIST FOR USER" DO
  . NEW CPTLIST DO CPTLIST(.CPTLIST,ADFN,SDT)
  . ;"------- Listing of prior CPT codes -----------------------  
  . SET JDX=0
  . FOR  SET JDX=$ORDER(CPTLIST(JDX)) QUIT:JDX'>0  DO
  . . NEW LINE SET LINE=$GET(CPTLIST(JDX)) QUIT:JDX=""
  . . SET OUT(IDX)="1^"_LINE,IDX=IDX+1  
  . ;"--------common CPT code from file -----
  . NEW ALLARRAY,USEDARR
  . SET JDX=0 FOR  SET JDX=$ORDER(^TMG(22754,"ASEQ",JDX)) QUIT:JDX'>0  DO
  . . NEW IEN SET IEN=0
  . . FOR  SET IEN=$ORDER(^TMG(22754,"ASEQ",JDX,IEN)) QUIT:IEN'>0  DO
  . . . DO ADDENTRYCPT(.OUT,2,22754,.IDX,IEN,.USEDARR,.ALLARRAY) 
  . ;"Now get subentries for which SEQ was not specified
  . NEW IEN SET IEN=0
  . FOR  SET IEN=$ORDER(^TMG(22754,IEN)) QUIT:IEN'>0  DO
  . . IF $DATA(USEDARR(IEN)) QUIT
  . . DO ADDENTRYCPT(.OUT,2,22754,.IDX,IEN,.USEDARR,.ALLARRAY) 
  . SET OUT(IDX)="2^HEADER^All Encounter CPT's",IDX=IDX+1
  . NEW DISPNAME SET DISPNAME=""
  . FOR  SET DISPNAME=$ORDER(ALLARRAY(DISPNAME)) QUIT:DISPNAME=""  DO
  . . SET OUT(IDX)="2^ENTRY^"_$GET(ALLARRAY(DISPNAME)),IDX=IDX+1  
  . ;"-------------------------------------------------------------  
  QUIT
  ;
ADDENTRYCPT(OUT,NODENUM,FNUM,IDX,IEN,USEDARR,ALLARRAY) ;"utility function for common CPT's above
  IF $DATA(USEDARR(IEN)) QUIT
  SET USEDARR(IEN)=""
  NEW SECTNAME SET SECTNAME=$PIECE($GET(^TMG(FNUM,IEN,0)),"^",1) QUIT:SECTNAME=""
  SET OUT(IDX)=NODENUM_"^HEADER^"_SECTNAME,IDX=IDX+1
  NEW KDX SET KDX=0
  FOR  SET KDX=$ORDER(^TMG(FNUM,IEN,1,"ASEQ",KDX)) QUIT:KDX'>0  DO
  . NEW SUBIEN SET SUBIEN=0
  . FOR  SET SUBIEN=$ORDER(^TMG(FNUM,IEN,1,"ASEQ",KDX,SUBIEN)) QUIT:SUBIEN'>0  DO
  . . SET USEDARR(IEN,"SUB",SUBIEN)=""
  . . DO ADDSUBENTRYCPT(.OUT,NODENUM,FNUM,.IDX,IEN,SUBIEN,.ALLARRAY)
  ;"Now get subentries for which SEQ was not specified
  NEW SUBIEN SET SUBIEN=0
  FOR  SET SUBIEN=$ORDER(^TMG(FNUM,IEN,1,SUBIEN)) QUIT:SUBIEN'>0  DO
  . IF $DATA(USEDARR(IEN,"SUB",SUBIEN)) QUIT  ;"already used
  . SET USEDARR(IEN,"SUB",SUBIEN)=""
  . DO ADDSUBENTRYCPT(.OUT,NODENUM,FNUM,.IDX,IEN,SUBIEN,.ALLARRAY)
  QUIT
  ;
ADDSUBENTRYCPT(OUT,NODENUM,FNUM,IDX,IEN,SUBIEN,ALLARRAY) ;"utility function for common CPT's above  
  NEW ZN SET ZN=$GET(^TMG(FNUM,IEN,1,SUBIEN,0)) QUIT:ZN=""
  NEW IEN81 SET IEN81=+$PIECE(ZN,"^",1) QUIT:IEN81'>0
  NEW Z2 SET Z2=$GET(^ICPT(IEN81,0))
  NEW CPTCODE SET CPTCODE=$PIECE(Z2,"^",1)
  NEW CPTNAME SET CPTNAME=$PIECE(Z2,"^",2)
  NEW DISPNAME SET DISPNAME=$PIECE(ZN,"^",3)
  NEW DISPMODE SET DISPMODE=$PIECE(ZN,"^",4)
  IF DISPMODE="D" SET CPTNAME=""   ;"D=DISPLAY NAME ONLY
  IF DISPMODE="C" SET DISPNAME="" ;"C=CPT NAME ONLY
  SET OUT(IDX)=NODENUM_"^ENTRY^"_CPTCODE_"^"_DISPNAME_"^"_CPTNAME,IDX=IDX+1
  NEW TEMPNAME SET TEMPNAME=DISPNAME
  IF TEMPNAME'="" SET TEMPNAME=DISPNAME_"("_CPTNAME_")" 
  ELSE  SET TEMPNAME=CPTNAME
  SET ALLARRAY(TEMPNAME)=CPTCODE_"^"_DISPNAME_"^"_CPTNAME
  QUIT
  ;   
  ;"==========================================================
  ;
CPTLIST(OUT,ADFN,SDT) ;"Get listing of CPT's used for patient in past. Utility funciton for PROCLIST above. 
  ;"Input: OUT -- PASS BY REFERENCE, AN OUT PARAMETER.  Format:
  ;"        OUT(#)=<CPT CODE>^<CPT NAME>^<LAST USED FMDT>
	;"       ADFN -- patient IEN
	;"       SDT -- Starting date for returned problems.
	;"Result: none
  NEW TEMP,XREF
  NEW EDT SET EDT=9999999
  DO GETCPT^TMGRPT4(.TEMP,ADFN,.SDT,.EDT)  ;"Gather CPT's for patient into array
  NEW IDX SET IDX=1
  NEW SORTARR  ;"<-- Used to remove duplicate CPT entries and alpha sort by NAME
  NEW ADT SET ADT=0  
  FOR  SET ADT=$ORDER(TEMP("CPT",ADT)) QUIT:ADT'>0  DO
  . NEW LINE SET LINE=""
  . FOR  SET LINE=$ORDER(TEMP("CPT",ADT,LINE)) QUIT:LINE=""  DO
  . . NEW CPT SET CPT=$PIECE(LINE,"^",1)
  . . NEW CPTNAME SET CPTNAME=$PIECE(LINE,"^",2)
  . . SET SORTARR(CPTNAME,ADT)=CPT
  NEW CPTNAME SET CPTNAME=""
  FOR  SET CPTNAME=$ORDER(SORTARR(CPTNAME)) QUIT:CPTNAME=""  DO
  . NEW LDT SET LDT=$ORDER(SORTARR(CPTNAME,""),-1)  ;"get just the last entry
  . NEW CPT SET CPT=$GET(SORTARR(CPTNAME,LDT))
  . SET CPT=$PIECE(CPT,"^",1)
  . SET OUT(IDX)=CPT_"^"_CPTNAME_"^"_LDT
  . SET IDX=IDX+1
  QUIT
  ;
TESTCPT ;
  NEW ADFN SET ADFN=75985
  NEW CMD SET CMD="LIST FOR USER^168"
  NEW SDT SET SDT=""
  NEW OUT DO PROCLIST(.OUT,ADFN,CMD,SDT)
  ZWR OUT
  QUIT
  ;
  ;"==========================================================
  ;
VISITLIST(OUT,ADFN,CMD,SDT)  ;"Get list of possible procedures for user to pick from, during patient encounter
  ;"RPC NAME:  TMG CPRS ENCOUNTER GET VST LST
  ;"Input:  OUT  -- output.  Format depends on command
  ;"        ADFN
  ;"        CMD -- (can extend in future if needed)
  ;"            CMD = "LIST FOR USER,LOC^<USER_IEN/DUZ>^<LOCIEN>"   
  ;"        SDT -- OPTIONAL.  Starting DT.  Default = 0.  Data prior to SDT can be ignored
  ;"OUTPUT:  OUT -- if CMD='LIST FOR USER'
  ;"           OUT(0)="1^OK", OR "-1^<ErrorMessage>"
  ;"           OUT(#)="1^HEADER^<Section Name>" 
  ;"        or OUT(#)="1^ENTRY^<CPT CODE>^<DISPLAY NAME>^<CPT LONG NAME>" 
  ;"               NOTES:
  ;"                 PIECE#1 =12 means that information is for a listing of common VISIT CPT code from a defined encounter form. 
  ;"                 PIECE#2 is either 'HEADER' or 'ENTRY'
  ;"                        Examples of HEADER nodes would be 'Injections', or 'Skin Bx'.  This is title of section for grouping of codes
  ;"                        ENTRY nodes will be the actual returned data. 
  ;"RESULT: none. But OUT(0) = 1^OK, or -1^ErrorMessage
  ;
  NEW TMGZZDB SET TMGZZDB=0
  IF TMGZZDB=1 DO
  . SET ADFN=$GET(^TMG("TMP","VISITLIST^TMGTIIUT3","ADFN"))
  . SET CMD=$GET(^TMG("TMP","VISITLIST^TMGTIIUT3","CMD"))
  . SET SDT=$GET(^TMG("TMP","VISITLIST^TMGTIIUT3","SDT"))
  ELSE  DO
  . KILL ^TMG("TMP","VISITLIST^TMGTIIUT3")
  . SET ^TMG("TMP","VISITLIST^TMGTIIUT3","ADFN")=$GET(ADFN)
  . SET ^TMG("TMP","VISITLIST^TMGTIIUT3","CMD")=$GET(CMD)
  . SET ^TMG("TMP","VISITLIST^TMGTIIUT3","SDT")=$GET(SDT)
  ;    
  SET OUT(0)="1^OK"  ;"default
  SET ADFN=+$GET(ADFN)      ;"may use later
  SET SDT=+$GET(SDT)        ;"may use later
  NEW IDX SET IDX=1
  NEW CMD1 SET CMD1=$PIECE(CMD,"^",1)
  NEW ADUZ SET ADUZ=$PIECE(CMD,"^",2)  ;"may use later
  NEW LOC SET LOC=$PIECE(CMD,"^",1)    ;"may use later
  IF CMD1="LIST FOR USER,LOC" DO
  . ;"--------common VISIT CPT code from a file  -----
  . NEW ALLARRAY,USEDARR
  . SET JDX=0 FOR  SET JDX=$ORDER(^TMG(22755,"ASEQ",JDX)) QUIT:JDX'>0  DO
  . . NEW IEN SET IEN=0
  . . FOR  SET IEN=$ORDER(^TMG(22755,"ASEQ",JDX,IEN)) QUIT:IEN'>0  DO
  . . . DO ADDENTRYCPT(.OUT,1,22755,.IDX,IEN,.USEDARR,.ALLARRAY) 
  . ;"Now get subentries for which SEQ was not specified
  . NEW IEN SET IEN=0
  . FOR  SET IEN=$ORDER(^TMG(22755,IEN)) QUIT:IEN'>0  DO
  . . IF $DATA(USEDARR(IEN)) QUIT
  . . DO ADDENTRYCPT(.OUT,1,22755,.IDX,IEN,.USEDARR,.ALLARRAY) 
  . SET OUT(IDX)="1^HEADER^All Visit Codes",IDX=IDX+1
  . NEW DISPNAME SET DISPNAME=""
  . FOR  SET DISPNAME=$ORDER(ALLARRAY(DISPNAME)) QUIT:DISPNAME=""  DO
  . . SET OUT(IDX)="1^ENTRY^"_$GET(ALLARRAY(DISPNAME)),IDX=IDX+1  
  . ;"-------------------------------------------------------------  
  QUIT
  ;
TESTVST ;
  NEW ADFN SET ADFN=75985
  NEW CMD SET CMD="LIST FOR USER,LOC^168^0"
  NEW SDT SET SDT=""
  NEW OUT DO VISITLIST(.OUT,ADFN,CMD,SDT)
  ZWR OUT
  QUIT
  ;
  
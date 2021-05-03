TMGEVENT       ;TMG - TMG CPRS EVENT FUNCTIONS;   3/24/21
        ;;1.0.CPRS Event Functions:**1**;OCT 29, 2020;Build 1
        ;"
        ;"
CHANNEL(TMGRESULT,EVENTINFO)  ;"
        ;"Purpose: This will be the main Event RPC Channel
        ;"Input: EVENTARRAY=COMMAND^DATA
        ;"       IF COMMAND=SAVE
        ;"             DATA should be USER^PATIENT^EVENT^DATETIME^DATA
        ;"       IF COMMAND=GET
        ;"             DATA should be USER^PATIENT^EVENT
        SET TMGRESULT(0)="1^SUCCESSFUL"
        NEW COMMAND SET COMMAND=$P(EVENTINFO,"^",1)
        IF COMMAND="" DO  GOTO CHDN
        . SET TMGRESULT(0)="-1^NO COMMAND FOUND IN PIECE 1"
        SET EVENTINFO=$P(EVENTINFO,"^",2,9999)
        NEW X SET X="DO "_COMMAND_"(.TMGRESULT,.EVENTINFO)"
        X X
CHDN    ;
        QUIT
        ;"        
SAVE(TMGRESULT,EVENTINFO)
        ;"This will save the event data and return any errors in TMGRESULT

        ;"This is used to store events from CPRS
        ;"Patient and Data are optional because certain events
        ;"    may not need extra data nor may be patient centric
        NEW USER,PATIENT,EVENT,DATA,DATETIME
        SET USER=+$P(EVENTINFO,"^",1),PATIENT=+$P(EVENTINFO,"^",2),EVENT=+$P(EVENTINFO,"^",3)
        SET DATA=+$P(EVENTINFO,"^",5),DATETIME=+$P(EVENTINFO,"^",4),TMGRESULT(0)="1^SUCCESSFUL"
        IF USER'>0 DO  GOTO SADN
        . SET TMGRESULT(0)="-1^USER NOT SENT"
        IF EVENT'>0 DO  GOTO SADN
        . SET TMGRESULT(0)="-1^EVENT NOT SENT"
        IF DATETIME="" DO  GOTO SADN
        . SET TMGRESULT(0)="-1^DATETIME NOT SENT"
        IF DATETIME=0 DO
        . DO NOW^%DTC
        . SET DATETIME=%
        NEW TMGFDA,TMGIEN,TMGMSG,TMGIENS
        SET TMGIENS="+1,"
        SET TMGFDA(22747,TMGIENS,.01)=USER
        IF PATIENT>0 SET TMGFDA(22747,TMGIENS,.02)=PATIENT
        SET TMGFDA(22747,TMGIENS,.03)=EVENT
        SET TMGFDA(22747,TMGIENS,.04)=DATETIME
        IF DATA>0 SET TMGFDA(22747,TMGIENS,.05)=DATA
        DO UPDATE^DIE("","TMGFDA","TMGIEN","TMGMSG")
        IF $DATA(TMGMSG("DIERROR")) DO
        . SET TMGRESULT(0)="-1^Error: "_$$GETERRST^TMGDEBU2(.TMGMSG) 
SADN    ;
        QUIT
        ;"
GET(TMGRESULT,EVENTINFO)
        ;"
        QUIT
        ;"
CHKOPEN(TMGRESULT,EVENTINFO)    ;"
        ;"CHECK THE LAST EVENT FOR AN OPEN EVENT, WITHOUT A CORRESPONDING
        ;"      CLOSE
        SET TMGRESULT(0)="1^NO MESSAGE"
        NEW IDX SET IDX=99999999
        NEW TMGDFN SET TMGDFN=+$P(EVENTINFO,"^",2)
        NEW USER SET USER=+$P(EVENTINFO,"^",1)
        NEW TODAY SET TODAY=$$TODAY^TMGDATE()
        NEW DONE SET DONE=0
        FOR  SET IDX=$O(^TMG(22747,"C",TMGDFN,IDX),-1) QUIT:(IDX'>0)!(DONE=1)  DO
        . NEW ZN SET ZN=$G(^TMG(22747,IDX,0))
        . NEW EVENT SET EVENT=$P(ZN,"^",3) 
        . NEW THISUSER SET THISUSER=$P(ZN,"^",1)
        . NEW THISDATE SET THISDATE=$P(ZN,"^",4)
        . NEW THISDAY SET THISDAY=$P(THISDATE,".",1)
        . IF (EVENT=1)&(THISUSER=USER)&(THISDAY=TODAY) DO
        . . SET DONE=1
        . . SET TMGRESULT(0)="-1^LAST EVENT DOESN'T HAVE CORRESPONDING CLOSE. TURNED ON AT: "_$$EXTDATE^TMGDATE(THISDATE)
        . ELSE  IF (EVENT=2)&(THISUSER=USER) DO
        . . SET DONE=1
        QUIT
        ;"
GETTIME(TMGDFN,VERBOSE,SHOWMSG)  ;"
        ;"GET TOTAL TIME SPENT TODAY
        SET SHOWMSG=+$G(SHOWMSG)
        SET VERBOSE=+$G(VERBOSE)
        NEW TMGRESULT,TIMEARRAY,IDX 
        NEW TODAY SET TODAY=$$TODAY^TMGDATE()
        NEW TIMEIDX SET TIMEIDX=9999
        SET IDX=999999
        FOR  SET IDX=$O(^TMG(22747,"C",TMGDFN,IDX),-1) QUIT:IDX'>0  DO
        . NEW ZN SET ZN=$G(^TMG(22747,IDX,0))
        . NEW EVENT SET EVENT=$P(ZN,"^",3)
        . NEW THISUSER SET THISUSER=$P(ZN,"^",1)
        . IF THISUSER'=DUZ QUIT
        . NEW THISDATE SET THISDATE=$P(ZN,"^",4)
        . NEW EDATE,DAY,TIME SET EDATE=$$EXTDATE^TMGDATE(THISDATE)
        . SET DAY=$P(EDATE,"@",1),TIME=$P(EDATE,"@",2),THISDATE=$P(THISDATE,".",1)
        . IF THISDATE'=TODAY QUIT
        . SET TIMEARRAY(TIMEIDX)=$J($P(ZN,"^",4),7,4)  ;"justify to 4 decimal places
        . SET TIMEIDX=TIMEIDX-1
        ;"NOW CYCLE THROUGH THE ARRAY TO DETERMINE TIME
        SET TMGRESULT=""
        SET TIMEIDX=0
        NEW TOTTIME SET TOTTIME=0
        FOR  SET TIMEIDX=$O(TIMEARRAY(TIMEIDX)) QUIT:TIMEIDX'>0  DO
        . NEW BTIME,ETIME
        . SET BTIME=$G(TIMEARRAY(TIMEIDX)),TIMEIDX=TIMEIDX+1,ETIME=$G(TIMEARRAY(TIMEIDX))
        . IF ETIME'>0 DO   ;"WE ARE GOING TO ASSUME THE CURRENT TIME
        . . NEW X DO NOW^%DTC
        . . SET ETIME=%
        . NEW TIMEDIFF SET TIMEDIFF=$$TIMEDIFF^TMGDATE(BTIME,ETIME)
        . SET TOTTIME=TOTTIME+TIMEDIFF
        . SET TMGRESULT=TMGRESULT_$$EXTDATE^TMGDATE(BTIME)_"-"_$$EXTDATE^TMGDATE(ETIME)_"="_TIMEDIFF_" MINS"_$C(13,10)
        IF VERBOSE=0 SET TMGRESULT=""
        SET TMGRESULT=TMGRESULT_"Time spent with patient: "_TOTTIME_" mins"
        IF SHOWMSG=1 DO
        . SET TMGRESULT=TMGRESULT_$C(13,10)_$C(13,10)_"<BR>This time may include chart review before the visit, the actual patient visit, and time spent on documentation after the visit."
        . SET TMGRESULT=TMGRESULT_$C(13,10)_$C(13,10)_"<BR>If any procedures were done during the visit, the time for the procedure was not included in determining the level of visit."
        QUIT TMGRESULT
        ;"
GTREPORT(ROOT,TMGDFN,ID,ALPHA,OMEGA,DTRANGE,REMOTE,MAX,ORFHIE) ;"AWV report
        ;"RETURN HTML REPORT OF TIME SPENT
        ;"Purpose: Entry point, as called from CPRS REPORT system
        ;"Input: ROOT -- Pass by NAME.  This is where output goes
        ;"       TMGDFN -- Patient DFN ; ICN for foriegn sites
        ;"       ID --
        ;"       ALPHA -- Start date (lieu of DTRANGE)
        ;"       OMEGA -- End date (lieu of DTRANGE)
        ;"       DTRANGE -- # days back from today
        ;"       REMOTE --
        ;"       MAX    --
        ;"       ORFHIE --
        ;"Result: None.  Output goes into @ROOT
        NEW TMGRESULT,RESULTIDX SET RESULTIDX=1
        NEW SDT,EDT
        SET SDT=+$G(ALPHA)
        SET EDT=+$G(OMEGA) IF EDT'>0 SET EDT="9999999"
        NEW HD SET HD="<TABLE BORDER=3><CAPTION><B>PATIENT EVENT REPORT</B><BR>"
        SET HD=HD_" FAMILY PHYSICIANS OF GREENEVILLE<BR>1410 TUSCULUM BLVD  STE. 2600 <BR>"
        SET HD=HD_" GREENEVILLE, TN 37745</CAPTION><TR><TH>DATE</TH>"
        SET HD=HD_"<TH>EVENT</TH><TH>USER</TH><TH>TIME</TH><TH>ELLAPSED</TH></TR>"
        NEW IDX SET IDX=9999999
        NEW LASTDATE SET LASTDATE=0
        NEW LASTTIME SET LASTTIME=0
        NEW SUM
        NEW TIMEARR,PRINTTIME,TOTTIME
        NEW TIMEIDX SET TIMEIDX=1
        FOR  SET IDX=$O(^TMG(22747,"C",TMGDFN,IDX),-1) QUIT:IDX'>0  DO
        . NEW ZN SET ZN=$G(^TMG(22747,IDX,0))
        . NEW EVENT SET EVENT=$P(ZN,"^",3)
        . NEW THISUSER SET THISUSER=$P(ZN,"^",1)
        . NEW THISDATE SET THISDATE=$J($P(ZN,"^",4),7,4)
        . IF (THISDATE<SDT)!(THISDATE>EDT) QUIT
        . NEW ELLAPSED SET ELLAPSED=""""
        . NEW EDATE,DAY,TIME SET EDATE=$$EXTDATE^TMGDATE(THISDATE)
        . SET DAY=$P(EDATE,"@",1),TIME=$P(EDATE,"@",2)
        . IF DAY'=LASTDATE DO
        . . IF LASTDATE'=0 DO TIMESUM(.TIMEARR,.TMGRESULT,.RESULTIDX,SUM)
        . . SET LASTDATE=DAY
        . . SET LASTTIME=THISDATE
        . . SET SUM=0
        . ELSE  DO
        . . SET DAY=""""
        . . IF (LASTTIME'=0) DO
        . . . SET ELLAPSED=$$TIMEDIFF^TMGDATE(LASTTIME,THISDATE)
        . . . SET SUM=SUM+ELLAPSED
        . . . SET LASTTIME=0
        . . ELSE  DO
        . . . SET LASTTIME=THISDATE
        . SET TIMEARR(TIMEIDX)=THISDATE,TIMEIDX=TIMEIDX+1
        . SET TMGRESULT(RESULTIDX)=DAY_"^"_$P($G(^TMG(22746,EVENT,0)),"^",1)_"^"_$P($G(^VA(200,THISUSER,0)),"^",1)_"^"_TIME_"^"_ELLAPSED
        . SET RESULTIDX=RESULTIDX+1
        IF $D(TIMEARR) DO TIMESUM(.TIMEARR,.TMGRESULT,.RESULTIDX,SUM)
        DO SETHTML^TMGRPT2(.ROOT,.TMGRESULT,"CHART EVENT REPORT",HD,5)
        QUIT
        ;"
TIMESUM(TIMEARR,TMGRESULT,RESULTIDX,SUM)  ;"
        ;"CALCULATE THE TIME FOR THE TIME IN TIME ARR. OUTPUT TO TMGRESULT
        NEW TOTTIME,TIMEIDX,ERROR
        SET SUM=+$G(SUM)
        SET TIMEIDX=9999,TOTTIME=0,ERROR=0
        FOR  SET TIMEIDX=$O(TIMEARR(TIMEIDX),-1) QUIT:TIMEIDX'>0  DO
        . NEW THISTIME,NEXTTIME SET THISTIME=$G(TIMEARR(TIMEIDX))
        . SET TIMEIDX=TIMEIDX-1 SET NEXTTIME=$G(TIMEARR(TIMEIDX))
        . IF NEXTTIME'>0 DO  QUIT
        . . SET ERROR=1
        . SET TOTTIME=TOTTIME+$$TIMEDIFF^TMGDATE(NEXTTIME,THISTIME)
        IF SUM>0 SET TOTTIME=SUM
        IF ERROR=1 DO
        . SET TMGRESULT(RESULTIDX)="======^DAY TOTAL TIME^(UNMATCHED TIME!)^"_TOTTIME_"^MINS"
        ELSE  DO
        . SET TMGRESULT(RESULTIDX)="======^DAY TOTAL TIME^======^"_TOTTIME_"^MINS"
        SET RESULTIDX=RESULTIDX+1
        KILL TIMEARR 
        QUIT
        ;" 
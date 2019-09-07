TMGDATE   ;TMG/ELH-DATE FUNCTIONS ; 8/26/17
         ;;1.0;TMG-LIB;**1,17**;8/26/17
      ;  
 ;"~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--
 ;"Copyright (c) 5/23/2019  Kevin S. Toppenberg MD
 ;"
 ;"This file is part of the TMG LIBRARY, and may only be used in accordence
 ;" to license terms outlined in separate file TMGLICNS.m, which should 
 ;" always be distributed with this file.
 ;"~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--
 ;
 ;"TMG DATE UTILITIES
 ;"=======================================================================
 ;" API -- Public Functions.
 ;"=======================================================================
 ;"EXTDATE(FMDATE,FORMAT)  ;"RETURN EXTERNAL DATE FOR PROVIDED FMDATE
 ;"INTDATE(EXTDATE) ;"RETURN FILEMAN DATE OR -1 IF INVALID FORMAT
 ;"ADDDAYS(DAYS)  ;"ADD OR SUBTRACT DAYS FROM TODAY
 ;"NOW() ;"RETURNS THE TIME RIGHT NOW
 ;"TODAY(EXTERNAL,FORMAT)  ;"RETURNS TODAY'S DATE
 ;"MNTHNAME(FMDATE)  ;"RETURNS DEC. 2017
 ;"FIRSTYR()  ;"FIRST DAY OF THE YEAR
 ;"DAYSDIFF(DATE1,DATE2)  ;"RETURNS THE DIFFERENCE BETWEEN 2 DTS IN DAYS
 ;"TIMEDIFF(DATE1,DATE2)  ;"RETURNS THE DIFFERENCE BETWEEN 2 DTS IN MINUTES
 ;"FMTDATE(DATESTR,EXTERNAL)  ;"
 ;"EXT2FMDT(EDATE)  ;"CONVERT EXTERNAL FORMAT DATE INTO A FILEMAN DT NUMBER
 ;"=======================================================================
 ;"=======================================================================
 ;   
EXTDATE(FMDATE,FORMAT)  ;"RETURN EXTERNAL DATE FOR PROVIDED FMDATE
      SET FORMAT=+$G(FORMAT)
      NEW Y
      IF FORMAT=1 DO
      . SET Y=$$FMTE^XLFDT(FMDATE,"2D")
      ELSE  DO
      . SET Y=+$GET(FMDATE) DO DD^%DT
      QUIT Y
      ;"
INTDATE(EXTDATE) ;"RETURN FILEMAN DATE OR -1 IF INVALID FORMAT
      NEW %DT,X,Y
      SET X=EXTDATE
      DO ^%DT
      QUIT Y
      ;"
ADDDAYS(DAYS)  ;"ADD OR SUBTRACT DAYS FROM TODAY
      ;"DAYS WILL CONTAIN # OF DAYS TO ADD, OR SUBTRACT IS NEGATIVE
      NEW X,X1,X2
      SET X1=$$TODAY(),X2=+$GET(DAYS)
      DO C^%DTC
      QUIT X 
      ;"
NOW() ;"RETURNS THE TIME RIGHT NOW
      NEW X DO NOW^%DTC
      QUIT $P(%,".",2)
      ;"
TODAY(EXTERNAL,FORMAT)  ;"RETURNS TODAY'S DATE
      ;"EXTERNAL (0 OR 1): IF 0 (DEFAULT), THE FILEMAN VALUE WILL BE RETURNED, ELSE THE FM DATE
      ;"FORMAT (0 OR 1): ONLY USES IF EXTERNAL=1, IF 0 (DEFAULT) MONTH
      ;"        DAY,YEAR. IF 1 MM/DD/YYYY
      NEW X
      SET EXTERNAL=+$G(EXTERNAL)
      SET FORMAT=+$G(FORMAT)
      DO NOW^%DTC
      IF EXTERNAL=1 DO
      . IF FORMAT=1 DO
      . . SET X=$$FMTE^XLFDT(X,"2D")
      . ELSE  DO
      . . SET X=$$EXTDATE(X)
      QUIT X
      ;"   
MNTHNAME(FMDATE)  ;"RETURNS DEC. 2017
      NEW MONTHS 
      SET MONTHS="JAN^FEB^MAR^APR^MAY^JUN^JUL^AUG^SEPT^OCT^NOV^DEC"
      NEW MONTH,YEAR
      SET MONTH=$E(FMDATE,4,5)
      SET YEAR=$E(FMDATE,1,3)+1700
      QUIT $P(MONTHS,"^",MONTH)_". "_YEAR
      ;"
FIRSTYR()  ;"FIRST DAY OF THE YEAR
      NEW DATE
      SET DATE=$$TODAY
      SET DATE=$E(DATE,1,3)_"0101.000000"
      QUIT DATE
      ;"
DAYSDIFF(DATE1,DATE2)  ;"RETURNS THE DIFFERENCE BETWEEN 2 DTS IN DAYS
      NEW X,X1,X2
      SET X1=DATE1,X2=DATE2
      DO ^%DTC
      IF X["-" SET X=$P(X,"-",2)
      QUIT X
      ;"
TIMEDIFF(DATE1,DATE2)  ;"RETURNS THE DIFFERENCE BETWEEN 2 DTS IN MINUTES
      NEW DAYSDIFF SET DAYSDIFF=$$DAYSDIFF(DATE1,DATE2)
      SET DATE1=$P(DATE1,".",2),DATE2=$P(DATE2,".",2)
      NEW HOURS,MINUTES,H1,H2,M1,M2
      SET H1=$E(DATE1,1,2),M1=$E(DATE1,3,4)
      SET H2=$E(DATE2,1,2),M2=$E(DATE2,3,4)
      SET M1=(H1*60)+M1,M2=(H2*60)+M2
      SET MINUTES=M1-M2
      ;"SET HOURS=((H1-H2)*60)
      ;"IF HOURS["-" SET HOURS=$P(HOURS,"-",2)
      ;"SET MINUTES=M1-M2
      IF MINUTES["-" SET MINUTES=$P(MINUTES,"-",2)
      SET MINUTES=MINUTES+(DAYSDIFF*1440)
      QUIT MINUTES
      ;"
FMTDATE(DATESTR,EXTERNAL)  ;"
      ;"TAKES A DATE IN UNCOMMON FORMAT AND FORMATS IT IN A STANDARD FORMAT
      ;"RETURNS EITHER EXTERNAL DATE (IF EXTERNAL IS 1) OR FM DATE
      NEW TMGRESULT SET TMGRESULT=""
      NEW ARR,WORDARR,IDX,WORDIDX
      SET WORDIDX=1,IDX=0
      DO SPLIT2AR^TMGSTUT2(DATESTR," ",.ARR)
      FOR  SET IDX=$O(ARR(IDX)) QUIT:IDX'>0  DO
      . NEW WORD SET WORD=$G(ARR(IDX))
      . IF WORD="" QUIT
      . IF $$UP^XLFSTR(WORD)["DAY" QUIT  ;"DON'T INCLUDE DOW
      . NEW DELIM SET DELIM=""
      . IF WORD["@" SET DELIM="@"      
      . IF WORD["," SET DELIM=","
      . IF DELIM'="" DO
      . . NEW TEMPWORD SET TEMPWORD=$P(WORD,DELIM,1)
      . . IF TEMPWORD'="" DO
      . . . SET WORDARR(WORDIDX)=TEMPWORD
      . . . SET WORDIDX=WORDIDX+1
      . . SET TEMPWORD=$P(WORD,DELIM,2,999)
      . . IF TEMPWORD'="" DO
      . . . SET WORDARR(WORDIDX)=$P(WORD,DELIM,2,999)
      . . . SET WORDIDX=WORDIDX+1
      . ELSE  DO
      . . SET WORDARR(WORDIDX)=WORD
      . . SET WORDIDX=WORDIDX+1
      SET WORDIDX=0
      SET MONTHS="JAN^FEB^MAR^APR^MAY^JUN^JUL^AUG^SEP^OCT^NOV^DEC"
      NEW MONTH,DAY,YEAR,TIME
      SET DAY=0,TIME=""
      FOR  SET WORDIDX=$O(WORDARR(WORDIDX)) QUIT:WORDIDX'>0  DO
      . NEW WORD SET WORD=$$UP^XLFSTR($G(WORDARR(WORDIDX)))
      . IF MONTHS[$E(WORD,1,3) SET MONTH=$E(WORD,1,3)
      . IF (DAY>0)&(WORD>17) SET YEAR=+$G(WORD)
      . IF (WORD>0)&(WORD<32)&(DAY=0) SET DAY=+$G(WORD)
      . IF WORD[":" DO
      . . IF WORD["AM" SET WORD=$P(WORD,"AM",1)
      . . IF WORD["PM" SET WORD=$P(WORD,"PM",1)
      . . SET TIME=WORD
      set TIME="08:00"
      SET TMGRESULT=MONTH_" "_DAY_","_YEAR_"@"_TIME
      w TMGRESULT
      IF +$G(EXTERNAL)=1 DO
      . SET TMGRESULT=$$INTDATE(TMGRESULT)
      QUIT TMGRESULT
      ;"
EXT2FMDT(EDATE)  ;"CONVERT EXTERNAL FORM DATE INTO A FILEMAN DT NUMBER
      ;"INPUT -- EDATE.  A human-readable date, e.g. '5/23/19' or 'Feb 24 2019' or 'Feb 24 2019 @12:00'
      NEW X,Y,%DT SET %DT="T"
      SET X=EDATE
      DO ^%DT
      QUIT Y
      ;"
TMGHL70 ;TMG/kst-Installation/config tools for POC HL7 processing ;11/14/16, 5/18/21
              ;;1.0;TMG-LIB;**1**;03/12/11
 ;
 ;"TMG POC-UTILITY FUNCTIONS 
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
 ;"=======================================================================
 ;" API -- Public Functions.
 ;"=======================================================================
 ;"SETUP(TMGTESTMSG) --help add NEW tests automatically to various files,
 ;"                    to enable use with POC HL7 processing.
 ;"FILEMENU(TMGTESTMSG,INDENTN) --HANDLE/SHOW FILE MENU
 ;"
 ;"=======================================================================
 ;" API - Private Functions
 ;"=======================================================================
 ;"UTILITY(TMGENV,TMGTESTMSG,TMGHL7MSG,INDENTN) --HANDLE/SHOW UTILITY MENU
 ;"TESTPARS(TMGENV,TMGTESTMSG,TMGHL7MSG,INDENTN) -- add one test to system, so it's result can be accepted into VistA
 ;"PRSMSH(LINE,ARRAY) -- Parse MSH segment  DEPRECIATED
 ;"MAPMENU(TMGENV,TMGTESTMSG,TMGHL7MSG,INDENTN) -- show Mapping menu, and interact with user...
 ;"VMPCK(TMGENV,TMGTESTMSG,TMGHL7MSG,INDENTN)  -- VIEW MAP, PICKING TYPE TO VIEW. 
 ;"VIEWMNLT(TMGENV,NLT) -- VIEW NATIONAL LABORATORY TEST (NLT) MAPPING. 
 ;"VIEWMAP(TMGENV,TESTID,TMGTESTMSG,TMGHL7MSG,INDENTN) -- Show maping between lab code and LABORATORY TEST entry.
 ;
 ;"=======================================================================
 ;"Dependancies
 ;"=======================================================================
 ;" TMGEDIT,TMGUSRIF, TMGDEBUG
 ;" Note: this uses Linux functionality.
 ;"=======================================================================
 ;
SETUP(TMGTESTMSG,INDENTN) ;
        ;"Purpose: To help add NEW tests automatically to various files,
        ;"         to enable use with POC HL7 processing.
        ;"Input: TMGTESTMSG -- optional.  This can be the message to work
        ;"              on.  If not provided, then user will be prompted to
        ;"              load one in via an editor.  Input format:
        ;"              TMGTESTMSG(1)="1st line"
        ;"              TMGTESTMSG(2)="2nd line etc."
        ;"       INDENTN -- OPTIONAL.  the number of spaces to indent the menu display        
        ;"Note: uses globally-scoped vars" TMGLABPREFIX, IEN62D4
        ;"Result: None
        NEW TMGUSERINPUT,TMGHL7MSG,TMGENV
        NEW TMGRESULT,IEN22720 
        NEW TMGMNU,TMGMNUI,TMGTEMP
        SET INDENTN=+$GET(INDENTN)
        NEW INDENTSTR SET INDENTSTR=$J("",INDENTN)
        WRITE !,!
        WRITE INDENTSTR,"Welcome to the TMG HL7 Message Lab Setup Assistant.",!
        WRITE INDENTSTR,"-------------------------------------------",!
SU1     SET TMGRESULT=$$SETUPENV^TMGHL7U(.TMGTESTMSG,.TMGENV,1) 
        SET TMGENV("INTERACTIVE MODE")=1
        IF TMGRESULT'>0 GOTO SUDN
        SET IEN22720=TMGENV("IEN 22720")                
M1      KILL TMGUSERINPUT,TMGMNU
        KILL TMGMNUI SET TMGMNUI=0
        SET TMGMNU(-1,"INDENT")=INDENTN
        SET TMGMNU(TMGMNUI)="Pick HL7 Lab Setup Option for "_TMGENV("INST"),TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="Setup/Test HL7 message test result from lab provider"_$CHAR(9)_"TestParse",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="HL7 Message Transform <MENU>"_$CHAR(9)_"XFRMMenu",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="HL7 Message FILE <MENU>"_$CHAR(9)_"FileMenu",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="Utility <MENU>"_$CHAR(9)_"UtilMenu",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="Try processing HL7 Message using DEBUGGER"_$CHAR(9)_"TryWithDebugger",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="Pick lab source other than "_TMGENV("INST")_" to work on."_$CHAR(9)_"OtherInst",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="Done setting up NEW HL7 Test."_$CHAR(9)_"^",TMGMNUI=TMGMNUI+1
        ;
        SET TMGUSERINPUT=$$MENU^TMGUSRI2(.TMGMNU,"^")
        KILL TMGMNU ;"Prevent from cluttering variable table during debug run
        ;
        IF TMGUSERINPUT="TestParse" DO TESTPARS(.TMGENV,.TMGTESTMSG,.TMGHL7MSG,INDENTN+2) GOTO M1
        IF TMGUSERINPUT="PasteMsg" DO LOADMSG^TMGHL7U2(.TMGTESTMSG) GOTO M1
        IF TMGUSERINPUT="UtilMenu" DO UTILITY(.TMGENV,.TMGTESTMSG,.TMGHL7MSG,INDENTN+2) GOTO M1
        IF TMGUSERINPUT="FileMenu" DO FILEMENU(.TMGTESTMSG,INDENTN+2) GOTO M1
        IF TMGUSERINPUT="XFRMMenu" DO SETUP^TMGHL7S(.TMGENV,.TMGTESTMSG,INDENTN+2) GOTO M1
        IF TMGUSERINPUT="TryWithDebugger" DO DEBUGTRY(.TMGTESTMSG,.TMGENV) GOTO M1
        ;
        IF TMGUSERINPUT="OtherInst" DO  GOTO SU1
        . KILL ^TMG("TMP","TMGHL70","IEN 68.2")
        . KILL ^TMG("TMP","TMGHL70","IEN 62.4")
        ;"IF TMGUSERINPUT="EditTest" DO EDITTEST GOTO M1
        IF TMGUSERINPUT="MapMenu" DO MAPMENU(.TMGENV,.TMGTESTMSG,.TMGHL7MSG,INDENTN+2) GOTO M1
        IF TMGUSERINPUT="LRWU5" DO ^LRWU5 GOTO M1
        IF TMGUSERINPUT="Dump" DO ASKDUMP^TMGDEBU3 GOTO M1
        IF TMGUSERINPUT="^" GOTO SUDN
        IF TMGUSERINPUT=0 SET TMGUSERINPUT=""
        GOTO M1
        ;
SUDN    WRITE "Quitting.  Goodbye",!
        QUIT
        ;
UTILITY(TMGENV,TMGTESTMSG,TMGHL7MSG,INDENTN) ;"HANDLE/SHOW UTILITY MENU
        ;"Input: TMGENV -- PASS BY REFERENCE.  Lab environment
        ;"           TMGENV("PREFIX") -- e.g. "LMH"
        ;"           TMGENV("IEN 68.2") -- IEN in LOAD/WORK LIST (holds orderable items)
        ;"           TMGENV("IEN 62.4") -- IEN in AUTO INSTRUMENT (holds resultable items)        
        ;"           TMGENV(<other entries>)= etc.              
        ;"           TMGTESTMSG,
        ;"           TMGHL7MSG,
        ;"       INDENTN -- the number of spaces to indent the menu display
        ;"Result: none
        NEW TMGUSERINPUT,TMGMNU,TMGMNUI,TMGTEMP
UT1     KILL TMGUSERINPUT,TMGMNU
        ;
        KILL TMGMNUI SET TMGMNUI=0
        SET TMGMNU(-1,"INDENT")=INDENTN
        SET TMGMNU(TMGMNUI)="Pick HL7 Lab Setup Utilty Option for "_TMGENV("INST"),TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="Modify an existing data name"_$CHAR(9)_"LRWU6",TMGMNUI=TMGMNUI+1
        ;"SET TMGMNU(TMGMNUI)="Add atomic data name"_$CHAR(9)_"LRWU5",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="Add atomic lab tests"_$CHAR(9)_"AddAtomic",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="Edit atomic lab tests"_$CHAR(9)_"EditAtomic",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="Check/Fix mapping of tests <MENU>"_$CHAR(9)_"MapMenu",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="View arbitrary record in file."_$CHAR(9)_"Dump",TMGMNUI=TMGMNUI+1
        ;"SET TMGMNU(TMGMNUI)="<HL7 Message FILE MENU>"_$CHAR(9)_"FileMenu",TMGMNUI=TMGMNUI+1

        SET TMGMNU(TMGMNUI)="Done"_$CHAR(9)_"^",TMGMNUI=TMGMNUI+1
        ;
        SET TMGUSERINPUT=$$MENU^TMGUSRI2(.TMGMNU,"^")
        KILL TMGMNU ;"Prevent from cluttering variable table during debug run
        ;
        IF TMGUSERINPUT="MapMenu" DO MAPMENU(.TMGENV,.TMGTESTMSG,.TMGHL7MSG,INDENTN+2) GOTO UT1
        IF TMGUSERINPUT="LRWU5" DO ^LRWU5 GOTO UT1
        IF TMGUSERINPUT="LRWU6" DO EDITEDN^TMGHL70D GOTO UT1
        IF TMGUSERINPUT="AddAtomic" SET TMGTEMP=$$ADDATOMIC^TMGHL70C() GOTO UT1
        IF TMGUSERINPUT="Dump" DO ASKDUMP^TMGDEBU3 GOTO UT1
        IF TMGUSERINPUT="EditAtomic" DO EDITATOMIC^TMGHL70D(.TMGENV) GOTO UT1
        ;"IF TMGUSERINPUT="FileMenu" DO FILEMENU(.TMGTESTMSG,INDENTN+2) GOTO UT1
        IF TMGUSERINPUT="^" GOTO UTDN
        IF TMGUSERINPUT=0 SET TMGUSERINPUT=""
        GOTO UT1
        ;
UTDN    QUIT
        ;
FLSTMENU(TMGTESTMSG,INDENTN,FILES) ;"FILE LIST MENU -- Show menu of files to load, from options passed in ARR
        ;"Input: TMGTESTMSG -- the message to work on.
        ;"       INDENTN -- the number of spaces to indent the menu display
        ;"       FILES -- PASS BY REFERENCE.  List of files to pick from.  Format:
        ;"            FILES(<FULL_FILE_PATH_AND_FILE_NAME>)=""
        ;
        NEW MENU,MENUCT,USRPICK
        NEW FNAME,FPATH 
FLM0    KILL MENU SET MENUCT=0
        SET MENU(0)="Pick HL7 file"
        NEW AFILE SET AFILE=""
        FOR  SET AFILE=$ORDER(FILES(AFILE)) QUIT:AFILE=""  DO
        . DO SPLITFPN^TMGIOUTL(AFILE,.FPATH,.FNAME)
        . SET MENUCT=MENUCT+1,MENU(MENUCT)=FNAME_$CHAR(9)_FPATH_"^"_FNAME
        IF MENUCT=0 DO  GOTO FLMDN
        . WRITE !,"No files to pick from",!
        SET USRPICK=$$MENU^TMGUSRI2(.MENU,"^")
        IF USRPICK="^" GOTO FLMDN
        SET FPATH=$PIECE(USRPICK,"^",1) IF FPATH="" GOTO FLMDN
        SET FNAME=$PIECE(USRPICK,"^",2) IF FNAME="" GOTO FLMDN
        DO LOADMSG3^TMGHL7U2(.TMGTESTMSG,FPATH,FNAME)        
FLMDN   QUIT
        ;
FILEMENU(TMGTESTMSG,INDENTN) ;"HANDLE/SHOW FILE MENU
        ;"Input: TMGTESTMSG -- the message to work on.
        ;"       INDENTN -- the number of spaces to indent the menu display
        ;"NOTE: may access IEN772,IEN773,HLMIEN,HLMIENS, but no error IF absent.
        ;"Result: none
        NEW TMGUSERINPUT,TMGMNU,TMGMNUI
        IF '$DATA(IEN772),$DATA(HLMIEN) MERGE IEN772=HLMIEN
        IF '$DATA(IEN773),$DATA(HLMIENS) MERGE IEN773=HLMIENS
        IF $DATA(IEN773),'$DATA(IEN772) NEW IEN773 ;"If both not present, hide present
        IF $DATA(IEN772),'$DATA(IEN773) NEW IEN772 ;"If both not present, hide present
        ;
FMU1    KILL TMGUSERINPUT,TMGMNU
        ;
        KILL TMGMNUI SET TMGMNUI=0
        SET TMGMNU(-1,"INDENT")=INDENTN
        SET TMGMNU(TMGMNUI)="Pick HL7 Message FILE Option",TMGMNUI=TMGMNUI+1
        IF $DATA(TMGTESTMSG)=0 DO        
        . SET TMGMNU(TMGMNUI)="Pick past HL7 for a selected PATIENT"_$CHAR(9)_"Patient",TMGMNUI=TMGMNUI+1
        . SET TMGMNU(TMGMNUI)="HFS -- Load a host text file as HL7 message"_$CHAR(9)_"LoadMsg",TMGMNUI=TMGMNUI+1
        . SET TMGMNU(TMGMNUI)="Paste an HL7 message into editor"_$CHAR(9)_"PasteMsg",TMGMNUI=TMGMNUI+1
        . SET TMGMNU(TMGMNUI)="Load a HL7 message from HL7 MESSAGE TEXT file"_$CHAR(9)_"LoadFMMsg",TMGMNUI=TMGMNUI+1
        ELSE  DO
        . SET TMGMNU(TMGMNUI)="View current HL7 message"_$CHAR(9)_"ViewMsg",TMGMNUI=TMGMNUI+1
        . SET TMGMNU(TMGMNUI)="Clear currently loaded test HL7 message"_$CHAR(9)_"ClearMsg",TMGMNUI=TMGMNUI+1
        . SET TMGMNU(TMGMNUI)="Save currently loaded test HL7 message to HFS file"_$CHAR(9)_"SaveMsg",TMGMNUI=TMGMNUI+1
        . SET TMGMNU(TMGMNUI)="Edit loaded HL7 test message"_$CHAR(9)_"EditMsg",TMGMNUI=TMGMNUI+1
        . IF $DATA(IEN772)&$DATA(IEN773) DO
        . . SET TMGMNU(TMGMNUI)="Save currently loaded test HL7 message to Fileman File"_$CHAR(9)_"SaveMsgFM",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="Done with FILE options."_$CHAR(9)_"^",TMGMNUI=TMGMNUI+1
        ;
        SET TMGUSERINPUT=$$MENU^TMGUSRI2(.TMGMNU,"^")
        KILL TMGMNU ;"Prevent from cluttering variable table during debug run
        ;
        IF TMGUSERINPUT="Patient" DO  GOTO FMU1
        . NEW FILES DO PKHL7F^TMGLRWU3(,.FILES)
        . DO FLSTMENU^TMGHL70(.TMGTESTMSG,,.FILES)
        IF TMGUSERINPUT="PasteMsg" DO LOADMSG^TMGHL7U2(.TMGTESTMSG) GOTO FMU1
        IF TMGUSERINPUT="LoadMsg" DO LOADMSG2^TMGHL7U2(.TMGTESTMSG) GOTO FMU1
        IF TMGUSERINPUT="LoadFMMsg" DO LOADMSGF^TMGHL7U2(.TMGTESTMSG) GOTO FMU1        
        IF TMGUSERINPUT="ClearMsg" KILL TMGTESTMSG GOTO FMU1
        IF TMGUSERINPUT="ViewMsg" DO VIEWMSG^TMGHL7U2(.TMGTESTMSG) GOTO FMU1
        IF TMGUSERINPUT="EditMsg" DO EDITMSG^TMGHL7U2(.TMGTESTMSG) GOTO FMU1
        IF TMGUSERINPUT="SaveMsg" DO SAVEMSG^TMGHL7U2(.TMGTESTMSG) GOTO FMU1
        IF TMGUSERINPUT="SaveMsgFM" DO SAVMSGFM^TMGHL7U2(.TMGTESTMSG,.IEN772,.IEN773) GOTO FMU1
        IF TMGUSERINPUT="^" GOTO FMUDN
        IF TMGUSERINPUT=0 SET TMGUSERINPUT=""
        GOTO FMU1
        ;
FMUDN   QUIT
        ;
TESTPARS(TMGENV,TMGTESTMSG,TMGHL7MSG,INDENTN) ;
        ;"Purpose: Test parse, and add one test to system, so it's result can be accepted into VistA
        ;"         If problems are found, user will be queried to correct problems. 
        ;"Input: TMGENV -- PASS BY REFERENCE.  Lab environment
        ;"           TMGENV("PREFIX") -- e.g. "LMH"
        ;"           TMGENV("IEN 68.2") -- IEN in LOAD/WORK LIST (holds orderable items)
        ;"           TMGENV("IEN 62.4") -- IEN in AUTO INSTRUMENT (holds resultable items)        
        ;"           TMGENV(<other entries>)= etc.              
        ;"       TMGTESTMSG -- the message to work on.
        ;"       TMGHL7MSG --PASS BY REFERENCE.  AN OUT PARAMETER.
        ;"Result: none
        NEW TMGRESULT SET TMGRESULT=1
        SET INDENTN=+$GET(INDENTN)
        NEW INDENTSTR SET INDENTSTR=$JUSTIFY("",INDENTN)
        NEW TMGU MERGE TMGU=TMGENV("TMGU")
        IF $DATA(TMGTESTMSG)'>0 DO  GOTO TSTMSG
        . SET TMGRESULT="-1^No message provided to parse, in TESTPARS.TMGHL70"
        ;
        ;"SET TMGENV("INDENTN")=INDENTN
        NEW OPTION SET OPTION("INTERACTIVE MODE")=1
        SET TMGRESULT=$$HL7PROCESS^TMGHL71(.TMGHL7MSG,.TMGENV,.TMGTESTMSG,.OPTION) ;" PARSE, then XFORM
        ;
        ;
        ;"  NEW TEMP SET TEMP=1
        ;"  SET TMGRESULT=$$PRSEARRY^TMGHL7X2(,.TMGTESTMSG,.TMGHL7MSG,.TMGU)        
        ;"  IF TMGRESULT<0 QUIT
        ;"  SET TMGRESULT=$$SETMAPS^TMGHL70B(.TMGENV,.TMGHL7MSG)
        ;"  ;"---------------------------------------------------
        ;"  ;"//kt added below 4/9/19 because a test was failing during full parse, but succeeding here and thus couldn't fix.              
        ;"  IF TMGRESULT<0 QUIT
        ;"  SET TMGHL7MSG("STAGE")="PRE"
        ;"  SET TMGRESULT=$$XFMSG^TMGHL7X(.TMGENV,.TMGHL7MSG)
        ;"  IF TMGRESULT<0 QUIT
        ;"  SET TMGRESULT=$$SETMAPS^TMGHL70B(.TMGENV,.TMGHL7MSG)
        ;"  IF TMGRESULT<0 QUIT
        ;"  SET TMGHL7MSG("STAGE")="FINAL"
        ;"  SET TMGRESULT=$$XFMSG^TMGHL7X(.TMGENV,.TMGHL7MSG)
        ;"  SET TMGHL7MSG("STAGE")=""
        ;"  ;"---------------------------------------------------
TSTMSG ;    
        WRITE !,INDENTSTR        
        IF TMGRESULT<0 DO  
        . WRITE $PIECE(TMGRESULT,"^",2),!
        ELSE  DO  
        . WRITE "Transform and processing of HL7 message was OK.",! 
        WRITE INDENTSTR        
        DO PRESS2GO^TMGUSRI2
        WRITE !
ADDTDN  QUIT
        ;
DEBUGTRY(TMGTESTMSG,TMGENV)  ;"Try processing message via debugger.  
        NEW OPTION 
        SET OPTION("GUI","NO FILE")=1  ;"prevent filing of message.  
        WRITE !,"NOTE: HL7 message will be processed but NOT be filed into database.",!
        IF $$TRYAGAN2^TMGHL7E(.TMGTESTMSG,1,.TMGENV)  ;"ignore results
        QUIT
        ;
MAPMENU(TMGENV,TMGTESTMSG,TMGHL7MSG,INDENTN) ;
        ;"Purpose: show Mapping menu, and interact with user...
        ;"Input: TMGENV -- PASS BY REFERENCE.  Lab environment
        ;"           TMGENV("PREFIX") -- e.g. "LMH"
        ;"           TMGENV("IEN 68.2") -- IEN in LOAD/WORK LIST (holds orderable items)
        ;"           TMGENV("IEN 62.4") -- IEN in AUTO INSTRUMENT (holds resultable items)        
        ;"           TMGENV(<other entries>)= etc.
        ;"       TMGTESTMSG
        ;"       TMGHL7MSG
        ;"       INDENTN -- the number of spaces to indent the menu display
        ;"Result: none
        NEW TMGUSERINPUT,TMGMNU,TMGMNUI
MMM1    SET TMGMNUI=0
        SET TMGMNU(-1,"INDENT")=INDENTN
        SET TMGMNU(TMGMNUI)="Check, Fix, Edit Mapping of tests",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="Show map of 1 test"_$CHAR(9)_"VIEWMAP",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="Remove mapping of 1 test"_$CHAR(9)_"DelMap",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="View arbitrary record in file."_$CHAR(9)_"Dump",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="Traditional map, some special fixes"_$CHAR(9)_"SpecialMap",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="VA standard lab mapping display"_$CHAR(9)_"ShowOldMap",TMGMNUI=TMGMNUI+1
        ;
        WRITE !
        SET TMGUSERINPUT=$$MENU^TMGUSRI2(.TMGMNU,"^")
        KILL TMGMNU ;"Prevent from cluttering variable table during debug run
        ;
        IF TMGUSERINPUT="SpecialMap" DO TESTMAP^TMGHL70A(.TMGENV,.TMGTESTMSG,.TMGHL7MSG) GOTO MMM1
        IF TMGUSERINPUT="ShowOldMap" DO PRINT^LA7PCFG GOTO MMM1
        IF TMGUSERINPUT="DelMap" DO DELMAP^TMGHL70D(.TMGENV,.TMGTESTMSG,.TMGHL7MSG) GOTO MMM1
        IF TMGUSERINPUT="VIEWMAP" DO VMPCK(.TMGENV,.TMGTESTMSG,.TMGHL7MSG,INDENTN) GOTO MMM1
        IF TMGUSERINPUT="Dump" DO ASKDUMP^TMGDEBU3 GOTO MMM1
        IF TMGUSERINPUT="^" GOTO MMDN
        IF TMGUSERINPUT=0 SET TMGUSERINPUT=""
        GOTO MMM1
MMDN    QUIT
        ;
VMPCK(TMGENV,TMGTESTMSG,TMGHL7MSG,INDENTN)  ;"VIEW MAP, PICKING TYPE TO VIEW. 
        ;"Input: TMGENV -- PASS BY REFERENCE.  Lab environment
        ;"           TMGENV("PREFIX") -- e.g. "LMH"
        ;"           TMGENV("IEN 68.2") -- IEN in LOAD/WORK LIST (holds orderable items)
        ;"           TMGENV("IEN 62.4") -- IEN in AUTO INSTRUMENT (holds resultable items)        
        ;"           TMGENV(<other entries>)= etc.
        ;"       TMGTESTMSG
        ;"       TMGHL7MSG
        ;"       INDENTN -- the number of spaces to indent the menu display
        ;"Result: none
        ;
        ;"TO DO.....  Allow working with already-parsed TMGHL7MSG.
        ;"        And if no data, then offer to parse and create now
        ;"        This is because some of the HL7 messages have crazy test codes that will
        ;"        get fixed prior to mapping to actual tests....
        ;
        NEW TMGUSERINPUT,TMGMNU,TMGMNUI
VMPM1   KILL TMGMNUI SET TMGMNUI=0
        SET TMGMNU(-1,"INDENT")=INDENTN
        SET TMGMNU(TMGMNUI)="Pick Type of 1-Test Mapping To View",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="HL7: Show map of test code from HL7 message (from lab provider)"_$CHAR(9)_"FromLab",TMGMNUI=TMGMNUI+1
        SET TMGMNU(TMGMNUI)="NLT: Show map of transformed NLT code"_$CHAR(9)_"NLTMap",TMGMNUI=TMGMNUI+1
        WRITE !
        SET TMGUSERINPUT=$$MENU^TMGUSRI2(.TMGMNU,"^")
        KILL TMGMNU ;"Prevent from cluttering variable table during debug run
        ;
        IF TMGUSERINPUT="FromLab" DO VIEWMAP(.TMGENV,"",.TMGTESTMSG,.TMGHL7MSG,INDENTN+2) GOTO VMPM1
        IF TMGUSERINPUT="NLTMap" DO VIEWMNLT(.TMGENV,"",.TMGTESTMSG,.TMGHL7MSG,INDENTN+2) GOTO VMPM1
        IF TMGUSERINPUT="^" GOTO VMPDN
        IF TMGUSERINPUT=0 SET TMGUSERINPUT=""
        GOTO VMPM1
VMPDN   QUIT
        ;        
VIEWMNLT(TMGENV,NLT,TMGTESTMSG,TMGHL7MSG,INDENTN)   ;"VIEW NATIONAL LABORATORY TEST (NLT) MAPPING. 
        ;"Purpose: View mapping from NLT code (used during actual filing of lab)
        ;"Input: TMGENV -- PASS BY REFERENCE.  Lab environment
        ;"           TMGENV("PREFIX") -- e.g. "LMH"
        ;"           TMGENV("IEN 68.2") -- IEN in LOAD/WORK LIST (holds orderable items)
        ;"           TMGENV("IEN 62.4") -- IEN in AUTO INSTRUMENT (holds resultable items)                
        ;"           TMGENV(<other entries>)= etc.              
        ;"       NLT -- Optional.  If not provided, then user is prompted for value.
        ;"              This is WKLD CODE (e.g. "81172.0000"), which is 1 field in file 64 (WKLD CODE)
        ;"       TMGTESTMSG
        ;"       TMGHL7MSG  (not yet used)
        ;"       INDENTN -- the number of spaces to indent the menu display (not yet used)
        ;"Result: none
        SET IEN62D4=TMGENV("IEN 62.4")
        SET NLT=$GET(NLT)
        IF NLT="" DO
        . NEW IEN64,DIC,X,Y
        . SET DIC=64,DIC(0)="MAEQ",DIC("A")="Select WKLD CODE / NLT CODE: "
        . DO ^DIC WRITE !
        . IF +Y'>0 QUIT
        . SET NLT=$PIECE($GET(^LAM(+Y,0)),"^",2)
        IF NLT="" DO  GOTO VMNLTDN
        . WRITE "NLT CODE not specified, so can't show map.",!
        NEW MAP,TMGRESULT
        SET TMGRESULT=$$LMAPAPI2^TMGHL7U(.TMGENV,NLT,.MAP) ;"Get actual mapping
        IF TMGRESULT'>0 DO  GOTO VMNLTDN
        . WRITE TMGRESULT,!
        NEW STR SET STR=$GET(MAP(NLT,"IEN64"))        
        WRITE !,"Via C index in file 64 (WKLD CODE) ...",!
        WRITE "  """,NLT," "" --> WKLD CODE #",+STR,", Name: """,$PIECE(STR,"^",3),"""",!
        WRITE !,"Via AC index in file 62.4 (AUTO INSTRUMENT) ...",!
        SET STR=$GET(MAP(NLT,"AUTO INSTRUMENT TEST"))
        WRITE "  """,NLT,""" --> """,$PIECE(STR,"^",2),""" (`",$PIECE(STR,"^",1),")",!
        SET STR=$GET(MAP(NLT,"STORAGE"))
        NEW FIELD SET FIELD=$PIECE(STR,"^",2) IF FIELD="" SET FIELD="??"
        NEW FLDNAME SET FLDNAME=$PIECE(STR,"^",3) IF FLDNAME="" SET FLDNAME="??" 
        WRITE "    Storage: ",$PIECE(STR,"^",1)," --> """,FLDNAME,""" field (#",FIELD,") in 63.04 (CHEM...), in 63 (LAB DATA)",!
        WRITE !
VMNLTDN DO PRESS2GO^TMGUSRI2
        QUIT
        ;        
VIEWMAP(TMGENV,TESTID,TMGTESTMSG,TMGHL7MSG,INDENTN) ;
        ;"Purpose: Show maping between lab code and LABORATORY TEST entry.
        ;"Input: TMGENV -- PASS BY REFERENCE.  Lab environment
        ;"           TMGENV("PREFIX") -- e.g. "LMH"
        ;"           TMGENV("IEN 68.2") -- IEN in LOAD/WORK LIST (holds orderable items)
        ;"           TMGENV("IEN 62.4") -- IEN in AUTO INSTRUMENT (holds resultable items)                
        ;"           TMGENV(<other entries>)= etc.              
        ;"       TESTID -- Optional.  If not provided, then user is prompted for value. 
        ;"       TMGTESTMSG
        ;"       TMGHL7MSG  (not yet used)
        ;"       INDENTN -- the number of spaces to indent the menu display (not yet used)
        ;"Note: uses globally-scoped vars" TMGLABPREFIX, IEN62D4, IEN68D2
        NEW TMGZZ SET TMGZZ=0
        IF TMGZZ=1 DO
        . KILL TMGENV
        . MERGE TMGENV=^TMG("TMP","VIEWMAP^TMGHL70","TMGENV") 
        ELSE  DO
        . KILL ^TMG("TMP","VIEWMAP^TMGHL70")
        . MERGE ^TMG("TMP","VIEWMAP^TMGHL70","TMGENV")=TMGENV 
        NEW X,Y,IEN60,IEN61,IEN62,IEN64,TEMP
        NEW TEST,TESTNAME,%,VACODE,NEWIEN60,IEN62D41,SYN60,SYNONYM,TMGRESULT
        SET TESTID=$GET(TESTID)
VM1     SET TEST=TESTID
        IF TESTID="" DO
        . IF $DATA(TMGTESTMSG) DO
        . . NEW TMGU MERGE TMGU=TMGENV("TMGU")
        . . SET TEST=$$GETTESTFROM(.TMGTESTMSG,.TMGHL7MSG,.TMGU) ;"GET LAB TEST FROM TEST HL7 MESSAGE
        . . ;"sample return: 1989-3^Vitamin D 25-Hydroxy^LN'  //kt changed 6/5/20.  Had returned just TestID before.
        . . SET TESTID=$PIECE(TEST,TMGU(2),1)
        . . ;"NOTE: To fix in future.  Needs to also try looking up by TESTNAME, not just TESTID.  This is
        . . ;"  because when processing HL7 message, if test can't be found by ID, then it falls back to 
        . . ;"  lookup by name.  Thus TESTID might not have map but TESTNAME might.  So need to show both. 
        . ELSE  DO
        . . WRITE !,"Enter lab code as found in HL7 message, e.g. OSMOC (^ to abort): "
        . . READ TESTID:$GET(DTIME,3600),!
        IF "^"[TESTID GOTO VMDN
        WRITE "-----",!
        WRITE "Using this TMGENV:",!
        IF $DATA(TMGENV) ZWRITE TMGENV(*)
        WRITE "-----",!
        NEW ARR
        ;"SET TMGRESULT=$$LMAPAPI^TMGHL7U(.TMGENV,TESTID,.ARR) ;"Get actual mapping
        SET TMGRESULT=$$LMAPAPI^TMGHL7U(.TMGENV,TEST,.ARR) ;"Get actual mapping   //KT 8/26/21
        DO
        . WRITE "-----",!
        . WRITE "Using this mapping array (from $$LMAPAPI^TMGHL7U):",!
        . DO ArrayDump^TMGIDE($NAME(ARR(TESTID)))
        . WRITE "-----",!
        
        SET SYNONYM=$GET(ARR(TESTID,"SYNONYM"))
        SET SYN60=$GET(ARR(TESTID,"SYN60"))  ;"//kt changed 30 -> 60
        WRITE "Using '",SYNONYM,"' as a synonym for a lab test in File# 60, via 'B' index...",!
        ;"First see if already added.
        SET IEN60=$GET(ARR(TESTID,"MAP SYN->60"))  ;"IEN^NAME
        IF (+TMGRESULT<0)&($PIECE(TMGRESULT,"^",2)=1) DO  GOTO VMDN
        . WRITE $PIECE(TMGRESULT,"^",3),!
        . DO PRESS2GO^TMGUSRI2
        SET TESTNAME=$PIECE(IEN60,"^",2)
        WRITE "Current map is:",!
        WRITE " ",TESTID," -->",!
        WRITE "   ",$PIECE(IEN60,"^",2),"(#",+IEN60," in file #60)",!
        SET VACODE=$GET(ARR(TESTID,"VA CODE")) ;"IEN64^WkLdcode^Name
        WRITE "     NATIONAL VA LAB CODE: #",+VACODE," (in File# 64), ",$P(VACODE,"^",2)," -- ",$P(VACODE,"^",3),!
        NEW NLTCODE SET NLTCODE=$GET(ARR(TESTID,"NLT CODE")) ;"IEN64^NLTCode^Name
        WRITE "     RESULT NLT CODE: #",+NLTCODE," (in File# 64)tig, ",$PIECE(NLTCODE,"^",2)," -- ",$P(NLTCODE,"^",3),!
VM2     WRITE !
        WRITE "In LOAD/WORK LIST (#68.2) (holds orderable items):",!
        NEW IEN68D24 SET IEN68D24=$GET(ARR(TESTID,"ORDERABLES","MAP 60->68.24"))  ;"IEN68D24
        IF (+TMGRESULT<0)&($PIECE(TMGRESULT,"^",2)=2) DO  GOTO VMDN
        . WRITE "  ",$PIECE(TMGRESULT,"^",3),!
        . DO PRESS2GO^TMGUSRI2
        WRITE " PROFILE(subrec# 1):TEST(subrec# ",IEN68D24,"):TEST --> (#",+IEN60," in file #60) ",$PIECE(IEN60,"^",2),!
        WRITE !
        WRITE "In AUTO INSTRUMENT (#62.4) file (holds resultable items):",!
        ;"Look up NLT code in auto instrument file, and get pointed to ien60.
        SET IEN62D41=$GET(ARR(TESTID,"RESULTABLES","MAP NLT->62.41")) ;"IEN62D41
        IF (+TMGRESULT<0)&($PIECE(TMGRESULT,"^",2)=3) DO  GOTO VMDN
        . WRITE "  ",$PIECE(TMGRESULT,"^",3),!
        . DO PRESS2GO^TMGUSRI2
        WRITE "  ",$PIECE(NLTCODE,"^",2),", via cross reference 'AC', --> CHEM TESTS (subrec# ",IEN62D41,")",!
        SET NEWIEN60=$GET(ARR(TESTID,"RESULTABLES","MAP 62.41->60"))  ;"IEN60^NAME
        WRITE "    --> (#",+NEWIEN60," in File #60) ",$PIECE(NEWIEN60,"6",2),!
        IF +TMGRESULT=0 DO
        . WRITE !,"***PROBLEM DETECTED***  Notice that pointed-to tests (file #60) are different!",!
        WRITE !
VM3     SET %=2
        WRITE "View entire record for test ",TESTNAME DO YN^DICN WRITE !
        IF %=1 DO
        . DO DUMPREC^TMGDEBU3(60,+IEN60,0)
        . WRITE !
VMDN    QUIT
        ;
GETTESTFROM(TESTMSG,TMGHL7MSG,TMGU) ;"GET TEST ID&NAME FROM TEST HL7 MESSAGE
        ;"Input: TESTMSG -- PASS BY REFERENCE.  FORMAT:
        ;"          TESTMSG(#)=<TEXT>, E.g. TESTMSG(133)= "NTE|1|L|Interpretation of Vitamin D 25 OH:|"
        ;"       TMGHL7MSG -- PASS BY REFERENCE.  Parsed message array.  
        ;"       TMGU -- ARRAY WITH DIVIDER INFO, E.G. 
        ;"       TMGU(1)="|"
        ;"       TMGU(2)="^"
        ;"       TMGU(3)="~"
        ;"       TMGU(4)="\"
        ;"       TMGU(5)="&"
        ;"NOTE: Uses TMGENV in global scope.  
        ;"Result: returns lab or "" if none chosen.    e.g., if user picks:
        ;"         Vitamin D 25-Hydroxy (ID: 1989-3), then '1989-3^Vitamin D 25-Hydroxy^LN' returned.        
        NEW TMGRESULT SET TMGRESULT=""
        IF $DATA(TMGHL7MSG)=0 DO
        . NEW % SET %=1
        . WRITE "HL7 Message should be parsed and transformed before checking mapping.",!
        . WRITE "Transform now" DO YN^DICN WRITE !
        . IF %'=1 QUIT
        . DO TESTPARS(.TMGENV,.TMGTESTMSG,.TMGHL7MSG)
        NEW MENU,TMGUSERINPUT
        SET MENU(0)="Which message source type?"
        SET MENU(1)="Original message (not transformed)"_$CHAR(9)_"ORIG"
        SET MENU(2)="TRANSFORMED message"_$CHAR(9)_"XFORM"
        SET TMGUSERINPUT=$$MENU^TMGUSRI2(.MENU,"^")
        ;
        NEW TEMPMSG
        IF TMGUSERINPUT="XFORM" MERGE TEMPMSG=TMGHL7MSG        
        IF TMGUSERINPUT="ORIG" MERGE TEMPMSG=TESTMSG
        IF $DATA(TEMPMSG)=0 GOTO GTFDN
        ;        
        KILL MENU,TMGUSERINPUT
        NEW MENUCT SET MENUCT=0
        SET MENU(0)="Select lab result from test message to show mapping."
        NEW IDX SET IDX=0
        FOR  SET IDX=$ORDER(TEMPMSG(IDX)) QUIT:IDX'>0  DO
        . NEW LINE SET LINE=$GET(TEMPMSG(IDX)) QUIT:LINE=""
        . NEW TYPE SET TYPE=$PIECE(LINE,TMGU(1),1)
        . IF TYPE'="OBX" QUIT
        . NEW LAB SET LAB=$PIECE(LINE,TMGU(1),4) 
        . NEW ID SET ID=$PIECE(LAB,TMGU(2),1)
        . NEW LABNAME SET LABNAME=$PIECE(LAB,TMGU(2),2)
        . IF (LAB'=""),(ID'=""),(LABNAME'="") SET MENUCT=MENUCT+1,MENU(MENUCT)=LABNAME_" (ID: "_ID_")"_$CHAR(9)_LAB
        . NEW ARR MERGE ARR=TMGHL7MSG(IDX,"RESULT","PREMAP") QUIT:$DATA(ARR)=0
        . NEW TESTID SET TESTID=$GET(ARR("TESTID"))
        . NEW TESTNAME SET TESTNAME=$GET(ARR("TESTNAME"))
        . NEW ALTTESTID SET ALTTESTID=$GET(ARR("ALT TESTID"))
        . NEW ALTTESTNAME SET ALTTESTNAME=$GET(ARR("ALT TESTNAME"))
        . IF TESTID'=""   SET MENUCT=MENUCT+1,MENU(MENUCT)=" (TESTID: "_TESTID_")"_$CHAR(9)_TESTID
        . IF TESTNAME'="" SET MENUCT=MENUCT+1,MENU(MENUCT)=" (TESTNAME: "_TESTNAME_")"_$CHAR(9)_TESTNAME
        . IF ALTTESTID'=""   SET MENUCT=MENUCT+1,MENU(MENUCT)=" (ALT TESTID: "_ALTTESTID_")"_$CHAR(9)_ALTTESTID
        . IF ALTTESTNAME'="" SET MENUCT=MENUCT+1,MENU(MENUCT)=" (ALT TESTNAME: "_ALTTESTNAME_")"_$CHAR(9)_ALTTESTNAME
        ;
        SET MENUCT=MENUCT+1,MENU(MENUCT)="Manual entry of a lab code (e.g. OSMOC)"_$CHAR(9)_"<MANUAL>" 
        SET TMGUSERINPUT=$$MENU^TMGUSRI2(.MENU,"^")
        IF TMGUSERINPUT="<MANUAL>" DO
        . WRITE !,"Enter lab code as found in HL7 message, e.g. OSMOC (^ to abort): "
        . READ TMGUSERINPUT:$GET(DTIME,3600),!
        IF TMGUSERINPUT="^" SET TMGUSERINPUT=""
        SET TMGRESULT=TMGUSERINPUT
GTFDN   ;        
        QUIT TMGRESULT
        ;
GETCFG(HL7INST,HL7APP) ;"DEPRECIATED
        ;"Purpose: To get TMGH HL7 MESSAGE TRANSFORM SETTINGS 
        ;"Input: HL7INST -- Institution, as found in HL7 message, piece #4.
        ;"       HL7APP -- Sending applications, as found in HL7 message, piece #3.
        ;"Result: IEN in 22720 or -1^message if not found or problem. 
        NEW IEN22720 SET IEN22720=0
        SET HL7INST=$GET(HL7INST,"?")
        SET HL7APP=$GET(HL7APP)
        NEW FOUND SET FOUND=0
        FOR  QUIT:FOUND  SET IEN22720=+$ORDER(^TMG(22720,"D",HL7INST,IEN22720)) QUIT:(+IEN22720'>0)!FOUND  DO
        . IF HL7APP="" SET FOUND=1 QUIT  ;"If not APP specified, then use first found. 
        . IF $DATA(^TMG(22720,"EAPP",HL7APP,IEN22720))>0 SET FOUND=1 QUIT
        IF FOUND'>0 SET IEN22720=0
        IF IEN22720'>0 DO
        . SET IEN22720="-1^Can't find entry in 22720 matching SENDING FACILITY=["_HL7INST_"], SENDING APPLICATION=["_HL7APP_"].  Consider editting list in TMGHL7U2."         
        QUIT IEN22720
        ;
GETCFG2(MSH,TMGU,HL7INST,HL7APP) ;
        ;"Purpose: To get TMG HL7 MESSAGE TRANSFORM SETTINGS 
        ;"Input: MSH -- the MSH segment of the HL7 message
        ;"       TMGU -- the array with delimeters
        ;"       HL7INST -- an OUT PARAMETER
        ;"       HL7APP -- an OUT PARAMETER.  
        ;"Result: IEN in 22720 or -1^message if not found or problem.
        ;"note -- There seems to be similarity between this code and MSH2IENA^TMGHL7U2 ??Combine at some point??
        ;"SET HL7INST=$PIECE($PIECE(MSH,TMGU(1),4),TMGU(2),1) ;"//IF HL7INST="" SET HL7INST="?"
        SET HL7INST=$PIECE(MSH,TMGU(1),4)
        IF $$XFRMFACILITY^TMGHL7U2(.HL7INST,.TMGU) ;"ignore result  //kt 1/14/21. Added TMGU 5/18/21
        SET HL7APP=$PIECE($PIECE(MSH,TMGU(1),3),TMGU(2),1)
        IF $$XFRMAPP^TMGHL7U2(.HL7APP,.TMGU)  ;"ignore result
        ;"IF HL7APP="" SET HL7APP="Epic"
        NEW MSGTYPE SET MSGTYPE=$PIECE($PIECE(MSH,TMGU(1),9),TMGU(2),1)
        NEW IEN22720 SET IEN22720=0
        NEW FOUND SET FOUND=0
        FOR  QUIT:FOUND  SET IEN22720=+$ORDER(^TMG(22720,"D",HL7INST,IEN22720)) QUIT:(+IEN22720'>0)!FOUND  DO
        . IF HL7APP="" SET FOUND=1 QUIT  ;"If not APP specified, then use first found. 
        . NEW SUBIEN SET SUBIEN=0
        . NEW SKIP SET SKIP=1
        . FOR  SET SUBIEN=$ORDER(^TMG(22720,IEN22720,23,SUBIEN)) QUIT:SUBIEN'>0  DO
        . .  ;"TO DO, EXAMINE RECORD TO SEE IF MATCHES MESSAGE TYPE.  
        . . IF $P($G(^TMG(22720,IEN22720,23,SUBIEN,0)),"^",1)=MSGTYPE SET SKIP=0
        . IF SKIP=1 QUIT
        . IF $DATA(^TMG(22720,"EAPP",HL7APP,IEN22720))>0 SET FOUND=1 QUIT
        IF FOUND'>0 SET IEN22720=0
        IF IEN22720'>0 DO
        . SET IEN22720="-1^Can't find entry in 22720 matching SENDING FACILITY=["_HL7INST_"], SENDING APPLICATION=["_HL7APP_"] in GETCFG2.TMGHL70.  "
        . SET IEN22720=IEN22720_"Consider editing list in XFRMFACILITY.TMGHL7U2"
        QUIT IEN22720
        ;        
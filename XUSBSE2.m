XUSBSE2 ;FO-OAK/JLI-CONNECT WITH HTTP SERVER AND GET REPLY ;2016-05-23  7:23 AM
 ;;8.0;KERNEL;**404,439,523,ven/smh**;Jul 10, 1995;Build 2
 Q
 ;
 ; Original version, returns only first line after headers
POST(SERVER,PORT,PAGE,DATA,TLS) ;
 N RESULTS
 Q $$ENTRY1(.RESULTS,SERVER,$G(PORT),$G(PAGE),"POST",$G(DATA),+$G(TLS))
 ;
 ; updated, returns entire conversation
POST1(RESULTS,SERVER,PORT,PAGE,DATA,TLS) ;
 Q $$ENTRY1(.RESULTS,SERVER,$G(PORT),$G(PAGE),"POST",$G(DATA),+$G(TLS))
 ;
GET(SERVER,PORT,PAGE,TLS) ;
 N RESULTS
 Q $$ENTRY1(.RESULTS,SERVER,$G(PORT),$G(PAGE),"GET",,+$G(TLS))
 ;
GET1(RESULTS,SERVER,PORT,PAGE,TLS) ;
 Q $$ENTRY1(.RESULTS,SERVER,$G(PORT),$G(PAGE),"GET",,+$G(TLS))
 ;
ENTRY(SERVER,PORT,PAGE,HTTPTYPE,DATA,TLS) ;
 N RESULTS
 S HTTPTYPE=$G(HTTPTYPE,"GET")
 Q $$ENTRY1(.RESULTS,SERVER,$G(PORT),$G(PAGE),HTTPTYPE,$G(DATA),+$G(TLS))
 ;
ENTRY1(RESULTS,SERVER,PORT,PAGE,HTTPTYPE,DATA,TLS) ;
 N XVALUE,XWBSBUF,XWBTDEV
 N XWBDEBUG,XWBOS,XWBT,XWBTIME,POP,RESLTCNT,LINEBUF
 N $ESTACK,$ETRAP S $ETRAP="D TRAP^XUSBSE2"
 K RESULTS
 S PAGE=$G(PAGE,"/") I PAGE="" S PAGE="/"
 S HTTPTYPE=$G(HTTPTYPE,"GET")
 S DATA=$G(DATA),PORT=$G(PORT,80)
 D SAVDEV^%ZISUTL("XUSBSE") ;S IO(0)=$P
 D INIT^XWBTCPM
 D OPEN^XWBTCPM2(SERVER,PORT,TLS)
 I POP Q "DIDN'T OPEN CONNECTION"
 S XWBSBUF=""
 U XWBTDEV
 D WRITE^XWBRW(HTTPTYPE_" "_PAGE_" HTTP/1.0"_$C(13,10))
 I HTTPTYPE="POST" D
 . D WRITE^XWBRW("Referer: http://"_$$KSP^XUPARAM("WHERE")_$C(13,10))
 . D WRITE^XWBRW("Content-Type: application/x-www-form-urlencoded"_$C(13,10))
 . D WRITE^XWBRW("Cache-Control: no-cache"_$C(13,10))
 . D WRITE^XWBRW("Content-Length: "_$L(DATA)_$C(13,10,13,10))
 . D WRITE^XWBRW(DATA)
 D WRITE^XWBRW($C(13,10))
 D WBF^XWBRW
 S XVALUE=$$DREAD($C(13,10)) ; read headers
 D BODY                      ; read body
 D CLOSE                     ; close cxn
 ;
 ; Rtn value is either HTTP error header or first line of response
 I XVALUE'[200 S XVALUE=$P($G(RESULTS(1))," ",2,5)
 E  N I F I=1:1 I RESULTS(I)="" S XVALUE=$G(RESULTS(I+1)) Q
 ;
 QUIT XVALUE
 ;
CLOSE ;
 D CLOSE^%ZISTCP,GETDEV^%ZISUTL("XUSBSE") I $L(IO) U IO
 Q
 ;
DREAD(D,TO) ;Delimiter Read
 S D=$G(D,$C(13)) ; get default delimiter if not passed
 ; ZEXCEPT: LINEBUF,RESLTCNT,RESULTS,XWBRBUF - NEWed and set in ENTRY
 ; ZEXCEPT: XWBDEBUG,XWBTDEV,XWBTIME - XWB global variables
 S TO=$S($G(TO)>0:TO,$G(XWBTIME(1))>0:XWBTIME(1),1:60)/2+1 ; default timeout
 U XWBTDEV            ; use dev
 S RESLTCNT=1         ; line counter
 N DONE S DONE=0  ; flag for for loop
 F  D  Q:DONE         ; loop for each character read
 . R XWBBUF#1         ; Read char
 . ; E  S $EC=",UREAD," ; Connection broken or not an HTTP server. Throw an error.
 . S LINEBUF=$G(LINEBUF)_XWBBUF ; append to buffer
 . I $L(LINEBUF,D)>1 D  Q:DONE  ; if buffer contains delimiter, we finished the read
 .. S RESULTS(RESLTCNT)=$P(LINEBUF,D) ; get the result
 .. I $G(XWBDEBUG)>2 D LOG^XWBDLOG($E("rd ("_$L(LINEBUF)_"): "_LINEBUF,1,255)) ; log if wanted
 .. S LINEBUF="" ; empty buf prep for next read
 .. I RESULTS(RESLTCNT)="" S DONE=1 QUIT  ; if last read is empty, we are at the end of the headers. We are done.
 .. S RESLTCNT=RESLTCNT+1  ; set next sub
 Q RESULTS(1)  ; unused return
 ;
BODY ; Read the body of HTTP response
 ; Extract headers
 N HEADERS
 N I F I=1:1 Q:'$D(RESULTS(I))  D
 . Q:(RESULTS(I)="")
 . N H S H=$P(RESULTS(I),": ")
 . N V S V=$P(RESULTS(I),": ",2)
 . S HEADERS(H)=V
 K I
 ;
 ; Quit if no content length
 I '$D(HEADERS("Content-Length")) QUIT
 I 'HEADERS("Content-Length") QUIT
 ;
 ;
 N REM S REM=HEADERS("Content-Length")           ; remainder
 N DONE S DONE=0                                 ; for flag exit
 F  D  Q:DONE
 . N RDLN S RDLN=$S(REM>(2**15-1):2**15-1,1:REM) ; Cache string limit max read length
 . S REM=REM-RDLN ; remove from remainder
 . N X R X#RDLN ; read
 . ; E  S $EC=",UREAD," ; oops
 . S RESLTCNT=RESLTCNT+1
 . S RESULTS(RESLTCNT)=X ; store
 . I REM=0 S DONE=1 ; if nothing left, we are done
 QUIT
 ;
 ;
 ;
TRAP ;
 I '(($EC["READ")!($EC["WRITE")) D ^%ZTER
 D CLOSE,LOG^XWBDLOG("Error: "_$$EC^%ZOSV):$G(XWBDEBUG),UNWIND^%ZTER
 Q
 ;
EN(ADDRESS) ;  test with input address or 127.0.0.1 if none entered
 N RESULTS
 D EN1(ADDRESS,.RESULTS)
 Q
 ;
EN1(ADDRESS,RESULTS,NOHEADERS) ;
 N VALUE,PAGE,SERVER,PORT
 S NOHEADERS=$G(NOHEADERS,1)
 S PAGE="/",SERVER=ADDRESS,PORT=80
 I SERVER["/" D
 . I SERVER["//" S SERVER=$P(SERVER,"//",2)
 . I SERVER["/" S PAGE="/"_$P(SERVER,"/",2,99),SERVER=$P(SERVER,"/")
 . I SERVER[":" S PORT=$P(SERVER,":",2),SERVER=$P(SERVER,":")
 . Q
 S VALUE=$$ENTRY1(.RESULTS,SERVER,PORT,PAGE)
 D HOME^%ZIS ;I IO="|TCP|80" U IO D ^%ZISC
 ; if NOHEADERS selected (default) remove the headers and first blank line
 I NOHEADERS D
 . N I,J,X
 . ; remove header lines and first blank line
 . F I=1:1 Q:'$D(RESULTS(I))  S X=(RESULTS(I)="") K:'X RESULTS(I) I X K RESULTS(I) Q
 . ; move lines down to start at 1 again
 . S J=I,I=0 F  S J=J+1,I=I+1 Q:'$D(RESULTS(J))  S RESULTS(I)=RESULTS(J) K RESULTS(J)
 . Q
 Q
 ;
TEST D EN^%ut($T(+0),1) QUIT
T1 ; @TEST GET page no TLS
 N R,% S %=$$GET1(.R,"thebes.smh101.com",80,"r/DIC")
 D CHKTF^%ut(%["DIC")
 ; Note: Problem Points from tracing the code
 ; - DREAD+9^XUSBSE2: 80ms elpased time (not user or system) spent
 ; - BODY+20^XUSBSE2: 30ms
 ; - READ+2^XLFNSLK: 144ms
 ; - CGTM+2^%ZISTCP: 249ms
 QUIT
 ;
T2 ; @TEST POST page no TLS
 N PAYLOAD
 N RAND S RAND=$R(123412341324)
 S PAYLOAD(1)="KBANTEST ; VEN/SMH - Test routine for Sam ;"_RAND
 S PAYLOAD(2)=" QUIT"
 N R,% S %=$$POST1(.R,"thebes.smh101.com",80,"r/KBANTEST",PAYLOAD(1)_$C(13,10)_PAYLOAD(2))
 N R,% S %=$$GET1(.R,"thebes.smh101.com",80,"r/KBANTEST")
 D CHKTF^%ut(%[RAND)
 QUIT
 ;
T3 ; @TEST GET page w/ TLS
 N R,% S %=$$GET1(.R,"thebes.smh101.com",443,"r/DIC",1)
 D CHKTF^%ut(%["DIC")
 QUIT
 ;
T4 ; @TEST POST page w/ TLS
 N PAYLOAD
 N RAND S RAND=$R(123412341324)
 S PAYLOAD(1)="KBANTEST ; VEN/SMH - Test routine for Sam ;"_RAND
 S PAYLOAD(2)=" QUIT"
 N R,% S %=$$POST1(.R,"thebes.smh101.com",443,"r/KBANTEST",PAYLOAD(1)_$C(13,10)_PAYLOAD(2),1)
 N R,% S %=$$GET1(.R,"thebes.smh101.com",443,"r/KBANTEST",1)
 D CHKTF^%ut(%[RAND)
 QUIT
 ;
TEST D EN^%ut($T(+0),2) quit  ; Unit Tests
TGET ; @TEST Test Get
 b
 N RTN,H,RET S RET=$$GET1(.RTN,"httpbin.org,443,"/stream/20",1)
 N CNT S CNT=0
 N I F I=0:0 S I=$O(RTN(I)) Q:'I  S CNT=CNT+1
 D CHKTF^%ut(CNT=20,"20 lines are supposed to be returned")
 D CHKTF^%ut(H("STATUS")=200,"Status is supposed to be 200")
 D CHKTF^%ut(RET=0,"Return code is supposed to be zero")
 quit
 ;
TPUT ; @TEST Test Put
 N PAYLOAD,RTN,H,RET
 N R S R=$R(123423421234)
 S PAYLOAD(1)="KBANTEST ; VEN/SMH - Test routine for Sam ;"_R
 S PAYLOAD(2)=" QUIT"
 S RET=$$%(.RTN,"PUT","https://httpbin.org/put",.PAYLOAD,"application/text",5,.H)
 ;
 N OK S OK=0
 N I F I=0:0 S I=$O(RTN(I)) Q:'I  I RTN(I)["data",RTN(I)[R S OK=1
 D CHKTF^%ut(RET=0,"Return code is supposed to be zero")
 D CHKTF^%ut(H("STATUS")=200,"Status is supposed to be 200")
 D CHKTF^%ut(OK,"Couldn't retried the putted string back")
 QUIT
 ;
TESTCRT ; Unit Test with Client Certificate
 N OPTIONS
 ;S OPTIONS("cert")="/home/sam/client.pem"
 ;S OPTIONS("key")="/home/sam/client.key"
 ;S OPTIONS("password")="xxxxxxxxxxx"
 S OPTIONS("cert")="/home/sam/client-nopass.pem"
 S OPTIONS("key")="/home/sam/client-nopass.key"
 N RTN N % S %=$$%(.RTN,"GET","https://green-sheet.smh101.com/",,,,,.OPTIONS)
 ZWRITE RTN
 I @$Q(RTN)'["DOCTYPE" W "FAIL FAIL FAIL",!
 W "Exit code: ",%,!
 QUIT
 ;
TESTH ; @TEST Unit Test with headers
 N OPTIONS
 S OPTIONS("header",1)="DNT: 1"
 N RTN N % S %=$$%(.RTN,"GET","https://httpbin.org/headers",,,,,.OPTIONS)
 N OK S OK=0
 N I F I=0:0 S I=$O(RTN(I)) Q:'I  I $$UP(RTN(I))["DNT" S OK=1
 D CHKTF^%ut(%=0,"Return code is supposed to be zero")
 D CHKTF^%ut(OK,"Couldn't get the sent header back")
 QUIT
 ;
TESTF ; @TEST Unit Test with Form
 N XML,H
 S XML(1)="<xml>"
 S XML(2)="<Book>Book 1</Book>"
 S XML(3)="<Book>Book 2</Book>"
 S XML(4)="<Book>Book 3</Book>"
 S XML(5)="</xml>"
 S OPTIONS("form")="filename=test1234.xml;type=application/xml"
 N RTN N % S %=$$%(.RTN,"POST","http://httpbin.org/post",.XML,"",,.H,.OPTIONS)
 N I F I=0:0 S I=$O(RTN(I)) Q:'I  I RTN(I)["multipart/form-data" S OK=1
 D CHKTF^%ut(%=0,"Return code is supposed to be zero")
 D CHKTF^%ut(OK,"Couldn't get the form back")
 QUIT

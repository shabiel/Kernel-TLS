XTHC ;HCIOFO/SG - HTTP 1.0 CLIENT ;2016-05-25  8:46 AM
 ;;7.3;TOOLKIT;**123**;Apr 25, 1995;Build 4
 ;
 ; API ENTRY POINTS ---- DESCRIPTIONS
 ;
 ;   $$GETURL^XTHC10     Gets the data from the provided URL
 ;
 ;       DEMO^XTHCDEM    Demonstartion entry point
 ;
 ;   $$ENCODE^XTHCURL    Encodes the string
 ;  $$MAKEURL^XTHCURL    Creates a URL from components
 ; $$PARSEURL^XTHCURL    Parses the URL into components
 ; $$NORMPATH^XTHCURL    Returns "normalized" path
 ;
 ;   $$DECODE^XTHCUTL    Decodes one string replacing
 ;                       &lt; <, &gt; >, &amp; &, &nbsp; " ".
 ;
 ; INTERNAL TOOLS ------ DESCRIPTIONS
 ;
 ;  $$RECEIVE^XTHC10A    Reads the HTTP response
 ;  $$REQUEST^XTHC10A    Sends the HTTP request
 ;
 Q
 ;
TEST D EN^%ut($T(+0),3) QUIT
 ;
TGET ; @TEST GET via TLS
 N SSS,XXX
 ; N RTN,H,RET S RET=$$%(.RTN,"GET","https://httpbin.org/stream/20",,"application/text",5,.H)
 N STATUS S STATUS=$$GETURL^XTHC10("https://httpbin.org/stream/20",1,$NA(SSS),.XXX)
 D CHKTF^%ut(+STATUS=200)
 N CNT S CNT=0
 N I F I=0:0 S I=$O(SSS(I)) Q:'I  I SSS(I)]"" S CNT=CNT+1
 D CHKTF^%ut(CNT=20)
 QUIT
 ;
TPOST ; @TEST Test Post
 N PAYLOAD,RTN,H,RET
 N R S R=$R(123423421234)
 S PAYLOAD(1)="KBANTEST ; VEN/SMH - Test routine for Sam ;"_R
 S PAYLOAD(2)=" QUIT"
 N STATUS S STATUS=$$GETURL^XTHC10("https://httpbin.org/post",1,$NA(RTN),.H,$NA(PAYLOAD))
 D CHKTF^%ut(+STATUS=200)
 N DATALINE N I F I=0:0 S I=$O(RTN(I)) Q:'I  I RTN(I)["""data""" S DATALINE=RTN(I)
 D CHKTF^%ut($G(DATALINE)[R)
 QUIT
 ;
TESTH ; @TEST Unit Test with headers
 N RTN
 N HEADER
 S HEADER="DNT: 1"
 N STATUS S STATUS=$$GETURL^XTHC10("https://httpbin.org/headers",1,$NA(RTN),.HEADER)
 N OK S OK=0
 N I F I=0:0 S I=$O(RTN(I)) Q:'I  I RTN(I)["DNT" S OK=1
 D CHKTF^%ut(+STATUS=200,"Status code is supposed to be 200")
 D CHKTF^%ut(OK,"Couldn't get the sent header back")
 QUIT
 ;
TESTF ; #TEST Unit Test with Form --needs work!!!
 N XML,H
 S XML(1)="<xml>"
 S XML(2)="<Book>Book 1</Book>"
 S XML(3)="<Book>Book 2</Book>"
 S XML(4)="<Book>Book 3</Book>"
 S XML(5)="</xml>"
 S OPTIONS("form")="filename=test1234.xml;type=application/xml"
 N RTN N % S %=$$%(.RTN,"POST","http://httpbin.org/post",.XML,"",,.H,.OPTIONS)
 N STATUS S STATUS=$$GETURL^XTHC10("https://httpbin.org/post",1,$NA(RTN),.H,$NA(PAYLOAD))
 N I F I=0:0 S I=$O(RTN(I)) Q:'I  I RTN(I)["multipart/form-data" S OK=1
 D CHKTF^%ut(%=0,"Return code is supposed to be zero")
 D CHKTF^%ut(OK,"Couldn't get the form back")
 QUIT

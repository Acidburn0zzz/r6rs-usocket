#!r6rs
(import (rnrs)
	(usocket)
	(srfi :64))

(define service "10000")
(define (socket-shutdown&close s)
  (usocket-shutdown! s *usocket:shutdown-read&write*)
  (usocket-close! s))

(test-begin "TCP socket")

(let ((s (make-tcp-client-usocket "localhost" service)))
  (test-assert "usocket?" (usocket? s))
  (test-assert "client-usocket?" (client-usocket? s))
  (let ((in (transcoded-port (client-usocket-input-port s)
			     (native-transcoder)))
	(out (transcoded-port (client-usocket-output-port s)
			      (native-transcoder))))
    (put-string out "hi\n")
    (flush-output-port out)
    (test-equal "Receive" "hi" (get-string-n in 2))
    (do ((i 0 (+ i 1))) ((= i 5))
      (put-string out "hi\n")
      (flush-output-port out)
      (test-equal (string-append "Part receive 1 - " (number->string i))
		  #\h (get-char in))
      (test-equal (string-append "Part receive 2 - " (number->string i))
		  #\i (get-char in)))

    (put-string out "nomore")
    (flush-output-port out)
    (socket-shutdown&close s)))

(let ((s (make-tcp-client-usocket "localhost" service)))
  (define utf8* string->utf8)
  (let ((in (client-usocket-input-port s))
	(out (client-usocket-output-port s)))
    (put-bytevector out (utf8* "hi\n"))
    (flush-output-port out)
    (test-equal "Receive" (utf8* "hi") (get-bytevector-n in 2))
    (do ((i 0 (+ i 1))) ((= i 5))
      (put-bytevector out (utf8* "hello\n"))
      (flush-output-port out)
      (test-equal (string-append "Part receive 1 - " (number->string i))
		  (utf8* "he") (get-bytevector-n in 2))
      (test-equal (string-append "Part receive 3 - " (number->string i))
		  (char->integer #\l) (get-u8 in))
      (test-equal (string-append "Part receive 4 - " (number->string i))
		  (char->integer #\l) (get-u8 in))
      (test-equal (string-append "Part receive 5 - " (number->string i))
		  (char->integer #\o) (get-u8 in)))

    (put-bytevector out (utf8* "exit"))
    (flush-output-port out)
    (socket-shutdown&close s)))

(test-end)

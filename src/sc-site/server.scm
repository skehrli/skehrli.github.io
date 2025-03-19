(define-module (sc-site server)
  #:use-module (fibers)
  #:use-module (fibers web server))

(define server-port
  (string->number (or (getenv "PORT")
                      "8080")))

(define-public (start-server)
  (format #t "Listening on http://localhost:~a\n" server-port)
  (run-server (lambda (request body)
                (values '((content-type . (text/plain)))
                        "Hello World!"))
              #:port server-port))

(define-module (sc-site server)
  #:use-module (fibers)
  #:use-module (fibers web server))

(define-public (start-server)
  (display "Listening on http://localhost:8080\n")
  (run-server (lambda (request body)
                (values '((content-type . (text/plain)))
                                          "Hello World!"))))

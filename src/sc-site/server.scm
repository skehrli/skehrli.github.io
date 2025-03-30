(define-module (sc-site server)
  #:use-module (ice-9 match)
  #:use-module (web uri)
  #:use-module (web request)
  #:use-module (web response)
  #:use-module (fibers)
  #:use-module (fibers web server))

(define server-port
  (string->number (or (getenv "PORT")
                      "8080")))

(define-public (start-server)
  (format #t "Listening on port ~a!\n" server-port)
  (run-server (lambda (request body)
                (match (uri-path (request-uri request))
                  ("/hello"
                   (values '((content-type . (text/plain)))
                           "Hello World!"))
                  (_ (values (build-response #:code 404)
                             "Not Found"))))
              #:port server-port))

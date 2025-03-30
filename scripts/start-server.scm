#!/usr/bin/env -S guile -e main -L src/ -s
!#

(use-modules (sc-site server)
             (system repl server))

(define (main args)
  ;; Start a REPL server if requested
  (let ((repl-port (getenv "REPL_PORT")))
    (when repl-port
      (format #t "Starting REPL server on port ~a...\n" repl-port)
      (spawn-server
       (make-tcp-server-socket
        #:port (string->number repl-port)))))

  ;; Start the server
  (start-server))

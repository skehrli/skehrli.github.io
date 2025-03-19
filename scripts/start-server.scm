#!/usr/bin/env -S guile --listen -e main -L src/ -s
!#

(use-modules (sc-site server))

(define (main args)
  (start-server))

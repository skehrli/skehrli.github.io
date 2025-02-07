(use-modules (htmlprag)
             (ice-9 match)
             (haunt post)
             (haunt site)
             (haunt reader)
             (haunt publisher)
             (haunt builder assets)
             (haunt builder flat-pages))

;; Launch Emacs to export Org files
;; (run-command "emacs" "-Q"
;;              "--batch" "-l" "./publish.el"
;;              "--funcall" "dw/publish")

(define (read-html-post port)
  (values (read-metadata-headers port)
          (match (html->shtml port)
            (('*TOP* sxml ...) sxml))))

(define better-html-reader
  (make-reader (make-file-extension-matcher "html")
               (lambda (file)
                 (call-with-input-file file read-html-post))))

(define (site-template site title body)
  `(html
    (head)
    (body
     ,@body)))

(site #:title "System Crafters"
      #:domain "systemcrafters.net"
      #:build-directory "public"
      #:default-metadata
      '((author . "David Wilson")
        (email . "david@systemcrafters.net")
        (index . "true"))
      #:readers (list better-html-reader)
      #:builders (list (flat-pages "org-output" #:template site-template)
                       ;; (blog)
                       ;; (atom-feed)
                       (static-directory "assets")))

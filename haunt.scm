(use-modules (htmlprag)
             (ice-9 match)
             (haunt post)
             (haunt site)
             (haunt reader)
             (haunt builder assets)
             (haunt builder flat-pages))

(define site-url "http://localhost:8080")

(define (site-header)
  `((header (@ (class "site-header"))
           (div (@ (class "container"))
                (div (@ (class "site-title"))
                     (img (@ (class "logo")
                             (src ,(string-append site-url "/img/sc_logo.png"))
                             (alt "System Crafters")))))
           (div (@ (class "site-masthead"))
                (div (@ (class "container"))
                     (nav (@ (class "nav"))
                          (a (@ (class "nav-link") (href "/")) "Home") " "
                          (a (@ (class "nav-link") (href "/guides/")) "Guides") " "
                          (a (@ (class "nav-link") (href "/courses/")) "Courses") " "
                          (a (@ (class "nav-link") (href "/news/")) "News") " "
                          (a (@ (class "nav-link") (href "/community/")) "Community") " "
                          (a (@ (class "nav-link") (href "https://systemcrafters.store?utm_source=sc-site-nav")) "Store") " "
                          (a (@ (class "nav-link") (href "/how-to-help/")) "How to Help")))))))

(define (site-footer)
  `((footer (@ (class "site-footer"))
            (div (@ (class "container"))
                 (div (@ (class "row"))
                      (div (@ (class "column"))
                           (div (@ (class "site-footer-line"))
                                (a (@ (href ,(string-append site-url "/privacy-policy/"))) "Privacy Policy")
                                " · "
                                (a (@ (href ,(string-append site-url "/credits/"))) "Credits")
                                " · "
                                (a (@ (href ,(string-append site-url "/rss/"))) "RSS Feeds")
                                " · "
                                (a (@ (rel "me") (href "https://fosstodon.org/@daviwil")) "Fediverse"))
                           (div (@ (class "site-footer-line"))
                                "© 2021-2024 · System Crafters LLC"))
                      (div (@ (class "column align-right"))
                           (p (a (@ (href "https://codeberg.org/SystemCrafters/systemcrafters.net"))
                                 (img (@ (src ,(string-append site-url "/img/codeberg.png"))
                                         (style "width: 120px")
                                         (alt "Contribute on Codeberg")))))))))))


(define* (generate-page title
                        content
                        #:key
                        publish-date
                        head-extra
                        pre-content
                        exclude-header
                        exclude-footer)
  `((doctype "html")
    (head
     (meta (@ (charset "utf-8")))
     (meta (@ (author "System Crafters - David Wilson")))
     (meta (@ (name "viewport")
              (content "width=device-width, initial-scale=1, shrink-to-fit=no")))
     (link (@ (rel "icon") (type "image/png") (href "/img/favicon.png")))
     (link (@ (rel "alternative")
              (type "application/rss+xml")
              (title "System Crafters News")
              (href ,(string-append site-url "/rss/news.xml"))))
     (link (@ (rel "stylesheet") (href ,(string-append site-url "/css/code.css"))))
     (link (@ (rel "stylesheet") (href ,(string-append site-url "/css/site.css"))))
     (script (@ (defer "defer")
                (data-domain "systemcrafters.net")
                (src "https://plausible.io/js/plausible.js"))
             ;; Empty string to cause a closing </script> tag
             "")
     (title ,(string-append title " - System Crafters")))
    (body ,@(if (not exclude-header)
                (site-header)
                '())
                                        ;,(embed-list-form)
          ,@content
          ,@(if (not exclude-footer)
                (site-footer)
                '()))))

;; Launch Emacs to export Org files
;; (system* "emacs" "-Q"
;;          "--batch" "-l" "./publish.el"
;;          "--funcall" "dw/publish")

(define (read-html-post port)
  (values (read-metadata-headers port)
          (match (html->shtml port)
            (('*TOP* sxml ...) sxml))))

(define better-html-reader
  (make-reader (make-file-extension-matcher "html")
               (lambda (file)
                 (call-with-input-file file read-html-post))))

(define (site-template site metadata body)
  (generate-page (assq-ref metadata 'title) body))

(site #:title "System Crafters"
      #:domain "systemcrafters.net"
      #:build-directory "public"
      #:default-metadata
      '((author . "David Wilson")
        (email . "david@systemcrafters.net"))
      #:readers (list better-html-reader)
      #:builders (list (flat-pages "org-output" #:template site-template)
                       ;; (blog)
                       ;; (atom-feed)
                       (static-directory "assets" ".")))

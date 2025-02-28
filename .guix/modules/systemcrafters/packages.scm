(define-module (systemcrafters packages)
  #:use-module (guix packages)
  #:use-module (guix licenses)
  #:use-module (guix git)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system guile)
  #:use-module (gnu packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages guile-xyz)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (gnu packages rsync)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages version-control))

(define vcs-file?
  ;; Return true if the given file is under version control.  The
  ;; nested `dirname` calls *must* correspond to the relative path in
  ;; the `local-file` expression below!
  (or (git-predicate (dirname
                      (dirname
                       (dirname
                        (current-source-directory)))))
      (const #t)))

(define haunt-latest
  (let ((commit "8b4b14dfa80582632aa74ac1f34c7c428f0eb423"))
    (package
      (inherit haunt)
      (version (string-append "0.3.1+" commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://git.dthompson.us/haunt.git")
                      (commit commit)))
                (sha256
                 (base32
                  "1rhffhzg4ljjbsbijns4gg1cibvdiw2gcv1pmmd94gcmigh60g1m"))))
      (native-inputs
       (list automake autoconf pkg-config texinfo))
      (inputs
       (list rsync guile-3.0-latest)))))

(define-public systemcrafters-site
  (package
    (name "systemcrafters-site")
    (version "0.0.1")
    (source (local-file "../../.." "systemcrafters-site-checkout"
                        #:recursive? #t
                        #:select? vcs-file?))
    (build-system guile-build-system)
    (arguments
     (list #:source-directory "./src"
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'fix-emacs-invoke
                 (lambda* (#:key inputs #:allow-other-keys)
                   (substitute* "haunt.scm"
                     (("system* \"emacs\"")
                      (format #f
                              "system* \"~a/bin/emacs\""
                              (assoc-ref inputs "emacs-no-x-toolkit"))))))

               (add-after 'build 'generate-static
                 (lambda* (#:key inputs outputs #:allow-other-keys)
                   (zero? (system* #$(file-append haunt-latest "/bin/haunt") "build")))))))
    (native-inputs
     (list guile-3.0
           emacs-no-x-toolkit))
    (inputs
     (list git
           haunt-latest))
    (propagated-inputs
     (list guile-lib
           emacs-esxml
           emacs-htmlize
           guile-fibers
           guile-sqlite3
           guile-json-3))
    (synopsis "The official System Crafters website.")
    (description "A hybrid static/dynamic website written in Guile Scheme.")
    (home-page "https://systemcrafters.net")
    (license gpl3+)))

;; Return the site package so that this file can be used as guix.scm
systemcrafters-site

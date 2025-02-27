(define-module (systemcrafters packages)
  #:use-modules (guix packages)
  #:use-modules (guix licenses)
  #:use-modules (guix git)
  #:use-modules (guix git-download)
  #:use-modules (guix build-system gnu)
  #:use-modules (guix build-system guile)
  #:use-modules (gnu packages)
  #:use-modules (gnu packages autotools)
  #:use-modules (gnu packages base)
  #:use-modules (gnu packages guile)
  #:use-modules (gnu packages guile-xyz)
  #:use-modules (gnu packages pkg-config)
  #:use-modules (gnu packages emacs)
  #:use-modules (gnu packages emacs-xyz)
  #:use-modules (gnu packages rsync)
  #:use-modules (gnu packages texinfo)
  #:use-modules (gnu packages version-control))

(define vcs-file?
  ;; Return true if the given file is under version control.
  (or (git-predicate (dirname (dirname (current-source-directory))))
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
    (source (local-file "../.." "systemcrafters-site-checkout"
                        #:recursive? #t
                        #:select? vcs-file?))
    (build-system guile-build-system)
    (arguments
     '(#:source-directory "./src"))
    ;; '(#:phases
    ;;   (modify-phases %standard-phases
    ;;     (add-after 'unpack 'bootstrap
    ;;       (lambda _ (zero? (system* "sh" "bootstrap")))))))
    (native-inputs (list guile-3.0))
    (inputs (list git
                  guile-lib
                  guile-fibers
                  guile-sqlite3
                  guile-json-3
                  haunt-latest
                  emacs-no-x-toolkit))
    (synopsis "The official System Crafters website.")
    (description "A hybrid static/dynamic website written in Guile Scheme.")
    (home-page "https://systemcrafters.net")
    (license gpl3+)))

;; Return the site package so that this file can be used as guix.scm
systemcrafters-site

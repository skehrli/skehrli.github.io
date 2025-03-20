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
  #:use-module (gnu packages bash)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages guile-xyz)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (gnu packages rsync)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages version-control)
  #:use-module (webframe packages))

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

(define-public systemcrafters.net
  (package
    (name "systemcrafters.net")
    (version "2025.03.19")
    (source (local-file "../../.." "systemcrafters-site-checkout"
                        #:recursive? #t
                        #:select? vcs-file?))
    (build-system guile-build-system)
    (arguments
     '(#:source-directory "./src"
       #:modules
       ((guix build guile-build-system)
        (guix build utils)
        (srfi srfi-26))
       #:phases
       (modify-phases %standard-phases
         (add-after 'build 'place-bin-files
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let ((bin (string-append (assoc-ref outputs "out")
                                       "/bin")))
               (install-file "scripts/start-server.scm" bin)
               (substitute* (string-append bin "/start-server.scm")
                 (("/usr/bin/env -S guile ")
                  (string-append (assoc-ref inputs "guile") "/bin/guile \\\n"))))))

         (add-after 'place-bin-files 'wrap-program
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (bin (string-append out "/bin"))
                    (deps (map (cut assoc-ref inputs <>)
                               '("guile-lib" "guile-json" "guile-sqlite3"
                                 "guile-fibers" "guile-webframe")))
                    (version (target-guile-effective-version))
                    (scm (string-append "/share/guile/site/" version))
                    (go (string-append "/lib/guile/" version
                                       "/site-ccache"))
                    (make-load-wrapper (lambda (file)
                                         (wrap-program (string-append bin "/" file)
                                           #:sh (which "sh")
                                           `("GUILE_LOAD_PATH" prefix
                                             (,(string-append out scm)
                                              ,@(map (cut string-append <> scm) deps)))
                                           `("GUILE_LOAD_COMPILED_PATH" prefix
                                             (,(string-append out go)
                                              ,@(map (cut string-append <> go) deps)))))))
               (make-load-wrapper "start-server.scm")
               #t)))

         (add-after 'unpack 'fix-build-script
           (lambda* (#:key inputs #:allow-other-keys)
             ;; Fix the Emacs path in the Haunt script
             (substitute* "haunt.scm"
               (("system* \"emacs\"")
                (format #f
                        "system* \"~a/bin/emacs\""
                        (assoc-ref inputs "emacs-no-x-toolkit"))))

             ;; Create a script that we can wrap
             (with-output-to-file "build.sh"
               (lambda ()
                 (display
                  (string-append
                   "#!" (which "sh") "\n"
                   (assoc-ref inputs "haunt") "/bin/haunt build\n"))))

             ;; Make the script executable
             (chmod "build.sh" #o755)

             ;; Wrap the build script with the correct EMACSLOADPATH
             (let* ((find-load-path
                     (lambda (package-name)
                       (find-files (string-append (assoc-ref inputs package-name)
                                                  "/share/emacs/site-lisp")
                                   (lambda (path stat)
                                     (eqv? (stat:type stat) 'directory))
                                   #:directories? #t)))
                    (lisp-dirs (append (find-load-path "emacs-esxml")
                                       (find-load-path "emacs-htmlize"))))
               (wrap-program "build.sh"
                 #:sh (which "sh")
                 `("EMACSLOADPATH" suffix ,lisp-dirs)))))

         (add-after 'build 'generate-static-files
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (and (zero? (system* "./build.sh"))
                  (copy-recursively "public"
                                    (string-append
                                     (assoc-ref outputs "out")
                                     "/www"))))))))
    (native-inputs
     (list bash
           guile-3.0
           emacs-no-x-toolkit
           emacs-esxml
           emacs-htmlize))
    (inputs
     (list git
           haunt-latest))
    (propagated-inputs
     (list guile-lib
           guile-fibers
           guile-sqlite3
           guile-json-4
           guile-webframe))
    (synopsis "The official System Crafters website.")
    (description "A hybrid static/dynamic website written in Guile Scheme.")
    (home-page "https://systemcrafters.net")
    (license gpl3+)))

;; Return the site package so that this file can be used as guix.scm
systemcrafters.net

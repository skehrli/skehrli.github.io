(use-modules (guix packages)
             (guix licenses)
             (guix git)
             (guix git-download)
             (guix build-system gnu)
             (guix build-system guile)
             (gnu packages)
             (gnu packages autotools)
             (gnu packages base)
             (gnu packages guile)
             (gnu packages guile-xyz)
             (gnu packages pkg-config)
             (gnu packages emacs)
             (gnu packages emacs-xyz)
             (gnu packages rsync)
             (gnu packages texinfo)
             (gnu packages version-control))

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

(package
  (name "systemcrafters.net")
  (version "0.0.1")
  (source (git-checkout (url (dirname (current-filename)))))
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
  (license gpl3+))

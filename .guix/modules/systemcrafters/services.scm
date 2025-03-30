(define-module (systemcrafters services)
  #:use-module (gnu)
  #:use-module (gnu services configuration)
  #:use-module (guix)
  #:use-module (guix gexp)
  #:use-module (systemcrafters packages)
  #:export (systemcrafters-service-type
            systemcrafters-site-config))

(use-package-modules bash emacs gnupg guile guile-xyz ssh sqlite)
(use-service-modules certbot networking shepherd ssh web)

(define-configuration/no-serialization systemcrafters-site-config
  (domain
   (string "staging.systemcrafters.net")
   "The domain to use for the site.")
  (backend-port
   (integer 8081)
   "The port on which the Guile backend should run.")
  (use-certs?
   (boolean #t)
   "If #t, use Certbot certificates."))

(define (systemcrafters-shepherd-service config)
  (list
   (shepherd-service
    (requirement '(nginx))
    (provision '(sc-site-backend))
    (start #~(make-forkexec-constructor
              (list #$(file-append systemcrafters.net "/bin/start-server.scm"))
              #:log-file "/var/log/systemcrafters/server.log"
              #:environment-variables
              (cons #$(format #f
                              "PORT=~a"
                              (systemcrafters-site-config-backend-port config))
                    (default-environment-variables))))
    (stop #~(make-kill-destructor)))))

(define (systemcrafters-nginx-server config)
  (list (nginx-server-configuration
         (listen (if (systemcrafters-site-config-use-certs? config)
                     '("80" "443 ssl")
                     '("8081")))
         (server-name (list (systemcrafters-site-config-domain config)
                            "systemcrafters.local"))
         (root (file-append systemcrafters.net "/www"))
         (ssl-certificate
          (and (systemcrafters-site-config-use-certs? config)
               (format #f
                       "/etc/letsencrypt/live/~a/fullchain.pem"
                       (systemcrafters-site-config-domain config))))
         (ssl-certificate-key
          (and (systemcrafters-site-config-use-certs? config)
               (format #f
                       "/etc/letsencrypt/live/~a/privkey.pem"
                       (systemcrafters-site-config-domain config))))
         (locations
          (list
           (nginx-location-configuration
            (uri "/")
            (body '("try_files $uri $uri/ @backend;")))
           (nginx-location-configuration
            (uri "@backend")
            (body `(,(format #f
                             "proxy_pass http://localhost:~a;"
                             (systemcrafters-site-config-backend-port config))
                    ;; Make sure any 404s from the backend get sent to
                    ;; the real 404 page
                    "proxy_intercept_errors on;"
                    "error_page 404 /404.html;"))))))))

(define %nginx-deploy-hook
  (program-file
   "nginx-deploy-hook"
   #~(let ((pid (call-with-input-file "/var/run/nginx/pid" read)))
       (kill pid SIGHUP))))

(define (systemcrafters-certbot-config config)
  (if (systemcrafters-site-config-use-certs? config)
      (list (certificate-configuration
             (domains (list (systemcrafters-site-config-domain config)))
             (deploy-hook %nginx-deploy-hook)))
      '()))

(define systemcrafters-service-type
  (service-type (name 'site)
                (extensions
                 (list (service-extension shepherd-root-service-type
                                          systemcrafters-shepherd-service)
                       (service-extension nginx-service-type
                                          systemcrafters-nginx-server)
                       (service-extension certbot-service-type
                                          systemcrafters-certbot-config)))
                (default-value (systemcrafters-site-config))
                (description "Runs the systemcrafters.net site.")))

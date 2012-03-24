#lang racket/base
(require (planet ryanc/webapi:1))
(provide verbose?
         the-client
         profile-pref-file)

(define verbose? (make-parameter #f))

(define the-client
  (oauth2-client #:id "525446519879.apps.googleusercontent.com"
                 ;; Not actually a secret in "installed application" flow.
                 #:secret "a_7YrZtEX053CyjILcY6MUHe"))

(define profile-pref-file (build-path (find-system-path 'pref-dir) "scriblogify.rktd"))

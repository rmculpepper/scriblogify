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

(define (get-pref sym)
  (get-preference sym (lambda () #f) 'timestamp profile-pref-file))
(define (set-pref sym value)
  (put-preferences (list sym) (list value) #f profile-pref-file))

#|
Profile information, version 0

profile-pref-file has 3 keys:
  'version => 0
  'auth => (list 'oauth2-refresh-token string)
  'profiles => (listof profile)

where profile = (cons name-symbol
                      (list (list 'blogger id-string title-string)
                            (list 'picasa id-string title-string)))
|#

;; get-profile : symbol -> (values oauth2<%> blogger-blog<%> picasa-album<%>/#f)
(define (get-profile profile)
  (define version (get-pref 'version))
  (unless (member version '(0 #f))
    (error 'scriblogify "unknown version: ~s" version))
  (define oauth2
    (match (get-pref 'auth)
      [(list 'oauth2-refresh-token token)
       (oauth2/refresh-token google-auth-server the-client refresh-token)]
      [#f
       (oauth2/request-auth-code/browser google-auth-server the-client (list blogger-scope picasa-scope))]
      [_ (error 'scriblogify "unknown authorization")]))
  (match (get-pref profile)
    [(list blog-info album-info)
     (values oauth2
             (match blog-info
               [(list 'blogger blog-id blog-title)
                (let ([b-user (blogger #:oauth2 oauth2)])
                  (or (send b-user find-child-by-id blog-id)
                      (error 'scriblogify "could not find blog with id ~s" blog-id)))])
             (match album-info
               [(list 'picasa album-id album-title)
                (let ([p-user (picasa #:oauth2 oauth2)])
                  (or (send p-user find-child-by-id album-id)
                      (error 'scriblogify "could not find album with id ~s" album-id)))]
               [#f #f]))]
    [#f (error 'scriblogify "profile not found: ~s" profile)]))

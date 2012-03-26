;; Copyright 2012 Ryan Culpepper
;; Released under the terms of the LGPL version 3 or later.
;; See the file COPYRIGHT for details.

#lang racket/base
(require racket/dict
         racket/match
         racket/class
         racket/file
         (planet ryanc/webapi:1))
(provide verbose?
         the-client
         profile-pref-file
         get-pref
         set-pref
         get-profile)

(define verbose? (make-parameter #f))

(define the-client
  (oauth2-client #:id "525446519879.apps.googleusercontent.com"
                 ;; Not actually a secret in "installed application" flow.
                 #:secret "a_7YrZtEX053CyjILcY6MUHe"))

(define profile-pref-file (build-path (find-system-path 'pref-dir) "scriblogify.rktd"))

(define (get-pref sym)
  (get-preference sym (lambda () #f) 'timestamp profile-pref-file))
(define (set-pref sym value)
  ;; Create with permissions #o600: user rw, inaccessible to group and other
  (unless (file-exists? profile-pref-file)
    (call-with-output-file profile-pref-file (lambda (out) (write '() out)))
    (file-or-directory-permissions profile-pref-file #o600))
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
  (define profiles (or (get-pref 'profiles) null))
  (define-values (get-blog get-album)
    (match (dict-ref profiles profile)
      [(list blog-info album-info)
       (values (match blog-info
                 [(list 'blogger blog-id blog-title)
                  (lambda (oauth2)
                    (let ([b-user (blogger #:oauth2 oauth2)])
                      (or (send b-user find-child-by-id blog-id)
                          (error 'scriblogify "could not find blog with id ~s" blog-id))))])
               (match album-info
                 [(list 'picasa album-id album-title)
                  (lambda (oauth2)
                    (let ([p-user (picasa #:oauth2 oauth2)])
                      (or (send p-user find-child-by-id album-id)
                          (error 'scriblogify "could not find album with id ~s" album-id))))]
                 [#f #f]))]
      [#f (error 'scriblogify "profile not found: ~s" profile)]))
  (define oauth2
    (match (get-pref 'auth)
      [(list 'oauth2-refresh-token refresh-token)
       (oauth2/refresh-token google-auth-server the-client refresh-token)]
      [#f #f]
      [_ (error 'scriblogify "unknown authorization")]))
  (when oauth2 (send oauth2 validate!)) ;; set scopes
  (let ([oauth2*
         (cond [(and oauth2 (or (not get-album) (member picasa-scope (send oauth2 get-scopes))))
                oauth2]
               [else
                (oauth2/request-auth-code/browser google-auth-server the-client
                                                  (if get-album
                                                      (list blogger-scope picasa-scope)
                                                      (list blogger-scope)))])])
    (values oauth2*
            (get-blog oauth2*)
            (and get-album (get-album oauth2*)))))

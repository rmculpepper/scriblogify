;; Copyright 2012-2013 Ryan Culpepper
;; Released under the terms of the LGPL version 3 or later.
;; See the file COPYRIGHT for details.

#lang racket/base
(require racket/match
         racket/class
         racket/file
         racket/dict
         racket/pretty
         "private/util.rkt"
         mzlib/etc
         web-server/dispatch
         web-server/servlet-env
         web-server/servlet/web
         web-server/servlet/web-cells
         web-server/http
         web-server/http/bindings
         web-server/http/xexpr
         web-server/formlets
         (only-in web-server/formlets/lib pure)
         webapi)
(provide main)

(define auth-wc (make-web-cell #f))

(define-values (setup-dispatch _setup-url)
  (dispatch-rules
   [("setup" "start") start-setup]
   [("setup" "oauth2") continue-oauth2]))

(define (start-setup req)
  (match (get-pref 'auth)
    [(list 'oauth2-refresh-token refresh-token)
     (let ([oauth2 (oauth2/refresh-token google-auth-server the-client refresh-token)])
       (send oauth2 validate!) ;; to update scopes
       (web-cell-shadow auth-wc oauth2))]
    [_ (void)])
  (welcome-page))

(define (continue-oauth2 req)
  (let ([bindings (request-bindings/raw req)])
    (cond [(bindings-assq #"code" bindings)
           => (lambda (code-b)
                (let* ([auth-code (bytes->string/utf-8 (binding:form-value code-b))]
                       [oauth2 (oauth2/auth-code google-auth-server the-client auth-code
                                                 #:redirect-uri "http://localhost:8000/setup/oauth2")])
                  (send oauth2 validate!) ;; to update scopes
                  (web-cell-shadow auth-wc oauth2)
                  (redirect/get)
                  (manage-page)))]
          [(bindings-assq #"error" bindings)
           => (lambda (err-b)
                (let ([err (bytes->string/utf-8 (binding:form-value err-b))])
                  (error-page
                   `(h2 "Authorization failed")
                   `(p ,err))))]
          [else (error-page
                 `(h2 "Internal error")
                 `(p "Bad response from authorization server."))])))

;; ----

(define (welcome-page)
  (define oauth2 (web-cell-ref auth-wc))
  (when oauth2 (send oauth2 validate!))
  (send/suspend/dispatch
   (lambda (make-url)
     (wrap-page
      `(div
        (h2 "Setup Overview")
        (p "Scriblogify is a tool for creating blog posts from Scribble documents.")
        (p "You can use Scriblogify purely as a local document processor, but you can also "
           "use it to automatically post blog entries and upload embedded images "
           "to image hosting services. (Currently only Blogger and Picasa Web Albums "
           "are supported.)")
        (p "A " (em "profile") " consists of a blog" mdash "where to upload posts" mdash
           "together with, optionally, a web album" mdash
           "where to store images that are part of a post.")
        (p (em "Warning: Use Scriblogify at your own risk!"))
        ,@(cond [oauth2
                 `((h3 "Use existing authorization")
                   (p "You have already authorized Scriblogify to access your Blogger "
                      ,(cond [(member picasa-scope (send oauth2 get-scopes))
                              "and Picasa Web Albums accounts."]
                             [else
                              "account only."]))
                   (p (a ([href ,(make-url (lambda _ (manage-page)))])
                         "Continue to profile management page.")))]
                [else '()])
        ,@(cond [oauth2
                 `((h3 "Change authorization"))]
                [else
                 `((h3 "Grant authorization")
                   (p "To create profiles, you must first authorize Scriblogify to access and "
                      "modify your Blogger and (optionally) Picasa Web Albums accounts."))])
        ,@(let ([auth-url
                 (lambda (include-picasa?)
                   (send google-auth-server get-auth-request-url
                         #:client the-client
                         #:scopes (if include-picasa?
                                      (list blogger-scope picasa-scope)
                                      (list blogger-scope))
                         #:redirect-uri "http://localhost:8000/setup/oauth2"))])
            `((p (a ([href ,(auth-url #t)])
                    "Authorize access to your Blogger and Picasa Web Albums accounts."))
              (p (a ([href ,(auth-url #f)])
                    "Authorize access to your Blogger account only."))))
        ,@(cond [oauth2
                 `((p (a ([href ,(make-url
                                  (lambda _
                                    (send oauth2 revoke!)
                                    (web-cell-shadow auth-wc #f)
                                    (set-pref 'auth #f)
                                    (redirect/get)
                                    (welcome-page)))])
                         "Revoke access to your accounts.")))]
                [else '()])
        (h3 "Done")
        (p (a ([href "/quit"]) "Quit the setup servlet."))
        )))))

(define (manage-page)
  (define oauth2 (web-cell-ref auth-wc))
  (define profiles (or (get-pref 'profiles) null))
  (send/suspend/dispatch
   (lambda (make-url)
     (wrap-page
      `(div
        (h2 "Manage Profiles")
        (p "Your setup information is stored at:")
        (pre ,(path->string profile-pref-file))
        (div (h3 "Authorization")
             (p "You may save an authorization token in your setup information file. "
                "The token will be used automatically when you run Scriblogify. "
                "If you do not save your authorization token, you will be prompted again for "
                "authorization each time you run Scriblogify.")
             ,@(let ([saved-auth (get-pref 'auth)])
                 (match saved-auth
                   [(list 'oauth2-refresh-token _)
                    `((p "Your authorization token is currently saved.")
                      (a ([href ,(make-url (lambda _ (set-pref 'auth #f) (redirect/get) (manage-page)))])
                         "Remove the authorization token."))]
                   [#f
                    `((p "No authorization token is currently saved.")
                      (a ([href ,(make-url
                                  (lambda _
                                    (set-pref 'auth `(oauth2-refresh-token ,(send oauth2 get-refresh-token)))
                                    (redirect/get)
                                    (manage-page)))])
                         "Save an authorization token."))]
                   [_
                    `((p "Your setup information file contains an invalid authorization record.")
                      (a ([href ,(make-url (lambda _ (set-pref 'auth #f) (redirect/get) (manage-page)))])
                         "Remove the invalid authorization record."))])))
        (div (h3 "New Profile")
             (p (a ([href ,(make-url (lambda (req) (new-profile-page)))])
                   "Create a new profile.")))
        (div (h3 "Existing Profiles")
             (ul
              ,@(for/list ([(name-sym info) (in-dict profiles)])
                  (let ([name (symbol->string name-sym)])
                    (match info
                      [`((blogger ,blog-id ,blog-title) ,album-info)
                       `(li (em ,name)
                            " (blog: " ,blog-title
                            ,@(match album-info
                                [`(picasa ,album-id ,album-title)
                                 `(", album: " ,album-title)]
                                [#f
                                 `(", no album")])
                            ") "
                            (a ([href ,(make-url
                                        (lambda _
                                          (set-pref 'profiles
                                                    (dict-remove (or (get-pref 'profiles) null)
                                                                 name-sym))
                                          (redirect/get)
                                          (manage-page)))])
                               "[delete]"))])))))
        (div (h3 "Done")
             (p (a ([href "/quit"]) "Quit the setup servlet."))))))))

;; ----

(define (new-profile-page)
  (define oauth2 (web-cell-ref auth-wc))
  (define bu (blogger #:oauth2 oauth2))
  (define pu (and (member picasa-scope (send oauth2 get-scopes)) (picasa #:oauth2 oauth2)))

  (define profile-formlet
    (formlet
     (div ([class "profile_form"])
          (div (div "Choose a name for the new profile:")
               ,(=> input-symbol
                    name))
          (div (div "Choose a blog:")
               ,(=> (select-input (send bu list-blogs)
                                  #:display (lambda (b) (send b get-title)))
                    blog))
          (div ,(if pu
                    `(div "Choose an album:")
                    `(div "Access to Picasa Web Albums not authorized."))
               ,(=> (if pu
                        (select-input (cons #f (send pu list-albums))
                                      #:display (lambda (a)
                                                  (if a
                                                      (send a get-title)
                                                      "(None)")))
                        (pure #f))
                    album))
          (div ([class "profile_form_submit"])
               (input ([type "submit"] [value "Create profile"] [name "submit"]))))
     (list name blog album)))

  (let ([req
         (send/suspend
          (lambda (k-url)
            (wrap-page
             `(div
               (h2 "New Profile")
               (form ([action ,k-url]) ,@(formlet-display profile-formlet))
               ))))])
    (let ([result (formlet-process profile-formlet req)])
      (match result
        [(list name blog album)
         (cond [(equal? (symbol->string name) "")
                (error-page `(p "Invalid profile name: \"" ,(symbol->string name) "\"."))]
               [else
                (set-pref 'profiles
                          (dict-set (or (get-pref 'profiles) null)
                                    name
                                    `((blogger ,(send blog get-id) ,(send blog get-title))
                                      ,(and album `(picasa ,(send album get-id) ,(send album get-title))))))
                (begin (redirect/get) (manage-page))])]))))

(define (error-page . contents)
  (wrap-page
   `(div ,@contents)))

(define (done-page . _)
  (redirect-to "/quit"))

;; ----

(define (wrap-page main)
  (response/xexpr
   `(html (head (title "Scriblogify Setup")
                (link ([rel "stylesheet"] [type "text/css"] [href "/style.css"])))
          (body
           (div ([class "main_body"])
                (h1 "Scriblogify")
                ;;(div (img ([src "/scriblogify-logo.png"] [alt "logo"])))
                ,main)))))

;; ----

(define here (this-expression-source-directory))

(define (main)
  (serve/servlet setup-dispatch
                 #:launch-browser? #t
                 #:quit? #t
                 #:banner? #f
                 #:port 8000
                 #:servlet-path "/setup/start"
                 #:servlet-regexp #rx"^/setup/"
                 #:extra-files-paths (list (build-path here "private" "setup"))))

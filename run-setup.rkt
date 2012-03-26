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
         (planet ryanc/webapi:1))

(define auth-wc (make-web-cell #f))

(define-values (setup-dispatch _setup-url)
  (dispatch-rules
   [("setup" "start") start-setup]
   [("setup" "oauth2") continue-oauth2]))

(define (start-setup req)
  (match (get-pref 'auth)
    [(list 'oauth2-refresh-token refresh-token)
     (web-cell-shadow auth-wc (oauth2/refresh-token google-auth-server the-client refresh-token))
     (manage-page)]
    [#f
     (welcome-page)]
    [other
     (error 'setup "Unknown authorization: ~e" other)]))

(define (continue-oauth2 req)
  (let ([bindings (request-bindings/raw req)])
    (cond [(bindings-assq #"code" bindings)
           => (lambda (code-b)
                (let* ([auth-code (bytes->string/utf-8 (binding:form-value code-b))]
                       [oauth2 (oauth2/auth-code google-auth-server the-client auth-code
                                                 #:redirect-uri "http://localhost:8000/setup/oauth2")])
                  (web-cell-shadow auth-wc oauth2)
                  (set-pref 'auth `(oauth2-refresh-token ,(send oauth2 get-refresh-token)))
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

(define (new-profile-page)
  (define oauth2 (web-cell-ref auth-wc))
  (define bu (blogger #:oauth2 oauth2))
  (define pu (picasa #:oauth2 oauth2))

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
          (div (div "Choose an album:")
               ,(=> (select-input (send pu list-albums)
                                  #:display (lambda (a) (send a get-title)))
                    album))
          (div ([class "profile_form_submit"])
               (input ([type "submit"] [value "Create profile"] [name "submit"]))))
     (list name blog album)))

  #|
  (pretty-print (formlet-display profile-formlet) (current-error-port))
  (newline (current-error-port))
  |#

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
         (set-pref 'profiles
                   (dict-set (or (get-pref 'profiles) null)
                             name
                             `((blogger ,(send blog get-id) ,(send blog get-title))
                               (picasa ,(send album get-id) ,(send album get-title)))))
         (begin (send/suspend redirect-to) (manage-page))]))))

(define (error-page . contents)
  (wrap-page
   `(div ,@contents)))

;; ----

(define (welcome-page)
  (wrap-page
   `(div
     (h2 "Setup Overview")
     (p "Scriblogify is a tool for creating blog posts from Scribble documents.")
     (p "It can be used purely as a local document processor, but it can also "
        "be used to automatically post blog entries and upload embedded images "
        "to image hosting services. (Currently only Blogger and Picasa Web Albums "
        "are supported.)")
     (p "A " (emph "profile") " consists of a blog for uploading posts together with "
        "a web album for uploading images.")
     (p "To create profiles, you must first authorize Scriblogify to access and "
        "modify your Blogger and Picasa Web Albums accounts. Authorization is "
        "handled through your Google account.")
     (p (a ([href
             ,(send google-auth-server get-auth-request-url
                    #:client the-client
                    #:scopes (list blogger-scope picasa-scope)
                    #:redirect-uri "http://localhost:8000/setup/oauth2")])
           "Go to the Google authorization page.")))))

(define (manage-page)
  (define oauth2 (web-cell-ref auth-wc))
  (define profiles (or (get-pref 'profiles) null))
  (send/suspend/dispatch
   (lambda (make-url)
     (wrap-page
      `(div
        (h2 "Manage Profiles")
        (p "Your profile information and authorization tokens are stored at "
           (code ,(path->string profile-pref-file)) ".")
        (div (h3 "New Profile")
             (p (a ([href ,(make-url (lambda (req) (new-profile-page)))])
                   "Create a new profile.")))
        (div (h3 "Existing Profiles")
             (ul
              ,@(for/list ([(name-sym info) (in-dict profiles)])
                  (let ([name (symbol->string name-sym)])
                    (match info
                      [`((blogger ,blog-id ,blog-title)
                         (picasa ,album-id ,album-title))
                       `(li (em ,name)
                            " (blog: " ,blog-title
                            ", album: " ,album-title ")")]))))))))))

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
(serve/servlet setup-dispatch
               #:launch-browser? #t
               #:quit? #t
               #:banner? #f
               #:port 8000
               #:servlet-path "/setup/start"
               #:servlet-regexp #rx"^/setup/"
               #:extra-files-paths (list (build-path here "private" "setup")))

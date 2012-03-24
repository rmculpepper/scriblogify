#lang racket/base
(require racket/file
         racket/path
         racket/cmdline
         racket/match
         racket/dict
         racket/class
         file/sha1
         (planet clements/sxml2:1)
         (planet neil/html-parsing:1)
         (planet neil/html-writing:1)
         (planet ryanc/webapi:1))
(provide (all-defined-out))

(define verbose? (make-parameter #f))

;; ============================================================

;; blogify : path handler<%> -> void
(define (blogify file handler)
  (let-values ([(title contents tag) (get-blog-entry file)])
    (let ([local-images (find-local-images contents)])
      (for ([local-image (in-list local-images)])
        (unless (file-exists? local-image)
          (error 'scriblogify "blog refers to local image that does not exist: ~e" local-image)))
      (let* ([images-map (send handler handle-images tag local-images)]
             [contents (transform contents images-map)])
        (send handler handle-content title contents)))))

;; get-blog-entry : path-string -> string/#f (listof SXML) string/#f
(define (get-blog-entry file)
  (let* ([doc (call-with-input-file file html->xexp)]
         [title ((sxpath "//title/text()") doc)]
         [title (and (pair? title) (car title))]
         [content
          ((sxpath "//div[@class='SAuthorListBox']/following-sibling::node()") doc)]
         [tag ((sxpath "//div/@blogtag/text()") doc)]
         [tag (and (pair? tag) (car tag))])
    (when (verbose?)
      (if tag
          (eprintf "Blog tag is ~s.\n" tag)
          (eprintf "No blog tag.\n")))
    (values title content tag)))

(define (find-local-images doc)
  (filter (lambda (src) (not (path-only src)))
          ((sxpath '(// img @ src *text*)) doc)))

;; transform : SXMLish -> SXMLish
(define (transform doc imgmap)
  ;; replace uses of @(the-jump) with <!--more-->
  ;; note local images
  (pre-post-order doc
                  `((div . ,(lambda elem
                              (let ([rs ((sxpath "self::div[@class='TheJump']") elem)])
                                (cond [(pair? rs)
                                       '(*COMMENT* "more")]
                                      [else elem]))))
                    (img . ,(lambda elem
                              (let* ([attrs (elem-attrs elem)]
                                     [src* (dict-ref attrs 'src #f)]
                                     [src (and src* (car src*))]
                                     [new-src
                                      (cond [(and src (not (path-only src)))
                                             (dict-ref imgmap src
                                                       (lambda ()
                                                         (eprintf "Warning: unmapped local image: ~s\n" src)
                                                         src))]
                                            [else src])])
                                ;; elem
                                (let ([new-elem
                                       ((sxml:modify (list "/@src" 'replace `(src ,new-src))) elem)])
                                  new-elem))))
                    (*text* . ,(lambda (tag str) str))
                    (*default* . ,(lambda elem elem)))))

(define (elem-attrs e)
  (match e
    [(list* _ (cons '@ attrs) _) attrs]
    [_ null]))

;; ============================================================

(define handler<%>
  (interface ()
    handle-images  ;; string/#f (listof string) -> (dict string string)
    handle-content ;; string/#f (listof SXML) -> void
    ))

(define default-handler%
  (class* object% (handler<%>)
    (super-new)

    (define/public (handle-images tag images)
      (for/hash ([img (in-list images)])
        (when (verbose?)
          (eprintf "Found local image: ~s.\n" img))
        (values img img)))

    (define/public (handle-content title content)
      (for-each write-html content))))

(define default-handler (new default-handler%))

;; ============================================================

(define the-client
  (oauth2-client #:id "525446519879.apps.googleusercontent.com"
                 ;; Not actually a secret in "installed application" flow.
                 #:secret "a_7YrZtEX053CyjILcY6MUHe"))

(define profile-pref-file (build-path (find-system-path 'pref-dir) "scriblogify.rktd"))

(define upload-handler%
  (class* object% (handler<%>)
    (init-field profile overwrite?)
    (super-new)

    ;; (list 0 blog-name album-name refresh-token/#f) -- 0 is format version
    (define profile-info (get-preference profile (lambda () #f) 'timestamp profile-pref-file))
    (define-values (blog-name album-name refresh-token)
      (match profile-info
        [(list 0 (? string? blog-name) (? string? album-name) (? string? refresh-token))
         (values blog-name album-name refresh-token)]
        [#f
         (error 'scriblogify "profile not found: ~s" profile)]
        [_
         (error 'scriblogify "internal error: bad profile information")]))

    (define my-oauth2
      (if refresh-token
          (oauth2/refresh-token google-auth-server the-client refresh-token)
          (oauth2/request-auth-code/browser google-auth-server the-client (list blogger-scope picasa-scope))))

    (define b-blog
      (let ([b-user (blogger #:oauth2 my-oauth2)])
        (or (send b-user find-blog blog-name)
            (error 'scriblogify "could not find blog named ~s" blog-name))))

    (define p-album
      (let ([p-user (picasa #:oauth2 my-oauth2)])
        (or (send p-user find-album album-name)
            (error 'get-the-album "could not find album named ~s" album-name))))

    (define/public (handle-images tag images)
      (for/hash ([img-path (in-list images)])
        (let* ([name (file-identifier tag img-path)]
               [img (or (send p-album find-photo name)
                        (begin
                          (when (verbose?)
                            (eprintf "Uploading ~s as ~s.\n" img-path name))
                          (send p-album create-photo img-path name)))]
               [url (send img get-content-link)])
          (values img-path url))))

    (define/private (file-identifier tag path)
      (let ([id (substring (call-with-input-file path sha1) 0 20)])
        (if tag (string-append tag "_" id) id)))

    (define/public (handle-content title content)
      (unless title (error 'scriblogify "no title"))
      (let loop ()
        ;; FIXME: instead of overwrite? flag, new policy: overwrite *draft* posts,
        ;; don't overwrite published posts.
        (let ([post (send b-blog find-post title)])
          (when post
            (cond [overwrite?
                   (when (verbose?) (eprintf "Deleting existing post titled ~s.\n" title))
                   (send post delete)]
                  [else (error 'scriblogify "a post already exists with that title: ~s" title)])
            ;; Ack, bug! Deleting doesn't properly invalidate b-blog info, so we get
            ;; an infinite loop!
            ;;(loop)
            )))
      (when (verbose?) (eprintf "Uploading draft blog post with title ~s.\n" title))
      (void (send b-blog create-html-post title content #:draft? #t)))))

(define (upload-handler profile overwrite?)
  (new upload-handler% (profile profile) (overwrite? overwrite?)))

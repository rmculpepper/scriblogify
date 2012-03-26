#lang racket/base
(require racket/class
         racket/match
         racket/file
         file/sha1
         (planet neil/html-writing:1)
         (planet ryanc/webapi:1)
         "util.rkt")
(provide (all-defined-out))

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
      (for-each write-html content)
      (newline))))

(define default-handler (new default-handler%))

;; ============================================================

(define upload-handler%
  (class* object% (handler<%>)
    (init-field profile overwrite?)
    (super-new)

    (define-values (oauth2 b-blog p-album)
      (get-profile profile))

    (define/public (handle-images tag images)
      (cond [p-album
             (for/hash ([img-path (in-list images)])
               (let* ([name (file-identifier tag img-path)]
                      [img (or (send p-album find-photo name)
                               (begin
                                 (when (verbose?)
                                   (eprintf "Uploading ~s as ~s.\n" img-path name))
                                 (send p-album create-photo img-path name)))]
                      [url (send img get-content-link)])
                 (values img-path url)))]
            [else (hash)]))

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

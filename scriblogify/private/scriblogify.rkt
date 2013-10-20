;; Copyright 2011-2012 Ryan Culpepper
;; Released under the terms of the LGPL version 3 or later.
;; See the file COPYRIGHT for details.

#lang racket/base
(require racket/path
         racket/match
         racket/dict
         racket/class
         (planet clements/sxml2:1)
         (planet neil/html-parsing:1)
         "util.rkt")
(provide (all-defined-out))

;; blogify : path handler<%> -> void
(define (blogify file handler)
  (let-values ([(title contents tag) (get-blog-entry file)])
    (let ([local-images (find-local-images contents)])
      (for ([local-image (in-list local-images)])
        (unless (file-exists? local-image)
          (eprintf "Blog post refers to local image that does not exist: ~e" local-image)))
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
  ;; replace refs to local images with stored images
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

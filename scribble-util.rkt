#lang racket/base
(require scribble/manual
         scribble/racket
         scribble/core
         scribble/html-properties
         scribble/decode
         (for-syntax racket/base))
(provide (except-out (all-defined-out)
                     define-declare-X))

(define (blogsection . preflow)
  (apply section #:style 'unnumbered preflow))

(define (the-jump)
  (paragraph (style "TheJump" '(div))
             null))

(define (blog-unique-tag tag)
  (let ([attrs
         `((style . "display: none")
           (blogtag . ,tag))])
    (paragraph (style #f (list 'div (attributes attrs))) null)))

;; Reference and Guide links

(define Guide '(lib "scribblings/guide/guide.scrbl"))
(define Reference '(lib "scribblings/reference/reference.scrbl"))

(define (tech/guide #:key [key #f] . preflow)
  (apply tech #:doc Guide #:key key preflow))

(define (secref/guide . key)
  (apply secref #:doc Guide key))

(define (tech/reference #:key [key #f] . preflow)
  (apply tech #:doc Reference #:key key preflow))

(define (secref/reference . key)
  (apply secref #:doc Reference key))

;; Formatting

(define-syntax-rule (define-declare-X declare-X formatter)
  (... (define-syntax-rule (declare-X id ...)
         (begin (define-syntax id
                  (make-element-id-transformer
                   (lambda _ #'(formatter (symbol->string 'id)))))
                ...))))

(define-declare-X declare-keyword racketkeywordfont)

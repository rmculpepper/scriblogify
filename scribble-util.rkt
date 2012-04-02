;; Copyright 2011-2012 Ryan Culpepper
;; Released under the terms of the LGPL version 3 or later.
;; See the file COPYRIGHT for details.

#lang racket/base
(require scribble/manual
         scribble/racket
         scribble/core
         scribble/html-properties
         (for-syntax racket/base))
(provide blogsection
         the-jump
         blog-tag)

(define (blogsection . preflow)
  (apply section #:style 'unnumbered preflow))

(define (the-jump)
  (paragraph (style "TheJump" '(div))
             null))

(define (blog-tag tag)
  (let ([attrs
         `((style . "display: none")
           (blogtag . ,tag))])
    (paragraph (style #f (list 'div (attributes attrs))) null)))

;; Copyright 2011-2013 Ryan Culpepper
;; Released under the terms of the LGPL version 3 or later.
;; See the file COPYRIGHT for details.

#lang info

(define name "scriblogify")
(define scribblings '(("scribblings/scriblogify.scrbl" ())))

(define compile-omit-paths '("samples"))

(define raco-commands
  '(("scriblogify"
     (planet ryanc/scriblogify:1/run)
     "proof or upload a Scribble blog post"
     #f)))

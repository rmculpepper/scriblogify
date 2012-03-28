;; Copyright 2011-2012 Ryan Culpepper
;; Released under the terms of the LGPL version 3 or later.
;; See the file COPYRIGHT for details.

#lang setup/infotab

(define name "scriblogify")
(define scribblings '(("scribblings/scriblogify.scrbl" ())))

(define blurb
  '("Scribble your blog."))
(define categories '(io net xml))
(define can-be-loaded-with 'all)
(define primary-file "main.rkt")
(define required-core-version "5.2")
(define repositories '("4.x"))

(define raco-commands
  '(("scriblogify"
     (planet ryanc/scriblogify:1/run)
     "proof or upload a Scribble blog post"
     #f)))

(define release-notes
  '("Initial release."))

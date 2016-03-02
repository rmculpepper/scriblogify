;; Copyright 2013 Ryan Culpepper
;; Released under the terms of the LGPL version 3 or later.
;; See the file COPYRIGHT for details.

#lang info

(define collection 'multi)
(define deps '("base"
               "sxml"
               "webapi"
               "scribble-lib"
               "compatibility-lib"
               "web-server-lib"
               "html-parsing"
               "html-writing"))
(define build-deps '("racket-doc"
                     "scribble-doc"
                     "scribble-lib"))

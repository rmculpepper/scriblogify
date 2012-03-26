#lang racket/base
(require racket/cmdline
         "main.rkt"
         (prefix-in setup: "run-setup.rkt"))

(define (post args)
  (define pre? #f)
  (define build-dir #f)
  (define upload-profile #f)
  (define overwrite? #f)
  (define v? #f)
  (command-line
   #:argv args
   #:once-each
   (("-d" "--dir") build-directory
    "Put temporary files in <build-directory>"
    (set! build-dir build-directory))
   (("-n" "--nightly")
    "Link to nightly build documentation pages"
    (set! pre? #t))
   (("-p" "--profile") profile
    "Upload blog according to <profile>"
    (set! upload-profile (string->symbol profile)))
   (("-f" "--force")
    "Overwrite existing blog post with same title"
    (set! overwrite? #t))
   (("-v" "--verbose")
    "Verbose mode"
    (set! v? #t))
   ("--setup"
    "Run setup servlet (all other flags are ignored)"
    (begin (setup:main)
           (exit 0)))
   #:args (file)
   (scriblogify file
                #:profile upload-profile
                #:link-to-pre? pre?
                #:overwrite? overwrite?
                #:verbose? v?
                #:temp-dir build-dir)))

;; ----

(post (vector->list (current-command-line-arguments)))

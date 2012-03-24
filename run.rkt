#lang racket/base
(require racket/cmdline
         "main.rkt")

(define (run)
  (define pre? #f)
  (define build-dir #f)
  (define upload-profile #f)
  (define overwrite? #f)
  (define v? #f)
  (command-line
   ;; #:argv args
   #:once-each
   (("-p" "--pre")
    "Link to nightly build documentation pages"
    (set! pre? #t))
   (("-d" "--dir") build-directory
    "Put temporary files in <build-directory>"
    (set! build-dir build-directory))
   (("-u" "--upload") profile
    "Upload blog according to <profile>"
    (set! upload-profile (string->symbol profile)))
   (("-f" "--force")
    "Overwrite existing blog post with same title"
    (set! overwrite? #t))
   (("-v" "--verbose")
    "Verbose mode"
    (set! v? #t))
   #:args (file)
   (scriblogify file
                #:profile upload-profile
                #:link-to-pre? pre?
                #:overwrite? overwrite?
                #:verbose? v?
                #:temp-dir build-dir)))

(run)

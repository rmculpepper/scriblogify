#lang racket/base
(require racket/command-line
         "main.rkt")

(define (run)
  (define docs-base-url "http://doc.racket-lang.org/")
  (define build-dir #f)
  (define upload-profile #f)
  (define overwrite? #f)
  (command-line
   ;; #:argv args
   #:once-each
   (("-p" "--pre")
    "Link to nightly build documentation pages"
    (eprintf "Using nightly build documentation pages\n")
    (set! docs-base-url "http://pre.racket-lang.org/docs/html/"))
   (("-d" "--dir") build-directory
    "Put temporary files in <build-directory>"
    (set! build-dir build-directory))
   (("-u" "--upload") profile
    "Upload blog to Blogger, images to PicasaWeb"
    (set! upload-profile (string->symbol profile)))
   (("-f" "--force")
    "Overwrite existing blog post with same title"
    (set! overwrite? #t))
   (("-v" "--verbose")
    "Verbose mode"
    (verbose? #t))
   #:args (file)
   (unless build-dir
     (set! build-dir (path->string (make-temporary-file "scriblogify~a" 'directory))))
   (when (verbose?)
     (eprintf "Putting temporary files in ~s.\n" build-dir))
   (parameterize ((current-command-line-arguments
                   (vector "--quiet"
                           "--html"
                           "--dest" build-dir
                           "--dest-name" "out.html"
                           "--redirect-main" docs-base-url
                           "++xref-in" "setup/xref" "load-collections-xref"
                           file)))
     (dynamic-require 'scribble/run #f))
   (parameterize ((current-directory build-dir))
     (blogify "out.html"
              (if upload-profile
                  (upload-handler upload-profile overwrite?)
                  default-handler)))))

(run)

#lang racket/base
(require racket/contract
         racket/file
         "private/scriblogify.rkt"
         "private/handlers.rkt"
         "private/util.rkt")
(provide/contract
 [scriblogify
  (->* (path-string?)
       (#:profile (or/c symbol? #f)
        #:link-to-pre? any/c
        #:overwrite? any/c
        #:verbose? any/c
        #:temp-dir (or/c path-string? #f)
        #:docs-base-url string?)
       void?)])

(define (scriblogify file
                     #:profile [profile #f]
                     #:link-to-pre? [link-to-pre? #f]
                     #:overwrite? [overwrite? #f]
                     #:verbose? [v? (verbose?)]
                     #:temp-dir [temp-dir #f]
                     #:docs-base-url [docs-base-url
                                      (if link-to-pre?
                                          "http://pre.racket-lang.org/docs/html/"
                                          "http://doc.racket-lang.org/")])
  (parameterize ((verbose? (and v? #t)))
    (let ([temp-dir
           (or temp-dir
               (path->string (make-temporary-file "scriblogify~a" 'directory)))])
      (when (verbose?)
        (when link-to-pre?
          (eprintf "Using nightly build documentation pages\n"))
        (eprintf "Putting temporary files in ~s.\n" temp-dir))
      (run-scribble #:dest temp-dir
                    #:dest-name "out.html"
                    #:redirect-main docs-base-url
                    file)
      (parameterize ((current-directory temp-dir))
        (blogify "out.html"
                 (if profile
                     (upload-handler profile overwrite?)
                     default-handler))
        (void)))))

(define (run-scribble #:dest dest
                      #:dest-name dest-name
                      #:redirect-main redirect-main
                      file)
  (parameterize ((current-namespace (make-base-namespace))
                 (current-command-line-arguments
                  (vector "--quiet"
                          "--html"
                          "--dest" dest
                          "--dest-name" dest-name
                          "--redirect-main" redirect-main
                          "++xref-in" "setup/xref" "load-collections-xref"
                          file)))
    (dynamic-require 'scribble/run #f)))

#lang scribble/manual
@(require scribble/racket
          slideshow/pict
          (planet ryanc/scriblogify:1/scribble-util)
          (for-syntax racket/base)
          (for-label racket))

@title{scriblogify test post}
@author{You!}

@(blog-tag "test")

I just made my first post using Scriblogify! And I feel great!

@(the-jump)

It was easy as installing Scriblogify with

@racketblock[
(require (planet ryanc/scriblogify:1))
]

and fiddling around with configurations using

@commandline{raco scriblogify --setup}

@elem[#:style "smaller"]{and then finding the directory where the package was installed,
going to the @tt{test} subdirectory} 
and then posting this with

@commandline{raco scriblogify -p testing test-scriblogify.scrbl}

Here's some fish in the clouds!

@(define (mycloud w h)
   (cc-superimpose (cloud w h "lightblue")
                   (cloud (- w 10) (- h 10) "white")))

@(cc-superimpose
  (rt-superimpose (inset (lb-superimpose (inset (mycloud 300 200) 20)
                                         (mycloud 150 100))
                         20)
                  (mycloud 150 100))
  (hc-append (standard-fish 60 50 #:direction 'right #:color "red")
             (blank 40 0)
             (standard-fish 30 20 #:direction 'left #:color "blue")))

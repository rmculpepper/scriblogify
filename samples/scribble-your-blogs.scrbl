#lang scribble/manual
@(require scribble/eval
          scribble/racket
          (planet ryanc/scriblogify:1/scribble-util)
          (for-syntax racket/base)
          (for-label racket slideshow/pict))

@(define the-eval (make-base-eval))

@title{Scribble Your Blogs}
@author{Ryan}

@seclink["top" #:doc '(lib "scribblings/scribble/scribble.scrbl")]{Scribble} is
a great language for writing documentation and papers. Now it's a great language
for writing blog posts too. I've just released a tool called Scriblogify that
compiles Scribble documents and posts them as blog entries. Scriblogify is a
more polished and automated version of the scripts I've been using for several
months to prepare posts for @hyperlink["http://macrologist.blogspot.com"]{my
blog}.

@(the-jump)

To get Scriblogify, just download it from PLaneT:

@racketblock[
(require (planet ryanc/scriblogify:1))
]
or
@commandline{raco planet install ryanc scriblogify.plt 1 0}

The package automatically installs a @tt{raco} subcommand (@tt{raco
scriblogify}) that can be used to configure Scriblogify and process
and upload blog posts.

Then configure Scriblogify with upload profiles by running

@commandline{raco scriblogify --setup}

That will open a browser window with the Scriblogify configuration
servlet. You'll need to log in to your Google account and authorize
Scriblogify to access your Blogger and (optionally) Picasa Web Albums
accounts.  Then create one or more @emph{profiles}---named
combinations of blogs and web albums to upload to.

Choosing a web album enables Scriblogify to automatically handle
images computed in your Scribble documents. For example, here are some
images computed with the @racketmodname[slideshow/pict] library:

@interaction[#:eval the-eval
(require slideshow/pict)
(define rainbow-colors
  '("red" "orange" "yellow" "green" "blue" "purple"))
(for/list ([c rainbow-colors])
  (colorize (filled-rounded-rectangle 20 20) c))
(for/list ([c rainbow-colors]
           [dir (in-cycle '(right left))])
  (standard-fish 25 25 #:color c #:direction dir))
(cc-superimpose
 (cc-superimpose (cloud 100 80 "lightblue")
                 (cloud 90 70 "white"))
 (hc-append 10
  (standard-fish 30 30 #:color "red" #:direction 'right)
  (standard-fish 25 20 #:color "blue" #:direction 'left)))
]

By Scribbling your blog entries you get Scribble's nice code formatting,
colorizing, and documentation links for free. If you're blogging about
bleeding-edge work, there's an option to make Scriblogify link to the
@hyperlink["http://pre.racket-lang.org/docs/html/"]{nightly build docs} (updated
``daily'') instead of the @hyperlink["http://docs.racket-lang.org/"]{release
docs} (updated every 3 months).

@;{FIXME: mention CSS}

Now go forth and Scribble your blogs.

@(close-eval the-eval)

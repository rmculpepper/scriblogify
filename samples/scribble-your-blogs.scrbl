#lang scribble/manual
@(require scribble/eval
          scribble/racket
          (planet ryanc/scriblogify:1/scribble-util)
          (for-syntax racket/base)
          (for-label racket slideshow/pict))

@(define the-eval (make-base-eval))

@title{Scribble Your Blogs}
@author{Ryan}               @;{ An author is required, but ignored, because
                                Scriblogify currently uses the author info box 
                                to find the start of the real content. }

@seclink["top" #:doc '(lib "scribblings/scribble/scribble.scrbl")]{Scribble} is
a great language for writing documentation. Now it's a great language for
writing blog posts, too. I've just released a tool called Scriblogify that
compiles Scribble documents and posts them as blog entries. Scriblogify is a
more polished and automated version of the scripts I've been using for several
months to prepare posts for @hyperlink["http://macrologist.blogspot.com"]{my own
blog}.

@(the-jump)

To get Scriblogify, just download it from
@hyperlink["http://planet.racket-lang.org/"]{PLaneT}:

@racketblock[
(require (planet ryanc/scriblogify:1))
]
or
@commandline{raco planet install ryanc scriblogify.plt 1 0}

The package automatically installs a @tt{raco} subcommand (@tt{raco
scriblogify}) that can be used to configure Scriblogify and process
and upload blog posts.

Configure Scriblogify by running

@commandline{raco scriblogify --setup}

That will open a browser window with the Scriblogify configuration servlet. The
servlet will prompt you to authorize Scriblogify to access your Blogger and
Picasa Web Albums accounts (only the Blogger/Picasa combination is currently
supported) and then create one or more @emph{profiles}---named combinations of
blogs and web albums to upload to.

Scriblogify automatically handles images computed in your Scribble documents by
uploading them to a web album. For example, here are some images computed with
the @racketmodname[slideshow/pict] library:

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

By Scribbling your blog entries, you get Scribble's nice code
formatting, colorizing, and documentation links for free---well, once
you've updated your blog's CSS (see below). If you're blogging about
bleeding-edge work, there's an option to make Scriblogify link to the
@hyperlink["http://pre.racket-lang.org/docs/html/"]{nightly build
docs} (updated daily) instead of the
@hyperlink["http://docs.racket-lang.org/"]{release docs} (updated
every 3 months).

@hyperlink["http://planet.racket-lang.org/package-source/ryanc/scriblogify.plt/1/0/planet-docs/scriblogify/index.html"]{Scriblogify's
documentation} has more details, including how to update your blog's CSS for
Scribbled content and what bloggable Scribble documents look like.

You can see the source for this blog post
@hyperlink["https://github.com/rmculpepper/scriblogify/blob/v1.0/samples/scribble-your-blogs.scrbl"]{here}. 
This blog entry was created with the following command:

@commandline{raco scriblogify -p the-racket-blog scribble-your-blogs.scrbl}

Now go forth and Scribble your blogs.

@(close-eval the-eval)

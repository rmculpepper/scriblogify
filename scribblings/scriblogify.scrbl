#lang scribble/manual
@(require racket/runtime-path
          planet/scribble
          planet/version
          scribble/struct
          (for-label racket/base
                     racket/contract
                     scribble/base
                     scribble/core
                     scribble/decode
                     (this-package-in main scribble-util)))

@(define-runtime-path sample-doc "../test/test-scriblogify.scrbl")
@(define-runtime-path style-file "../blog-style.css")
@(define (ttt . content) (make-element 'tt content))
@(define (my-package-version)
   (format "~a.~a" (this-package-version-maj) (this-package-version-min)))

@title[#:version (my-package-version)]{Scriblogify: Scribble Your Blog}
@author{@author+email["Ryan Culpepper" "ryanc@racket-lang.org"]}

This package provides a @tt{raco} subcommand for processing Scribble
documents into a form suitable for uploading as blog posts. It can
also be configured to do the uploading itself.

@bold{Development} Development of this library is hosted by
@hyperlink["http://github.com"]{GitHub} at the following project page:

@centered{@url{https://github.com/rmculpepper/scriblogify}}

@bold{Copying} This program is free software: you can redistribute
it and/or modify it under the terms of the
@hyperlink["http://www.gnu.org/licenses/lgpl.html"]{GNU Lesser General
Public License} as published by the Free Software Foundation, either
version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License and GNU Lesser General Public License for more
details.

@section[#:tag "raco-scriblogify"]{@tt{raco scriblogify}: Running Scriblogify}

Scriblogify installs a @tt{raco} subcommand so that it can be run
using @tt{raco scriblogify}. See @secref["scriblogify-api"] for how to
run Scriblogify from Racket code.

Scriblogify can be used as a local document processor, or with a
little configuration it can be used to automatically process and
upload blog posts (including embedded images).

To use Scriblogify as a local document processor, just call @tt{raco
scriblogify} on the Scribble source of the document to process:

@commandline{raco scriblogify document.scrbl}

The script compiles @tt{document.scrbl} using Scribble and prints the
processed HTML to standard output. You can try running it on
@hyperlink[sample-doc]{this source file}.

The following command-line options are relevant:
@itemlist[

@item{@tt{-d build-directory} or @ttt{--dir build-directory}: puts
temporary files in @tt{build-directory}}

@item{@tt{-n} or @ttt{--nightly}: link to the nightly build
documentation at @url{http://pre.racket-lang.org/docs/html} instead of
the released documentation at @url{http://docs.racket-lang.org}.}

@item{@tt{-v} or @ttt{--verbose}: turns on verbose output}
]

There are some restrictions on the Scribble documents:
@itemlist[
@item{a @racket[title] must be present; it is used as the blog post title}
@item{an @racket[author] must be present, but it is ignored}
@item{@racket[margin-note]s should not be used}
]

Scriblogify must be configured before it can automatically post blog
entries for you. You can configure Scriblogify using the following
command:

@commandline{raco scriblogify --setup}

That command starts a local configuration servlet and opens a browser
window with the servlet's address. The servlet guides you through the
process of granting Scriblogify access to your Blogger and
(optionally) Picasa Web accounts; access is necessary for Scriblogify
to upload posts on your behalf. Access to your Picasa Web account is
necessary only if you want to post blog enries that have embedded
(computed) images; you don't need to grant Picasa Web access if your
posts won't have images or if you explicitly link to manually uploaded
images.

@emph{Note:} Authorizing Scriblogify to access your accounts gives it
a long-lived token (a ``refresh token'' in the parlance of the OAuth
2.0 protocol). That token is saved in your local Scriblogify
preference file; anyone with access to that token can access your
Blogger and (optionally) Picasa Web accounts. @emph{Do not use
Scriblogify if you do not want this token stored in your local
filesystem.}

Once you have created a profile using the setup servlet, you can
process and upload your blog entries in one step:

@commandline{raco scriblogify -p profile document.scrbl}

Scriblogify uploads posts in ``draft'' mode, so you'll still have to
log in and click ``Publish'' to make your post public.

The following additional command-line options are relevant:
@itemlist[

@item{@tt{-p profile} or @ttt{--profile profile}: uploads using the
Blogger and (optionally) Picasa Web account associated with
@tt{profile}}

@item{@tt{-f} or @ttt{--force}: overwrite an existing blog post with
the same title}
]

Finally, you should update your blog with CSS styles for Scribble
elements. This package includes @hyperlink[style-file]{a basic CSS
file} based on the default Scribble style files but with unnecessary
styles removed.

(Hint: To upload custom CSS, start at your blog's main page, then
click the ``Design'' link at the top right, select the ``Template''
link on the left margin, click the ``Customize'' button, select
``Advanced'', then scroll down to ``Add CSS''. Add your CSS in the
text box to the right, then click the ``Apply to Blog'' button.)

@section[#:tag "scriblogify-api"]{Scriblogify API}

@defmodule/this-package[main]

@defproc[(scriblogify [file path-string?]
                      [#:profile profile (or/c symbol? #f) #f]
                      [#:link-to-pre? link-to-pre? any/c #f]
                      [#:overwrite? overwrite? any/c #f]
                      [#:verbose? verbose? any/c #f]
                      [#:temp-dir temp-dir (or/c path-string? #f) #f]
                      [#:docs-base-url docs-base-url string?
                                       (if link-to-pre?
                                           "http://pre.racket-lang.org/docs/html/"
                                           "http://docs.racket-lang.org/")])
         void?]{

  Same as @tt{raco scriblogify}, described in @secref["raco-scriblogify"].
}

@section{Scribble Utilities for Blog Posts}

The following utilities are intended for use within Scribble documents
representing blog posts.

@defmodule/this-package[scribble-util]

@defproc[(the-jump)
         block?]{

Marks the ``jump''---the boundary between the part of the post
displayed in abbreviated contexts and the rest of the post.
}

@defproc[(blogsection [preflow pre-content?] ...+)
         part-start?]{

Like @racket[section], but not numbered.
}

@defform[(declare-keyword id ...)]{

Defines each @racket[id] so that it typesets as a syntactic form in
code.
}

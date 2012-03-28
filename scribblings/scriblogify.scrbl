#lang scribble/manual

@title{Scriblogify: Scribble Your Blog Posts}
@author{Ryan Culpepper}

@section{Running Scriblogify}

@;{ talk about security }

@section{Scribble Utilities for Blog Posts}

@defmodule/this-package[scribble-util]

@defproc[(the-jump)
         ???]{

Marks the ``jump''---the boundary between the part of the post
displayed in abbreviated contexts and the rest of the post.
}

@defproc[(blogsection [preflow ???])
         ???]{

Like @racket[section], but not numbered.
}

@defform[(declare-keyword id ...)]{

Defines each @racket[id] so that it typesets as a syntactic form in
code.
}

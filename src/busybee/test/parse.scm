(require "parsing.scm")

;; Parsing shouldn't transclude, since that leaves it open to failure if a file doesn't exist

(parse "◊![#:tag def:term=Transclusion]{test/basic.bee}")

(parse "◊!{test/basic.bee}")

(require "busybee.scm")

(require "markdown.scm")

(define parsed (read-and-parse "test/basic.bee"))

(define parsed (read-and-parse "test/query.bee"))

(define parsed (read-and-parse "test/template.bee"))

(require "latex.scm")

(parameterize ([target "tex"])
  (flatten-txt-expr (texpr->tgt parsed)))

(texpr->tgt parsed)

(define parsed (read-and-parse "test/query.bee"))

(texpr->tgt parsed)

(define parsed (parse "◊section{Opening}
					  ◊b{hello} my good friends"))

;; https://codereview.stackexchange.com/a/87626

(eq? parsed '((b "hello") " my good friends"))


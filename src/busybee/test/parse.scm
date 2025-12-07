(require "busybee.scm")

(define parsed (read-and-parse "test/basic.bee"))

(define parsed (read-and-parse "test/query.bee"))

(define parsed (read-and-parse "test/template.bee"))


;; Parsing shouldn't transclude, since that leaves it open to failure if a file doesn't exist

(require "parsing.scm")

(parse "◊![#:tag def:term=Transclusion]{test/basic.bee}")

(parse "◊!{test/basic.bee}")


(require "markdown.scm")


(require "latex.scm")

(define parsed (parse "◊section{Hello}
					  
					  My name is ◊b{Matt} and I am working on this feature"))

(paragraph-reader parsed)

(parameterize ([target "tree"])
  (flatten-txt-expr (texpr->tgt parsed)))

(texpr->tgt parsed)

(define parsed (read-and-parse "test/query.bee"))

(texpr->tgt parsed)

(define parsed (parse "◊section{Opening}
					  ◊b{hello} my good friends"))

;; https://codereview.stackexchange.com/a/87626

(eq? parsed '((b "hello") " my good friends"))


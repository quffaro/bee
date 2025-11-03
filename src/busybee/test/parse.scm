(require "parsing.scm")

(require "busybee.scm")

(define parsed (read-and-parse "test/basic.bee"))

(require "markdown.scm")

(texpr->tgt parsed)

(define parsed (parse "◊section{Opening}
					  ◊b{hello} my good friends"))

;; https://codereview.stackexchange.com/a/87626

(eq? parsed '((b "hello") " my good friends"))


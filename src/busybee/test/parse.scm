(require "parsing.scm")

(define parsed (parse "◊b{hello} my good friends"))

(eq? parsed '((b "hello") " my good friends"))


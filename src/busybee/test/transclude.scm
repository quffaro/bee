(require "parsing.scm")

(require "busybee.scm")

(require "markdown.scm")

(define parsed (read-and-parse "test/query.bee"))

(texpr->tgt parsed)

(define out (flatten-txt-expr (texpr->tgt parsed)))

(read-and-parse "../../docs/busy.bee")



(render "md" "◊section[#:lvl 3]{Introduction}
	   Lorem ipsum ◊cite[#:src 'val]{sic}")

(define parsed (read-and-parse "test/transcluding.bee"))

;; TODO a \n character is not parsed in the second line.

;; TODO we should handle iteration in a way where we don't need to flatten after the fact. we could also consider a flat-mapping transducer

(flatten-txt-expr (texpr->tgt parsed))

(transclude-runner parsed)

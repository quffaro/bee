(require "parsing.scm")

(require "busybee.scm")

(require "markdown.scm")

(define parsed (parse "◊section[#:lvl 3]{Introduction}
	   Lorem ipsum ◊cite[#:src 'val]{sic}"))

parsed

(define interpreted (texpr->md parsed))

(flatten-txt-expr interpreted)

(read-and-parse "test/transcluding.bee")

;; TODO a \n character is not parsed in the second line.

;; TODO we should handle iteration in a way where we don't need to flatten after the fact. we could also consider a flat-mapping transducer

(flatten-txt-expr (texpr->md parsed))

(transclude-runner parsed)

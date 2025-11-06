(define-tag (b tree) (attrs els)
  `(txt "*" ,@els "*"))

(define-tag (em tree) (attrs els)
 `(txt "_" ,@els "_"))

(define-tag (def tree) (attrs els)
 `(txt "" ,@els ""))

(define-tag (section tree) (attrs els)
 `(txt "## " ,@els "\n"))

(define-tag (ltx tree) (attrs els)
 `(txt "$" ,@els "$"))

(define-tag (cite tree) (attrs els)
  (define src (attr-val attrs 'src))
  `(txt ,@src ,@els))

;; busybee-specific

;; because of the awkwardness defining 
(define-tag (transclude tree) (attrs els)
  `(txt ,@els)) 

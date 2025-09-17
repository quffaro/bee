(define-tag (b md) (attrs els)
  `(txt "*" ,@els "*"))

(define-tag (em md) (attrs els)
 `(txt "_" ,@els "_"))

(define-tag (def md) (attrs els)
 `(txt "" ,@els ""))

(define-tag (section md) (attrs els)
 `(txt "## " ,@els "\n"))

(define-tag (cite md) (attrs els)
  (define src (attr-val attrs 'src))
  `(txt ,@src ,@els))

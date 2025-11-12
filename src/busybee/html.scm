(define-tag (b html) (attrs els)
  `(txt "<b>" ,@els "</b>"))

(define-tag (em html) (attrs els)
 `(txt "<i>" ,@els "</i>"))

(define-tag (def html) (attrs els)
 `(txt "" ,@els ""))

(define-tag (section html) (attrs els)
 `(txt "<h1>" ,@els "</h1>"))

(define-tag (ltx html) (attrs els)
 `(txt "$" ,@els "$"))

(define-tag (cite html) (attrs els)
  (define src (attr-val attrs 'src))
  `(txt ,@src ,@els))

;; busybee-specific

(define-tag (transclude html) (attrs els)
  `(txt ,@els))

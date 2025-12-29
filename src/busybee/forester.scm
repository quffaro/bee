(define-tag (p tree) (attrs els)
  `(txt "\\p{" ,@els "}"))

(define-tag (b tree) (attrs els)
  `(txt "\\b{" ,@els "}"))

(define-tag (em tree) (attrs els)
 `(txt "\\em{" ,@els "}"))

(define-tag (def tree) (attrs els)
 `(txt "" ,@els ""))

(define-tag (section tree) (attrs els)
 `(txt "\\section{" ,@els "}\n"))

(define-tag (ltx tree) (attrs els)
 `(txt "\\${" ,@els "}"))

(define-tag (cite tree) (attrs els)
  (define src (attr-val attrs 'src))
  `(txt ,@src ,@els))

;; busybee-specific

;; because of the awkwardness defining 
(define-tag (transclude tree) (attrs els)
  `(txt ,@els))

(define-tag (root tree) (attrs els)
  `(txt ,@els))

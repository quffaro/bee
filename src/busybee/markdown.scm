(define-tag (b md) (attrs els)
  `(txt "*" ,@els "*"))

(define-tag (em md) (attrs els)
 `(txt "_" ,@els "_"))

(define-tag (def md) (attrs els)
 `(txt "" ,@els ""))

(define (fmt-section-level attrs)
  (define level (attr-val attrs 'lvl))
  (define level (cond
				  [(void? level) 1]
				  [(list? level) 1] ;; TODO when (#<void>)
				  [else (string->int (symbol->string level))]))
  (string-join (map (lambda _ "#") (range level))))

(define-tag (section md) (attrs els)
  (define lvl-str (fmt-section-level attrs))
  `(txt ,lvl-str " " ,@els "\n"))

(define-tag (ltx md) (attrs els)
 `(txt "$" ,@els "$"))

(define-tag (cite md) (attrs els)
  (define src (attr-val attrs 'src))
  `(txt ,@els))

;; busybee-specific

;; because of the awkwardness defining 
(define-tag (transclude md) (attrs els)
  `(txt ,@els)) 

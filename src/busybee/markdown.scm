(define-tag (b md) (attrs els)
  `(txt "*" ,@els "*"))

(define-tag (em md) (attrs els)
 `(txt "_" ,@els "_"))

(define-tag (def md) (attrs els)
 `(txt "*" ,@els "*"))

(define-tag (ul md) (attrs els)
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

(define (split-by lst x)
  (foldr (lambda (element next)
           (if (eqv? element x)
               (cons '() next)
               (cons (cons element (first next)) (rest next))))
         (list '()) lst))

(define (intersperse lst val)
  (cond
	[(empty? lst) lst]
	[else
	  (cons (car lst) (cons val (intersperse (cdr lst) val)))]))

(define-tag (pre md) (attrs els)
  ; (define tabbed-els (string-replace (car els) "\n" "\n\t"))
  ; (define spersed (intersperse (split-by els 'NEWLINE) (list 'NEWLINE "\t")))
  ; (define tabbed-els (apply append spersed))
  `(txt "```\n" ,@els "```" ))

(define-tag (ltx md) (attrs els)
 `(txt "$" ,@els "$"))

(define-tag (cite md) (attrs els)
  (define src (attr-val attrs 'src))
  `(txt ,@els))

;; busybee-specific

(define-tag (transclude md) (attrs els)
  `(txt ,@els)) 

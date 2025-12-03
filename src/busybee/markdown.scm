(define-tag (b md) (attrs els)
  `(txt "*" ,@els "*"))

(define-tag (em md) (attrs els)
 `(txt "_" ,@els "_"))

(define-tag (def md) (attrs els)
  (define new-term (attr-val attrs 'term))
  (define terms (cons (format "~a" new-term) (attr-val attrs 'terms)))
  (mhash-set! (root-parameter) 'terms terms)
 `(txt "*" ,@els "*"))

(define-tag (ul md) (attrs els)
 `(txt "" ,@els ""))

;; For list items to work properly
;; we would need to access state from ◊ul.
;; This would happen in `texpr->tgt` when we process
;; the args of ◊ul first. We'll process...

(define-tag (li md) (attrs els)
 `(txt "-" ,@els ""))

(define (fmt-section-level attrs)
  (define level (attr-val attrs 'lvl))
  (define level (cond
				  [(or (void? level) (empty? level)) 1]
				  [(list? level) 1] ;; TODO when (#<void>)
				  [(number? level) level]
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

(require "/home/you/projects/personal/steel-dev/steel/cogs/collections/mhash.scm")
(require "srfi/srfi-28/format.scm")


(define-tag (example md) (attrs els)
  (define name (format "~a" (mhash-ref attrs 'name)))
  `(txt ,name ": " ,@els "\n\n"))

;; busybee-specific

(define-tag (! md) (attrs els) 
   `(txt ,@els))

(define-tag (root md) (attrs els)
  `(txt ,@els))

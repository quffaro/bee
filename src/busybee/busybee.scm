(require "srfi/srfi-28/format.scm")

(require "srfi/match.scm")

(provide methods
		 register-tag!
		 fetch-tag
		 target
		 parse
		 mhash-ref
		 mhash-set!
		 mhash-contains?
		 define-tag)

;; --------------------------------------------------

(require "/home/you/projects/personal/steel-dev/steel/cogs/collections/mhash.scm")

(define methods (mhash))

(define target (make-parameter "md"))

(define (register-tag! name tgt expr)
  (define fmt-table
    (cond
      [(mhash-contains? methods tgt) (mhash-ref methods tgt)]
      [else
       (define new (mhash))
       (mhash-set! methods tgt new)
       new]))
  (mhash-set! fmt-table name expr))

(define (get-tag tag-name tgt)
  (if (and (mhash-contains? methods tgt) (mhash-contains? (mhash-ref methods tgt) tag-name))
      (mhash-ref (mhash-ref methods tgt) tag-name)
	  (error 'get-tag-handler "No handler found for tag ~a in format ~a" tag-name tgt)))

(define (identity x) x)

(define (fetch-tag tag-name)
  (if (and (mhash-contains? methods (target)) (mhash-contains? (mhash-ref methods (target)) tag-name))
      (mhash-ref (mhash-ref methods (target)) tag-name)
	  identity))

(define-syntax define-tag
  (syntax-rules ()
	[(_ (name tgt) (attrs els) body ...)
	 (begin
	   (register-tag! 
		 (symbol->string (quote name)) 
		 (symbol->string (quote tgt)) 
		 (handle-kw (lambda (attrs els) body ...)))
	   (define name
	     (handle-kw (lambda (attrs els) body ...))))]))

(define (handle-kw proc)
  (lambda args
    (cond
      [(null? args) (proc (hash) '())]
      [(hash? (car args)) (proc (car args) (cdr args))]
      [else (proc (hash) args)])))

(define (attr-val dict key)
  (if (hash-contains? dict key)
    (hash-ref dict key)
	(list void)))

;; --------------------------------------------------

(define (texpr->md texpr)
  (cond
	[(empty? texpr) texpr]
	[(string? texpr) texpr]
	[(eq? 'NEWLINE texpr) "\n"]
	[(symbol? texpr) texpr]
	; [(eq? (car texpr) 'code) texpr]
	[(empty? (car texpr)) texpr] ; case when ◊cite[ returns '(())
	[(symbol? (car texpr))
	  (define tag (fetch-tag (symbol->string (car texpr))))
	  (define result (map texpr->md (cdr texpr)))
	  (apply tag result)]
	[else (cons 'txt (map texpr->md texpr))]))

(define (flatten-txt-expr expr)
  (cond
    [(string? expr) expr]
    [(and (list? expr) (eq? (car expr) 'txt))
     (apply string-append (map flatten-txt-expr (cdr expr)))]
    [else (format "~a" expr)]))

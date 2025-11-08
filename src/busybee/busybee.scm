(require "srfi/srfi-28/format.scm")

(require "srfi/match.scm")

(provide methods
		 register-tag!
		 fetch-tag
		 target
		 mhash-ref
		 mhash-set!
		 mhash-contains?
		 define-tag
		 attr-val
		 texpr->tgt
		 flatten-txt-expr
		 render)

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
	  ; (begin (displayln methods)
	  ; (error 'get-tag-handler (format "No handler found for tag ~a in format ~a" tag-name (target))))))

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
      [(null? args) (proc (mhash) '())]
      [(mhash? (car args)) (proc (car args) (cdr args))]
      [else (proc (mhash) args)])))

(define (attr-val dict key)
  (if (mhash-contains? dict key)
    (mhash-ref dict key)
	(list void)))

;; --------------------------------------------------

(define (kw-list->mhash lst)
  (let loop ((rest lst) (h (mhash)))
    (cond
      [(< (length rest) 2) h]
      [(eq? (car rest) 'KW)
       (let* ([kv-str (cadr rest)]
              [parts (split-whitespace kv-str)])
         (mhash-set! h 
                         (string->symbol (car parts))
                         (string->symbol (cadr parts)))
		 (loop (cddr rest) h))]
      [else (loop (cddr rest) h)])))

; (kw-list->hash (cadar parsed))

; (kw->mhash x)

(define (texpr->tgt texpr)
  (cond
	[(empty? texpr) texpr]
	[(and (list? texpr) (eq? (car texpr) 'KW)) 
	 (kw-list->mhash texpr)]
	[(string? texpr) texpr]
	[(eq? 'NEWLINE texpr) "\n"]
	[(symbol? texpr) texpr]
	; [(eq? (car texpr) 'code) texpr]
	[(empty? (car texpr)) texpr] ; case when ◊cite[ returns '(())
	[(symbol? (car texpr))
	 (define tag (fetch-tag (symbol->string (car texpr))))
	 (define result (map texpr->tgt (cdr texpr)))
	  (apply tag result)]
	[else (cons 'txt (map texpr->tgt texpr))]))

(define (flatten-txt-expr expr)
  (cond
    [(string? expr) expr]
    [(and (list? expr) (eq? (car expr) 'txt))
     (apply string-append (map flatten-txt-expr (cdr expr)))]
    [else (format "~a" expr)]))

(define (render tgt txt)
  (parameterize ([target tgt])
	(flatten-txt-expr (texpr->tgt (parse txt)))))

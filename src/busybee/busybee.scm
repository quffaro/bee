(provide methods
		 register-tag!
		 fetch-tag
		 target
		 mhash-ref
		 mhash-set!
		 mhash-contains?
		 define-tag
		 attr-val
		 texpr?
		 head
		 attrs
		 args
		 texpr->tgt
		 flatten-txt-expr
		 query-loop
		 render)

;; --------------------------------------------------

(require "parsing.scm")

(provide read-and-parse)

(require "srfi/srfi-28/format.scm")
(require "srfi/match.scm")
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

(define (mhash-empty? hsh)
  (if (mhash? hsh)
	(empty? (mhash-keys->list hsh))
	(error 'type-error "The value ~a is not a mutable hash" hsh)))

(define (fetch-tag tag-name)
  (if (and (mhash-contains? methods (target)) (mhash-contains? (mhash-ref methods (target)) tag-name))
      (mhash-ref (mhash-ref methods (target)) tag-name)
	  identity))

(define-syntax define-tag
  (syntax-rules ()
	[(_ (name tgt) (attrs . els) body ...)
	 (begin
	   (register-tag! 
		 (symbol->string (quote name)) 
		 (symbol->string (quote tgt)) 
		 (handle-kw (lambda (attrs . els) body ...)))
	   (define name
	     (handle-kw (lambda (attrs . els) body ...))))]))

(define (handle-kw proc)
  (lambda args
	(cond
      [(null? args) (proc (mhash) '())]
      [(mhash? (car args)) (proc (car args) (cdr args))]
      [else (proc (mhash) args)])))

(define (attr-val dict key)
  (if (mhash-contains? dict key)
    (mhash-ref dict key)
	'()))

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

(define (intersperse lst val)
  (cond
	[(empty? lst) lst]
	[else (cons (car lst) (cons val (intersperse (cdr lst) val)))]))

(define (texpr? lst)
  (match lst
    [(list sym hsh) (and (symbol? sym) (mhash? hsh))]
    [(list sym hsh x ...) 
	 (and (symbol? sym) (mhash? hsh) (or (string? x) (symbol? x) (list? x)))]
    [_ #f]))

(define (head texpr)
  (if (texpr? texpr)
	(car texpr)
	'()))

(define (attrs texpr)
  (if (texpr? texpr)
	(cadr texpr)
	(mhash)))

(define (args texpr)
  (if (texpr? texpr)
	(match texpr
	[(list sym hsh x ...) x]
	[_ '()])))

(define (texpr->tgt texpr)
  ;; use texpr? function
  (cond
	[(void? texpr) '()]
	[(empty? texpr) texpr]
	[(mhash? texpr) texpr]
	[(string? texpr) texpr]
	[(eq? 'NEWLINE texpr) "\n"]
	[(symbol? texpr) texpr]
	; [(eq? (car texpr) 'code) texpr]
	[(empty? (car texpr)) texpr] ; case when ◊cite[ returns '(())
	[(symbol? (car texpr))
	 (define tag (fetch-tag (symbol->string (car texpr))))
	 (define result (cond
	   [(eq? '! (head texpr))
		 (define queried-result (map (lambda (x) (query-loop (attrs texpr) x)) (args texpr)))
		 (map texpr->tgt queried-result)]
	   [else
	     (map texpr->tgt (cdr texpr))]))
	  (apply tag result)]
	;; TODO this should be a list case
	[else (cons 'txt (map texpr->tgt texpr))]))

(define (flatten-txt-expr expr)
  (cond
    [(string? expr) (format "~a" expr)]
	[(list? expr)
	 (define filtered (filter (lambda (x) (not (empty? x))) expr))
	 (if (eq? (car filtered) 'txt)
       (apply string-append (map flatten-txt-expr (cdr filtered))))]
    [else (format "~a" expr)]))

(define (fapply-texpr-kw f kw-key texpr #:default default)
  (define adjusted-key (string->symbol kw-key))
  (let [(kw-val (attr-val (attrs texpr) adjusted-key))]
	(define kw (attrs texpr))
	(if (empty? (mhash-keys->list kw))
	  `(,(head texpr) ,(mhash kw-key default) ,(args texpr))
	  (begin
		(define adjusted-kw-val (char->number (cadr (string->list (value->string kw-val)))))
		(mhash-set! kw adjusted-key (f adjusted-kw-val))
	`(,(head texpr) ,kw ,(args texpr))))))

(define (query-loop q texpr)
  (cond
	[(mhash-empty? q) texpr]
	;; because our use of `match` cannot match on symbols
	[(or (string? texpr) (symbol? texpr) (empty? texpr)) ]
	[(texpr? texpr)
	   ;; Currently the *single* value which matches all tags whose heads match `tag`.
	   (define tag-value (attr-val q 'tag))
	   ;; The `kw-value` is a pair with the `head` of a tag and a kwarg that might be associated with
	   ;; it, written `tag:kwarg`. If there is a `tag` whose head matches `tag` and has a keyword argument
	   ;; matching `kwarg`, then its considered a match. For example, the texpr
	   ;;   
	   ;;   ◊section[#:lvl 1]{Beginning}
	   ;;
	   ;; will match on `section:lvl`.
	   (define kw-value (attr-val q 'kw))
	   ;; The `do-value` is the action that we're supposed to be performing on matches for `kw-value`.
	   ;; Currently this is unused.
	   (define do-value (attr-val q 'do))
	   (cond
		 [(eq? tag-value (head texpr)) texpr]
		 ;; section:lvl 
		 [(not (empty? kw-value))
		  ;; possible forms:
		  ;;   - section:lvl
		  ;;   - section:lvl=1
		  (define tag-kwarg (split-once (format "~a" kw-value) ":"))
		  ;; possible forms:
		  ;;   - #t
		  ;;   - '("lvl" "1")
		  (define quantity (split-once (second tag-kwarg) "="))
		  (if (and (equal? (value->string (head texpr)) (first tag-kwarg))
				;; need to parse symbols and numbers in kwargs!
				(if quantity quantity (equal? (attr-val texpr (string->symbol (first quantity))) (string->number (second quantity)))))
			(fapply-texpr-kw (lambda (x) (+ x 1)) (second tag-kwarg) texpr #:default 1))]
		 [else
		   (map (lambda (x) (query-loop q x)) (args texpr))])]
	[else ]))

(define (render tgt txt)
  (parameterize ([target tgt])
	(flatten-txt-expr (texpr->tgt (parse txt)))))

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
		 texpr?
		 head
		 attrs
		 args
		 texpr->tgt
		 flatten-txt-expr
		 query-loop
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

(define (texpr? lst)
  (match lst
    [(list sym hsh) (and (symbol? sym) (mhash? hsh))]
    [(list sym hsh x ...) (and (symbol? sym) 
                           (mhash? hsh)
                           (or (string? x) (symbol? x) (list? x)))]
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
	; (if (eq? (cddr texpr) '()) '() (caddr texpr))
	; '()))

(define (texpr->tgt texpr)
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
		; (displayln "!!" texpr)
		(define queried-result 
		  (map (lambda (x) (query-loop (attrs texpr) x)) (args texpr)))
		(map texpr->tgt queried-result)]
	   [else
		 (map texpr->tgt (cdr texpr))]))
	  (apply tag result)]
	[else (cons 'txt (map texpr->tgt texpr))]))

(define (flatten-txt-expr expr)
  (cond
    [(string? expr) (format "~a" expr)]
	[(list? expr)
	 (define filtered (filter 
						(lambda (x) (not (empty? x))) expr))
	 (if (eq? (car filtered) 'txt)
       (apply string-append 
			  (map flatten-txt-expr (cdr filtered))))]
    [else (format "~a" expr)]))

(define (fapply-texpr-kw f kw-key texpr #:default default)
  (define adjusted-key (string->symbol (list->string (rest (string->list kw-key)))))
  (let [(kw-val (mhash-ref (attrs texpr) adjusted-key))]
	(define kw (attrs texpr))
	(if (empty? (mhash-keys->list kw))
	  `(,(head texpr) ,(mhash kw-key default) ,(args texpr))
	  (begin
		(define adjusted-kw-val (char->number (cadr (string->list (value->string kw-val)))))
		(mhash-set! kw adjusted-key (f adjusted-kw-val))
	`(,(head texpr) ,kw ,(args texpr))))))

(define (query-loop q texpr)
  (cond
	;; because `match` cannot match on symbols
	[(or (string? texpr) (symbol? texpr) (empty? texpr)) ]
	[(texpr? texpr)
	   (define cmd-value (attr-val q 'cmd))
	   (define kw-value (attr-val q 'kw))
	   (define do-value (attr-val q 'do))
	   (cond
		 [(eq? cmd-value (head texpr)) texpr]
		 ;; section:lvl 
		 [(not (empty? kw-value))
		  (define cmd-kwarg (split-once (format "~a" kw-value) ":"))
		  (if (equal? (value->string (head texpr)) (first cmd-kwarg))
			(fapply-texpr-kw (lambda (x) (+ x 1)) (second cmd-kwarg) texpr #:default 1))]
		 [else
		   (map (lambda (x) (query-loop q x)) (args texpr))])]
	[else ]))

(define (all? pred lst)
  (foldl (lambda (fst snd) 
		   (and fst snd)) #true (map pred lst)))

; (define (query-loop q texpr)
;   (displayln texpr)
;   (cond
; 	[(or (string? texpr) (symbol? texpr) (empty? texpr)) '()]
; 	[(texpr? texpr)
; 	  (define qkeys (mhash-keys->list q))
; 	  (define mh (attrs texpr))
; 	  (define keys (mhash-keys->list mh))
; 	  (define cmd-match (eq? (mhash-ref q 'cmd) (head texpr)))
; 	  (define search-keys (filter (lambda (k) (not (eq? k 'cmd))) qkeys))
; 	  (define is-match 
; 		(cons #t (map (lambda (qkey) (eq? (mhash-ref q qkey) (hash-ref mh qkey))) search-keys)))
; 		(if (all? identity `(cmd-match ,@is-match)) 
; 		  texpr
;           (map (lambda (x) (query-loop q x)) (args texpr)))]
; 	   [else
; 		  (map (lambda (x) (query-loop q x)) texpr)]))

(define (render tgt txt)
  (parameterize ([target tgt])
	(flatten-txt-expr (texpr->tgt (parse txt)))))

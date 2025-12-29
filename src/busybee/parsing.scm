;; TODO
;; - move tokenizer to its own file
;; - document and clean up parser code
;; - I was originally going to minimize the tokenizer and let the parser handle different cases, but we don't want to tokenize content we don't intend to parse. However, we need kwargs for transclusion

(provide parse
		 read-and-parse)

(define (string->expr str)
  (read (open-input-string (string-append "(" str ")"))))

(require "/home/you/projects/personal/steel-dev/steel/cogs/collections/mhash.scm")


;; PARSING

(define (char-whitespace? c)
    (or 
	  (char=? c #\space) 
	  (char=? c #\tab) 
      ; (char=? c #\newline) 
	  ; (char=? c #\return)
	  ))
  
(define (char-delimiter? c)
  (or (char=? c #\{) (char=? c #\})
	  (char=? c #\() (char=? c #\))
      (char=? c #\[) (char=? c #\])))
 
(define (skip-whitespace chars)
  (cond [(null? chars) '()]
        ; [(char-whitespace? (car chars)) 
         ; (skip-whitespace (cdr chars))]
        [else chars]))

(define (read-braces-string chars)
  (define (loop acc chars brace-depth)
	(cond
	  [(null? chars)
	    (values (list->string (reverse acc)) '())]
	  [(eq? (car chars) #\})
	     (if (= brace-depth 0)
		   (values (list->string (reverse acc)) (cdr chars))
		   (loop (cons #\} acc) (cdr chars) (- brace-depth 1)))]
	  [(eq? (car chars) #\{)
	   (loop (cons #\{ acc) (cdr chars) (+ brace-depth 1))]
	  [else
		(loop (cons (car chars) acc) (cdr chars) brace-depth)]))
  (loop '() chars 0))

(define (read-braces-string-no-braces chars)
  (define (loop acc chars brace-depth)
	(cond
	  [(null? chars)
	    (values (list->string (reverse acc)) '())]
	  [(eq? (car chars) #\})
	     (if (= brace-depth 1)
		   (values (list->string (reverse acc)) (cdr chars))
		   (loop (cons #\} acc) (cdr chars) (- brace-depth 1)))]
	  [(eq? (car chars) #\{)
	     (if (= brace-depth 0)
			(loop acc (cdr chars) (+ brace-depth 1))
			(loop (cons #\{ acc) (cdr chars) (+ brace-depth 1)))]
	  [else
		(loop (cons (car chars) acc) (cdr chars) brace-depth)]))
  (loop '() chars 0))

(define (read-string chars)
   (define (loop acc chars)
     (cond [(empty? chars) (values (list->string (reverse acc)) '())]
           ; [(char-whitespace? (car chars)) 
           ;  (values (list->string (reverse acc)) chars)]
		   [(char=? (car chars) #\newline)
			(values (list->string (reverse acc)) chars)]
           [(char-delimiter? (car chars))
            (values (list->string (reverse acc)) chars)]
		   [(char=? (car chars) #\◊)
			(values (list->string (reverse acc)) chars)]
		   [(and (>= (length chars) 2)
              (char=? (car chars) #\#)
              (char=? (cadr chars) #\:))
			(values (list->string (reverse acc)) chars)]
           [else (loop (cons (car chars) acc) (cdr chars))]))
   (loop '() chars))

;; unused
(define (read-kw chars)
	(define (loop acc chars)
	  (cond [(null? chars) (values (list->string (reverse acc)) '())]
			[(eq? #\space (car chars))
			 (values (list->string (reverse acc)) chars)]
			[else (loop (cons (car chars) acc) (cdr chars))]))
	(loop '() chars))

(define (read-quoted chars)
  (if (and (not (null? chars)) (char=? (car chars) #\'))
      (call-with-values 
        (lambda () (read-string (cdr chars)))
        (lambda (str rest)
          (values (list 'quote (string->symbol str)) rest)))
      (read-string chars)))

(define (tokenize-loop chars acc)
   (let ([chars (skip-whitespace chars)])
      (cond
		[(empty? chars) (reverse acc)]
        [(null? chars) (reverse acc)]
        [(char=? (car chars) #\() 
         (tokenize-loop (cdr chars) (cons 'LPAREN acc))]
        [(char=? (car chars) #\)) 
         (tokenize-loop (cdr chars) (cons 'RPAREN acc))]
		[(char=? (car chars) #\{) 
         (tokenize-loop (cdr chars) (cons 'LBRACE acc))]
        [(char=? (car chars) #\}) 
         (tokenize-loop (cdr chars) (cons 'RBRACE acc))]
        [(char=? (car chars) #\[) 
         (tokenize-loop (cdr chars) (cons 'LBRACKET acc))]
        [(char=? (car chars) #\]) 
         (tokenize-loop (cdr chars) (cons 'RBRACKET acc))]
		[(and (>= (length chars) 2)
			  (char=? (car chars) #\◊)
			  (char=? (cadr chars) #\'))
		 (tokenize-loop (cddr chars) (cons 'VAR acc))]
		; [(and (>= (length chars) 2)
          ; (char=? (car chars) #\◊)
          ; (char=? (cadr chars) #\!))
		;  (call-with-values
		;    ;; TODO amend so that we can retain kwargs
           ; (lambda () (read-braces-string (cdddr chars)))
           ; (lambda (content rest)
             ; (tokenize-loop rest (cons (list 'TRANSCLUDE content) acc))))]
		[(and (>= (length chars) 2)
          (char=? (car chars) #\◊)
          (char=? (cadr chars) #\$))
         (call-with-values
           (lambda () (read-braces-string (cdddr chars)))
           (lambda (content rest)
             (tokenize-loop rest (cons (list 'LATEX content) acc))))]
		;; read the input literally
		[(and (>= (length chars) 4)
		   (char=? (car chars) #\◊)
		   (char=? (cadr chars) #\p)
		   (char=? (caddr chars) #\r)
		   (char=? (cadddr chars) #\e))
		 (call-with-values
		   (lambda () (read-braces-string-no-braces (cddddr chars)))
		   (lambda (content rest)
			 (define formatted-content (string-append (trim content) "\n"))
			 (tokenize-loop rest (cons (list 'PRE formatted-content) acc))))]
		[(char=? (car chars) #\◊)
		 (tokenize-loop (cdr chars) (cons 'LOZENGE acc))]
		[(char=? (car chars) #\newline)
		 (tokenize-loop (cdr chars) (cons 'NEWLINE acc))]
        [(char=? (car chars) #\')
         (call-with-values
           (lambda () (read-quoted chars))
           (lambda (quoted rest)
            (tokenize-loop rest (cons quoted acc))))]
        [(and (>= (length chars) 2)
              (char=? (car chars) #\#)
              (char=? (cadr chars) #\:))
			(tokenize-loop (cddr chars) (cons 'KW acc))]
        [else
         (call-with-values
		   (lambda () (read-string chars))
		   (lambda (str rest)
            (tokenize-loop rest (cons str acc))))])))


; (tokenize-loop (string->list "◊b[#:key1 'value]{hello}") '())

; '(LOZENGE "b" LBRACKET KW "key1 'value" RBRACKET LBRACE "hello" RBRACE)

; (parse "◊b{Fraisse limits} are model-theoretic constructions for producing a suitable nice yet countably infinite structure out of substructures.")

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

(define (parse val #:transcluding? [is-transcluding #f])
  (define tokens (tokenize-loop (string->list val) '()))

  ;;
  (define (parse-kwargs tokens)
  (define (loop acc tokens)
    (cond
      [(empty? tokens) (values (reverse acc) '())]
      [(eq? (car tokens) 'RBRACKET) (values (reverse acc) (cdr tokens))]
      [else (loop (cons (car tokens) acc) (cdr tokens))]))
  (loop '() tokens))
    
  ;;
  (define (parse-parens tokens)
    (define (loop acc tokens paren-depth)
      (cond
        [(empty? tokens)
          (values (string-join (reverse acc) " ") '())]
        [(eq? (car tokens) 'RPAREN)
         (if (= paren-depth 0)
             (values (string->expr (string-join (reverse acc) " ")) (cdr tokens))
             (loop (cons ")" acc) (cdr tokens) (- paren-depth 1)))]
        [(eq? (car tokens) 'LPAREN)
         (loop (cons "(" acc) (cdr tokens) (+ paren-depth 1))]
        [else
          (loop (cons (if (string? (car tokens)) (car tokens) (symbol->string (car tokens))) acc) (cdr tokens) paren-depth)]))
    (loop '() tokens 0))
    
  ;;
  (define (parse-braces tokens)
    (define (loop acc tokens paren-depth)
      (cond
        [(empty? tokens)
          (values (string-join (reverse acc) " ") '())]
        [(eq? (car tokens) 'RBRACE)
         (if (= paren-depth 0)
             (values (string->expr (string-join (reverse acc) " ")) (cdr tokens))
             (loop (cons "}" acc) (cdr tokens) (- paren-depth 1)))]
        [(eq? (car tokens) 'LBRACE)
         (loop (cons "{" acc) (cdr tokens) (+ paren-depth 1))]
        [else
          (loop (cons (if (string? (car tokens)) (car tokens) (symbol->string (car tokens))) acc) (cdr tokens) paren-depth)]))
    (loop '() tokens 0))
  
  ;; 
  (define (parse-cmd tokens #:arg-as-string [arg-as-string #false])
    (define head (string->symbol (car tokens)))
    (define tokens (cdr tokens))
    (cond
	  [(empty? tokens)
	    (values '() tokens)]
      
	  ;; case 1: command [kwargs] { content }
      [(and (not (null? tokens)) (eq? (car tokens) 'LBRACKET))
       (call-with-values
         (lambda () (parse-kwargs (cdr tokens)))
         (lambda (kwargs tokens)
		   (define kwargs (kw-list->mhash kwargs))
		   (if (and (not (null? tokens)) (eq? (car tokens) 'LBRACE))
               (call-with-values
                 (lambda () (parse-loop (cdr tokens)))
                 (lambda (content tokens)
                   (cond
					 [(eq? head '!)
					    (define transcluded (read-and-parse (car content) #:transcluding? #t))
					    (values `(,head ,kwargs ,@(cddr transcluded)) tokens)]
					 [else
				   (values `(,head ,kwargs ,@content) tokens)])))
               (values (list head kwargs '()) '()))))]
      
	  ;; case 2: command { content }
      [(and (not (null? tokens)) (eq? (car tokens) 'LBRACE))
       (call-with-values
         (lambda () (parse-loop (cdr tokens)))
         (lambda (content tokens)
		 (cond
		   [(eq? head '!)
			(define transcluded (read-and-parse (car content) #:transcluding #t))
			(values `(,head ,(mhash) ,@(cddr transcluded)) tokens)]
		   [else
		   ; (cond
			 ; [(eq? head '!)
			  ; (define transcluded (read-and-parse (car content)))
			  ; (values (list 'transclude (mhash) transcluded) tokens)]
			 ; [else
			  (values `(,head ,(mhash) ,@content) tokens)])))]
			
	  [else
		 (values '() tokens)]
      ; [else (error "Expected [ or { after command")]
	  ))

  ;;
  (define (parse-loop tokens)
    (define (loop acc tokens)
      (cond
  	  [(empty? tokens)
  	    (values (reverse acc) tokens)]
	  [(string? tokens)
	    (values tokens '())]
	  ; [(symbol? tokens)
		; (values tokens '())]
	  [(eq? (car tokens) 'RBRACE)
  		(values (reverse acc) (cdr tokens))]
	  [(and (eq? (car tokens) 'VAR) (eq? (cadr tokens) 'LPAREN))
		(call-with-values
		  (lambda () (parse-parens (cddr tokens)))
		  (lambda (content rest)
			;;  TODO only taking out the first element of the list
			(loop (cons (list 'var (car content)) acc) rest)))]
	  ;; DANGER OF INFINITE LOOP!!!
	  ; [(and (pair? (car tokens)) (eq? (caar tokens) 'TRANSCLUDE))
	  ;    (displayln (car tokens))
	  ;   (loop (cons (list 'transclude (read-and-parse (cadar tokens))) acc) (cdr tokens))] 
	  [(and (pair? (car tokens)) (eq? (caar tokens) 'LATEX))
		(loop (cons (list 'ltx (mhash) (cadar tokens)) acc) (cdr tokens))]
	[(and (pair? (car tokens)) (eq? (caar tokens) 'PRE))
		(loop (cons (list 'pre (mhash) (cadar tokens)) acc) (cdr tokens))]
	  ; [(eq? (car tokens) 'LATEX) 
		; (loop (list '$ (cadr tokens) acc) (cddr tokens))]
	  [(and (eq? (car tokens) 'LOZENGE) (not (empty? (cdr tokens))))
	    (cond
		  [(eq? (cadr tokens) 'LPAREN)
  	       (call-with-values
  	         (lambda () (parse-parens (cddr tokens)))
  	         (lambda (content rest)
  	           (loop (cons (list 'code content) acc) rest)))]
		  ; [(eq? (cadr tokens) '!)
		  ;   (call-with-values
			  ; (lambda () (parse-cmd-string) (cdr tokens))
			  ; (lambda () (cmd rest)
				; (loop (cons cmd acc) rest)))]
		  [else
  	        (call-with-values
  		      (lambda () (parse-cmd (cdr tokens)))
  		      (lambda (cmd rest)
  		        (loop (cons cmd acc) rest)))] 
		  )]
  	  [else
  		(begin
  		  (loop (cons (car tokens) acc) (cdr tokens)))]))
    (loop '() tokens))
  (if (null? tokens)
    '()
      (call-with-values
        (lambda () (parse-loop tokens))
        (lambda (cmd remaining)
          (if (null? remaining)
			;; TODO parsing just a string should not return an error
			(if is-transcluding `(root ,@cmd) `(root ,(mhash) ,@cmd))
            (begin
			  (error "Unexpected tokens after command")))))))

(define (read-and-parse file #:transcluding? [is-transcluding #f])
  (define port (open-input-file file))
  (define content (read-port-to-string port))
  (define parsed (parse content #:transcluding is-transcluding))
  parsed)

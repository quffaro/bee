
(provide parse)

(define (string->expr str)
  (read (open-input-string (string-append "(" str ")"))))

;; PARSING

(define (char-whitespace? c)
    (or 
	  ; (char=? c #\space) 
	  (char=? c #\tab) 
      ; (char=? c #\newline) 
	  ; (char=? c #\return)
	  ))
  
(define (char-delimiter? c)
  (or (char=? c #\{) (char=? c #\})
	  (char=? c #\() (char=? c #\))
      (char=? c #\[) (char=? c #\])))
 
;; TODO replace with Newline(n)

(define (skip-whitespace chars)
  (cond [(null? chars) '()]
        ; [(char-whitespace? (car chars)) 
         ; (skip-whitespace (cdr chars))]
        [else chars]))

(define (read-string chars)
   (define (loop acc chars)
     (cond [(null? chars) (values (list->string (reverse acc)) '())]
           [(char-whitespace? (car chars)) 
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

(define (parse val)
  (define tokens (tokenize-loop (string->list val) '()))

  (define (parse-kwargs tokens)
  (define (loop acc tokens)
    (cond
      [(empty? tokens) (values (reverse acc) '())]
      [(eq? (car tokens) 'RBRACKET) (values (reverse acc) (cdr tokens))]
      [else (loop (cons (car tokens) acc) (cdr tokens))]))
  (loop '() tokens))

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

  (define (parse-cmd tokens)
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
           ; (values (list head kwargs) tokens)))]
		   (if (and (not (null? tokens)) (eq? (car tokens) 'LBRACE))
               (call-with-values
                 (lambda () (parse-loop (cdr tokens)))
                 (lambda (content tokens)
                   (values (list head kwargs content) tokens)))
               (values (list head kwargs '()) '()))))]
      ;; case 2: command { content }
      [(and (not (null? tokens)) (eq? (car tokens) 'LBRACE))
       (call-with-values
         (lambda () (parse-loop (cdr tokens)))
         (lambda (content tokens)
           (values (cons head content) tokens)))]
	  [else
		 (values '() tokens)]
      ; [else (error "Expected [ or { after command")]
	  ))
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
	  [(and (eq? (car tokens) 'LOZENGE) (not (empty? (cdr tokens))))
	    (cond
		  [(eq? (cadr tokens) 'LPAREN)
  	       (call-with-values
  	         (lambda () (parse-parens (cddr tokens)))
  	         (lambda (content rest)
  	           (loop (cons (list 'code content) acc) rest)))]
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
			(begin
			  ; (displayln cmd)
            cmd)
            (begin
			  (error "Unexpected tokens after command")))))))

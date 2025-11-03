;; the document needs to store a tree of found files.

;; see busybee tests for a case where this is useful

(define (transclude-runner parsed)
  (transduce parsed 
	(flat-mapping (lambda (elem)
	   (cond
		 [(and (list? elem) (eq? (car elem) '!))
		  (transclude (cadr elem))]
		 [else (list elem)])))
	(into-list)))

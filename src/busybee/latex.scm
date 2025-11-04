(define-tag (b tex) (attrs els)
  `(txt "\\textbf{" ,@els "}"))

(define-tag (em tex) (attrs els)
 `(txt "\\textit{" ,@els "}"))

(define-tag (def tex) (attrs els)
 `(txt "\\textbf{" ,@els "}"))

(define-tag (section tex) (attrs els)
 `(txt "\\section{" ,@els "}"))

(define-tag (ltx tex) (attrs els)
 `(txt "$" ,@els "$"))

(define-tag (cite tex) (attrs els)
  (define src (attr-val attrs 'src))
  `(txt ,@src ,@els))

;; busybee-specific

(define-tag (transclude tex) (attrs els)
  `(txt ,@els))

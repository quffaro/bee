(define-tag (b ltx) (attrs els)
  `(txt "\\textbf{" ,@els "}"))

(define-tag (section ltx) (attrs els)
  `(txt "\\textbf{" ,@els "}"))

(define-tag (cite ltx) (attrs els)
  `(txt "\\textbf{" ,@els "}"))

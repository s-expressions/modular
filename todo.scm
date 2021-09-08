;;;; Modular S-expression reader

;;; API:

;; (reader &rest rules)
;; (reader-union &rest readers)  ; On conflict, rightmost reader wins.

;;; What it reads:

;; whitespace
;; datum:
;;   list
;;   word      symbol keyword number
;;   string    symbol keyword string comment
;;   dispatch  char word else
;;   error     "Error message"

;;; Standard syntax:

(define quasiquote-reader
  (reader
   ("'"  datum tag quote)
   ("`"  datum tag quasiquote)
   (","  (dispatch
          (char
           ("@" datum tag unquote-splicing))
          (else datum tag unquote)))))

(define common-lisp-reader
  (reader-union
   quasiquote-reader
   (reader
    ("("  list   ")")
    ("|"  string "|" tag symbol)
    (";"  string "\n" tag comment)
    ("\"" string "\"")
    ("#"  (dispatch
           (char
            ("(" list ")" tag vector)
            ("A" datum tag array)
            ("B" datum tag binary)
            ("O" datum tag octal)
            ("X" datum tag hex)
            ("P" datum tag pathname)
            ("S" datum tag structure)
            (";" datum tag comment)
            ("+" datum tag conditional+)
            ("-" datum tag conditional-)
            ("|" nestable-string "#|" "|#" tag comment)
            ("<" error "Unreadable object")
            (" " error "Whitespace after #")))))))

(define scheme-reader/r5rs
  (reader
   quasiquote-reader
   ("(" list ")")
   ("\"" string "\"")
   (";"  string "\n" tag comment)
   ("#"  (dispatch
          (char
           ("(" list ")" tag vector)
           ("B" datum tag binary)
           ("O" datum tag octal)
           ("X" datum tag hex)
           (";" datum tag comment)
           ("|" nestable-string "#|" "|#" tag comment)
           (" " (error "Whitespace after #")))))))

(define scheme-reader/r6rs
  (reader-union
   scheme-reader/r5rs
   (reader
    ("#"  (dispatch
           (word
            ("vu8" datum tag bytevector)))))))

(define scheme-reader/r7rs
  (reader-union
   scheme-reader/r5rs
   (reader
    ("|"  string "|" tag symbol)
    ("#"  (dispatch
           (word
            ("u8" datum tag bytevector)))))))

(define edn-reader
  (reader
   ("(" list ")" tag list)
   ("[" list "]" tag vector)
   ("{" list "}" tag map)
   ("\"" string "\"")
   (";"  string "\n" tag comment)
   ("#" (dispatch
         (char
          ("{" list "}" tag set))))))

;;; Custom syntax:

(define clojure-reader
  (reader-union
   edn-reader
   (reader
    ("'"  datum tag quote))))

(define gauche-reader
  (reader-union
   scheme-reader/r5rs
   (reader
    ("[" list "]")
    (":" datum tag keyword)
    ("#" (dispatch
          (char
           ("!" datum tag directive)
           ("\"" string "\"" tag interpolated-string)
           ("/" string "/" tag regexp)
           (":" datum tag uninterned-symbol)))))))

(define dollar-string-reader
  (reader
   ("$" (dispatch
         (char
          (" " string "\n")
          ("(" string ")")
          ("[" string "]")
          ("{" string "}")
          ("|" string "|"))))))

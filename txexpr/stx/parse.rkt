#lang racket/base

(provide ~txexpr
         define-txexpr-pattern-expander
         (for-syntax make-txexpr-pattern-expander))

(require syntax/parse
         txexpr/stx
         (for-syntax racket/base
                     racket/syntax
                     syntax/parse))

;; ---------------------------------------------------------

;; Syntax Parse Patterns for TXexprs

;; {~txexpr tag-pat attrs-pat elements-pat}
#;{Examples:
   > (syntax-parse #'(span ([style "color: red"]) "I am" "angry")
       #:datum-literals [span style]
       [{~txexpr span ([style sty]) (elem1 elem2)}
        (list #'sty #'elem1 #'elem2)])
   (list <syntax:"color: red"> <syntax:"I am"> <syntax:"angry">)}

(define-syntax ~txexpr
  (pattern-expander
   (syntax-parser
     [(_ tag-pat attrs-pat elements-pat)
      #:with stx (generate-temporary 'stx)
      #'(~and stx
              (~fail #:unless (stx-txexpr? #'stx))
              (~parse [tag-pat attrs-pat elements-pat]
                      (stx-txexpr->list #'stx)))])))

(define-syntax-class (datum=? dat)
    #:attributes []
    [pattern stx
             #:fail-unless (equal? (syntax->datum #'stx) dat)
             (format "expected ~s" dat)])

(begin-for-syntax
  (define (make-txexpr-pattern-expander tag-symbol)
    (pattern-expander
     (syntax-parser
       [(_ attrs-pat elements-pat)
        #`(~txexpr (~var _ (datum=? '#,tag-symbol))
                   attrs-pat
                   elements-pat)]))))

;; (define-txexpr-pattern-expander name tag)
#;{Examples:
   > (define-txexpr-pattern-expander ~span span)
   > (syntax-parse #'(span ([style "color: red"]) "I am" "angry")
       #:datum-literals [style]
       [{~span ([style sty]) (elem1 elem2)}
        (list #'sty #'elem1 #'elem2)])
   (list <syntax:"color: red"> <syntax:"I am"> <syntax:"angry">)}

(define-syntax define-txexpr-pattern-expander
  (syntax-parser
    [(_ name:id tag-symbol:id)
     #'(define-syntax name
         (make-txexpr-pattern-expander 'tag-symbol))]))


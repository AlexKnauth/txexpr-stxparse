#lang racket/base
(require racket/runtime-path
         xml
         txexpr/stx
         racket/format
         racket/string
         (rename-in syntax/parse [attribute @])
         txexpr/stx/parse)
(module+ test
  (require rackunit))

(define-runtime-path file.xml "file.xml")

(define-txexpr-pattern-expander ~measure measure)
(define-txexpr-pattern-expander ~attributes attributes)
(define-txexpr-pattern-expander ~divisions divisions)
(define-txexpr-pattern-expander ~key key)
(define-txexpr-pattern-expander ~fifths fifths)
(define-txexpr-pattern-expander ~time time)
(define-txexpr-pattern-expander ~beats beats)
(define-txexpr-pattern-expander ~beat-type beat-type)
(define-txexpr-pattern-expander ~clef clef)
(define-txexpr-pattern-expander ~sign sign)
(define-txexpr-pattern-expander ~line line)
(define-txexpr-pattern-expander ~note note)
(define-txexpr-pattern-expander ~pitch pitch)
(define-txexpr-pattern-expander ~step step)
(define-txexpr-pattern-expander ~octave octave)
(define-txexpr-pattern-expander ~duration duration)
(define-txexpr-pattern-expander ~type type)

(define-syntax-class snum
  #:attributes [num]
  [pattern s:str
           #:attr num (string->number (syntax-e #'s))
           #:when (@ num)])

(define-splicing-syntax-class ws  ; whitespace
  #:attributes []
  [pattern {~seq s:str ...}
           #:when (for*/and ([s (in-list (@ s))] [c (in-string (syntax-e s))])
                    (char-whitespace? c))])

(define-syntax-class key-sig
  #:attributes [fifths string]
  [pattern {~key () (:ws {~fifths () (fifths-str:snum)} :ws)}
           #:attr fifths (@ fifths-str.num)
           #:attr string
           (if (not (negative? (@ fifths))) ; circle of fifths
               (list-ref '("C" "G" "D" "A" "E" "B F#") (@ fifths))
               (list-ref '("C" "F" "B♭" "E♭" "A♭" "D♭ G♭") (- (@ fifths))))])

(define-syntax-class time-sig
  #:attributes [string]
  [pattern {~time () (:ws {~beats () (numerator:snum)}
                      :ws {~beat-type () (denominator:snum)} :ws)}
           #:attr string (format "~a/~a"
                                 (@ numerator.num)
                                 (@ denominator.num))])

(define-syntax-class clef
  [pattern {~clef () (:ws {~sign () ("G")} :ws {~line () ("2")} :ws)}
           #:attr string "Treble Clef"]
  [pattern {~clef () (:ws {~sign () ("F")} :ws {~line () ("4")} :ws)}
           #:attr string "Bass Clef"]
  [pattern {~clef () (:ws {~sign () ("C")} :ws {~line () ("3")} :ws)}
           #:attr string "Alto Clef"])

(define-syntax-class pitch
  #:attributes [string]
  [pattern {~pitch ()
             (:ws {~step () (letter:str)}
              :ws {~octave () (octave:snum)} :ws)}
           #:attr string (format "~a~a"
                                 (syntax-e #'letter)
                                 (string-ref "₀₁₂₃₄₅₆₇₈₉" (@ octave.num)))])

(define-syntax-class note
  #:attributes [string]
  [pattern {~note ()
             (:ws pitch:pitch
              :ws {~duration () (dur:snum)}
              _ ...)}
           #:attr string (~a (@ pitch.string)
                             #:min-width (* 4 (@ dur.num))
                             #:right-pad-string "-")])

;(syntax:read-xml (open-input-file file.xml))

(define (read-measure in)
  (syntax-parse (syntax:read-xml in)
    #:datum-literals [number]
    [{~measure ([number N:snum])
       (:ws
        {~attributes ()
          ({~alt {~once key:key-sig}
                 {~once time:time-sig}
                 {~once clef:clef}
                 _}
           ...)}
        :ws
        {~seq note:note
              :ws}
        ...)}
     (format "~a, ~a, ~a:\n~a"
             (@ clef.string)
             (@ time.string)
             (@ key.string)
             (string-join (@ note.string)))]))


(module+ test
  (check-equal?
   (read-measure (open-input-file file.xml))
   #<<```
Treble Clef, 4/4, C:
C₄------ D₄-- E₄--
```
   ))


# txexpr-stxparse
syntax-parse patterns for parsing Tagged X-expressions

```racket
(require txexpr/stx/parse)
```

<br>

```racket
(~txexpr tag-pat attrs-pat elements-pat)                              syntax-parse pattern
```

Matches txexprs where the tag matches `tag-pat`, the attributes-list matches `attrs-pat`, and the elements-list matches `elements-pat`.

Examples:
```racket
> (syntax-parse #'(span ([style "color: red"]) "I am" "angry")
    #:datum-literals [span style]
    [{~txexpr span ([style sty]) (elem1 elem2)}
     (list #'sty #'elem1 #'elem2)])
(list #<syntax:"color: red"> #<syntax:"I am"> #<syntax:"angry">)
```

<br>

```racket
(define-txexpr-pattern-expander name tag)                             syntax
```

Defines `name` as a syntax-parse _pattern expander_ that regonizes txexprs tagged with `tag`.

Examples:
```racket
> (define-txexpr-pattern-expander ~span span)
> (syntax-parse #'(span ([style "color: red"]) "I am" "angry")
    #:datum-literals [style]
    [{~span ([style sty]) (elem1 elem2)}
     (list #'sty #'elem1 #'elem2)])
(list #<syntax:"color: red"> #<syntax:"I am"> #<syntax:"angry">)
```

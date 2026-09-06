;; extends

; extends the bundled PHP queries so the splits Sublime's Mariana makes are
; available as captures: a class being *declared* is not painted like a class
; being *referenced*, and extends/implements are storage modifiers, not keywords.

; class/interface/trait/enum being declared -- orange
(class_declaration name: (name) @type.definition)
(interface_declaration name: (name) @type.definition)
(trait_declaration name: (name) @type.definition)
(enum_declaration name: (name) @type.definition)

; inherited classes, implemented interfaces and imported traits -- cyan
(base_clause (name) @type.inherited)
(class_interface_clause (name) @type.inherited)
(use_declaration (name) @type.inherited)

; `extends` / `implements` read as storage modifiers -- red
(base_clause "extends" @keyword.modifier)
(class_interface_clause "implements" @keyword.modifier)

; `const` is a declaration keyword like `class`/`function` -- purple
(const_declaration "const" @keyword.type)

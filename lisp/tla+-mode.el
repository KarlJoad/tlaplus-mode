;;; tla+-mode.el --- Major mode for TLA+  -*- lexical-binding:t; coding:utf-8 -*-

;; Copyright (C) 2024 Raven Hallsby

;; Author: Raven Hallsby <karl@hallsby.com>
;; Maintainer: Raven Hallsby <karl@hallsby>

;; Homepage: https://github.com/KarlJoad/tla+-mode
;; Keywords: TLA+ languages tree-sitter

;; Package-Version: 0.0.1-git
;; Package-Requires: (
;;     (emacs "29.1"))

;; SPDX-License-Identifier: GPL-3.0-or-later

;; tla+-mode is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; tla+-mode is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with tla+-mode.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; tla+-mode is a major-mode for TLA+ that leverages the excellent
;; tree-sitter-tlaplus tre-sitter parser for unmatched syntax highlighting
;; accuracy and REPL tools to provide an interactive development environment
;; for both TLC- and Apalache-checked models and TLAPS-proved theorems.

;; tla+-mode inherits code from two major sources:
;;   1. https://github.com/carlthuringer/tla-mode
;;   2. https://git.sdf.org/bch/tlamode
;; The first variant used tree-sitter to provide excellent syntax highlighting.
;; The second included many helpful tools, and keybindings, such as being able
;; to access tlc2-repl from within Emacs.

;;; Code:

(require 'treesit)
(require 'comint)
(eval-when-compile (require 'rx))

(autoload 'comint-mode "comint")

(defgroup tla+ nil
  "Support for the TLA+ model specification language."
  :tag "TLA+"
  :group 'languages
  :version "29.1"
  :link '(custom-manual "(tla+) Top")
  :link '(info-link "(tla+) Customization")
  :link '(url-link "https://github.com/KarlJoad/tla+-mode")
  :link '(emacs-commentary-link :tag "Commentary" "tla+-mode.el")
  :link '(emacs-library-link :tag "Lisp File" "tla+-mode.el"))

(defun tla+-mode-comment-setup ()
  "Set up local variables for TLA+ comments.

Set up:
 - `comment-start'
 - `comment-end'
 - `comment-start-skip'
 - `comment-end-skip'
 - `adaptive-fill-mode'
 - `adaptive-fill-first-line-regexp'
 - `paragraph-start'
 - `paragraph-separate'
 - `fill-paragraph-function'"

  ;; \* is a line-comment, (* *) is a block comment, which can cover multiple
  ;; lines.
  (setq-local comment-start "\\*")
  (setq-local comment-end "")

  (setq-local comment-start-skip (rx (or (seq "\\" (+ "*"))
                                         (seq "(" (+ "*")))
                                     (* (syntax whitespace))))
  (setq-local comment-end-skip
              (rx (* (syntax whitespace))
                  (group (or (syntax comment-end)
                             (seq (+ "*") ")")))))

  (setq-local adaptive-fill-mode t)

  ;; This matches (1) empty spaces (the default), (2) "\*", (3) "(*",
  ;; but do not match "*)", because we don't want to use "*)" as
  ;; prefix when filling.  (Actually, it doesn't matter, because
  ;; `comment-start-skip' matches "(*" which will cause
  ;; `fill-context-prefix' to use "(*" as a prefix for filling, that's
  ;; why we mask the "(*" in `tla+-mode--fill-paragraph'.)
  (setq-local adaptive-fill-regexp
              (concat (rx (* (syntax whitespace))
                          (group (seq (or "\\" "(") (+ "*") (* "*"))))
                      adaptive-fill-regexp))
  ;; Note the missing * comparing to `adaptive-fill-regexp'.  The
  ;; reason for its absence is a bit convoluted to explain.  Suffice
  ;; to say that without it, filling a single line paragraph that
  ;; starts with /* doesn't insert * at the beginning of each
  ;; following line, and filling a multi-line paragraph whose first
  ;; two lines start with * does insert * at the beginning of each
  ;; following line.  If you know how does adaptive filling works, you
  ;; know what I mean.
  (setq-local adaptive-fill-first-line-regexp
              (rx bos
                  (seq (* (syntax whitespace))
                       (group (seq "/" (+ "/")))
                       (* (syntax whitespace)))
                  eos))
  ;; Same as `adaptive-fill-regexp'.
  (setq-local paragraph-start
              (rx (or (seq (* (syntax whitespace))
                           (group (or (seq "/" (+ "/")) (* "*")))
                           (* (syntax whitespace))
                           ;; Add this eol so that in
                           ;; `fill-context-prefix', `paragraph-start'
                           ;; doesn't match the prefix.
                           eol)
                      "\f")))
  (setq-local paragraph-separate paragraph-start)
  (setq-local fill-paragraph-function #'tla+-mode--fill-paragraph))

(defvar tla+-mode--syntax-table
  (let ((table (make-syntax-table)))
    ;; Treat underscores as symbol constiuents
    (modify-syntax-entry ?_ "_" table)

    ;; TLA+ has 2 comment syntaxes, (* block *) and \* line.
    ;; The 1 means that both the ( character and \ character are the first
    ;; characters that start the two-character comment sequence.
    ;; However, more heavily uses (* *), so that is marked as the "a" comment
    ;; sequence style.
    (modify-syntax-entry ?\( "()1" table)
    ;; Treat the \ as punctuation so that it can be used as an operator/keyword
    ;; but if * is found immediately after, the sequence \* is treated as a
    ;; comment.
    (modify-syntax-entry ?\\ ". 1b" table)
    ;; The * needs to be treated as a punctuation character to not mess up
    ;; highlighting of normal multiplication.
    (modify-syntax-entry ?* ". 23" table)
    (modify-syntax-entry ?\) ")(4" table)
    ;; Return characters end the line-comment sequence.
    (modify-syntax-entry ?\n "> b" table)
    (modify-syntax-entry ?\m "> b" table)
    table)
  "Syntax table for `tla+-mode'.")

(defvar treesit-load-name-override-list)

(defun tla+-mode--set-modeline ()
  "Set Emacs modeline with this major-mode's name."
  (setq mode-name "TLA+")
  (force-mode-line-update))

(defvar tla-ts-mode--builtin
  '((nat_number_set) (boolean_set) (int_number_set) (real_number_set) (string_set))
  "List of sets built into TLA+.")

(defvar tla-ts-mode--constant
  '("TRUE" "FALSE")
  "List of constant values in TLA+.")

(defvar tla-ts-mode--numbers
  '((nat_number) (real_number) (octal_number) (hex_number) (binary_number))
  "TLA+'s tree-sitter's notion of numbers.")

(defvar tla-ts-mode--delimiters
  '((langle_bracket) (rangle_bracket) (rangle_bracket_sub) "{" "}" "[" "]" "]_" "(" ")")
  "TLA+'s delimiters.")

(defvar tla-ts-mode--misc-punctuation
  '(
    ","
    ":"
    "."
    "!"
    (bullet_conj)
    (bullet_disj))
  "TLA+'s punctuation.")

(defvar tla-ts-mode--operators
  '( (amp)
     (ampamp)
     (approx)
     (assign)
     (asymp)
     (bigcirc)
     (bnf_rule)
     (bullet)
     (cap)
     (cdot)
     (circ)
     (compose)
     (cong)
     (cup)
     (div)
     (dol)
     (doldol)
     (doteq)
     (dots_2)
     (dots_3)
     (eq)
     (equiv)
     (excl)
     (geq)
     (gg)
     (gt)
     (hashhash)
     (iff)
     (implies)
     (in)
     (land)
     (ld_ttile)
     (leads_to)
     (leq)
     (ll)
     (lor)
     (ls_ttile)
     (lt)
     (map_from)
     (map_to)
     (minus)
     (minusminus)
     (mod)
     (modmod)
     (mul)
     (mulmul)
     (neq)
     (notin)
     (odot)
     (ominus)
     (oplus)
     (oslash)
     (otimes)
     (plus)
     (plus_arrow)
     (plusplus)
     (pow)
     (powpow)
     (prec)
     (preceq)
     (propto)
     (qq)
     (rd_ttile)
     (rs_ttile)
     (setminus)
     (sim)
     (simeq)
     (slash)
     (slashslash)
     (sqcap)
     (sqcup)
     (sqsubset)
     (sqsubseteq)
     (sqsupset)
     (sqsupseteq)
     (star)
     (subset)
     (subseteq)
     (succ)
     (succeq)
     (supset)
     (supseteq)
     (times)
     (uplus)
     (vert)
     (vertvert)
     (wr)
     ;; bound_prefix_op symbols
     (always)
     (domain)
     (enabled)
     (eventually)
     (lnot)
     (negative)
     (powerset)
     (unchanged)
     (union)
     ;; bound_postfix_op symbols
     (asterisk)
     (prime)
     (sup_hash)
     (sup_plus))
  "TLA+ operators.")

(defvar tla+-mode--keywords
  '("ACTION"
    "ASSUME"
    "ASSUMPTION"
    "AXIOM"
    "BY"
    "CASE"
    "CHOOSE"
    "CONSTANT"
    "CONSTANTS"
    "COROLLARY"
    "DEF"
    "DEFINE"
    "DEFS"
    "DOMAIN"
    "ELSE"
    "ENABLED"
    "EXCEPT"
    "EXTENDS"
    "HAVE"
    "HIDE"
    "IF"
    "IN"
    "INSTANCE"
    "LAMBDA"
    "LEMMA"
    "LET"
    "LOCAL"
    "MODULE"
    "NEW"
    "OBVIOUS"
    "OMITTED"
    "ONLY"
    "OTHER"
    "PICK"
    "PROOF"
    "PROPOSITION"
    "PROVE"
    "QED"
    "RECURSIVE"
    "SF_"
    "STATE"
    "SUBSET"
    "SUFFICES"
    "TAKE"
    "TEMPORAL"
    "THEN"
    "THEOREM"
    "UNCHANGED"
    "UNION"
    "USE"
    "VARIABLE"
    "VARIABLES"
    "WF_"
    "WITH"
    "WITNESS"
    (def_eq)
    (set_in)
    (gets)
    (forall)
    (exists)
    (temporal_forall)
    (temporal_exists)
    (all_map_to)
    (maps_to)
    (case_box)
    (case_arrow)
    (address)
    (label_as))
  "TLA+ keywords.")

(defvar tla+-mode-treesit-font-lock-feature-list
  '((module module-boundary comment)
    (builtin string numbers)
    (keyword extend declaration definition identifier)
    (operator delimiter misc-punctuation assume))
  "Alist of symbols for features used in tree-sitter font-lock rules.")

(defun tla+-mode--font-lock-settings ()
  "Tree-sitter font-lock settings."
  (treesit-font-lock-rules
   :language 'tlaplus
   :override t
   :feature 'module
   `((module
      (header_line) @font-lock-warning-face
      name: (identifier) @font-lock-type-face
      (header_line) @font-lock-warning-face)
     )

   :language 'tlaplus
   :override t
   :feature 'keyword
   `(([,@tla+-mode--keywords] @font-lock-keyword-face)
     )

   :language 'tlaplus
   :override t
   :feature 'builtin
   `(([,@tla-ts-mode--builtin] @font-lock-builtin-face)
     ([,@tla-ts-mode--constant] @font-lock-constant-face)
     )

   ;; Assumptions are marked in the warning face because they could be dangerous
   ;; and must be checked for correctness. We _really_ want to call them out.
   ;; NOTE: This highlights the ENTIRE assumption with the warning color!
   :language 'tlaplus
   :override t
   :feature 'assume
   `(((assumption "ASSUME" _) @font-lock-warning-face)
     )

   :language 'tlaplus
   :override t
   :feature 'extend
   `(((extends "EXTENDS" _) @font-lock-preprocessor-face)
     )

   :language 'tlaplus
   :override t
   :feature 'declaration
   `(
     ;; FIXME: Highlights entire line, only highlight the constants!
     ((constant_declaration "CONSTANTS" _) @font-lock-constant-face)
     ((variable_declaration "VARIABLES" _) @font-lock-variable-name-face)
     )

   :language 'tlaplus
   :override t
   :feature 'definition
   `((operator_definition
      name: (identifier) @font-lock-variable-name-face
      ;; FIXME: Highlight parameters, if they are present!
      )
     ;; A quantifier_bound "defines" variables for a subsequent expression
     (quantifier_bound (identifier) @font-lock-variable-name-face)
     )

   :language 'tlaplus
   :override 'keep
   :feature 'identifier
   `((identifier_ref) @font-lock-variable-use-face
     )

   :language 'tlaplus
   :override t
   :feature 'operator
   `([,@tla-ts-mode--operators] @font-lock-operator-face
     )

   :language 'tlaplus
   :override t
   :feature 'delimiter
   `([,@tla-ts-mode--delimiters ] @font-lock-bracket-face
     )

   :language 'tlaplus
   :feature 'misc-punctuation
   `([,@tla-ts-mode--misc-punctuation] @font-lock-misc-punctuation-face
     )

   :language 'tlaplus
   :override 'keep
   :feature 'module-boundary
   `((double_line) @font-lock-warning-face
     )

   :language 'tlaplus
   :override 'keep
   :feature 'string
   `((string) @font-lock-string-face
     )

   :language 'tlaplus
   :override t
   :feature 'numbers
   `([,@tla-ts-mode--numbers] @font-lock-number-face
     )

   :language 'tlaplus
   :override 'keep
   :feature 'comment
   ;; FIXME: Block comments are still highlighting start "(" and end ")"
   `(((block_comment) @font-lock-comment-face)
     (comment) @font-lock-comment-face
     (extramodular_text) @font-lock-comment-face
     )))

;;;###autoload
(define-derived-mode tla+-mode prog-mode "TLA+"
  "Major mode for TLA+ specifications, powered by tree-sitter.

Key bindings:
\\{tla+-mode-map}

Configuration:
	   You must at least set the variable to the TLA2 Toolbox.  This
	   can be done by setting the variable in the Emacs configuration
	   file (i.e. ~/.emacs or ~/.emacs.d/init.el)
	      (setq tla+-tlatools-path </path/to/tla2tools.jar>)
	   or with:
	      \\[execute-extended-command] \"customize-group\" <RET> tla+

	   You may also set the following paths:
	      tla+-java-path
	      tla+-dvipdf-path
	      tla+-dvips-path
	      tla+-tla+-tlatex-arguments
	   TLC options can be set globally or in the TLC configuration
	   GUI dialogue:
	      tla+-tlc-deadlock
	      tla+-tlc-simulate
	      tla+-tlc-depth
	      tla+-tlc-coverage
	      tla+-tlc-workers
	   To get help on one of the variables:
	      \\[describe-variable] <variablename>
	      \\[execute-extended-command] describe-variable <variablename>"
  :group 'tla+
  :syntax-table tla+-mode--syntax-table
  :after-hook (tla+-mode--set-modeline)

  ;; Comments
  ;; Teach Emacs what TLA+'s comments use as delimiters
  (tla+-mode-comment-setup)

  ;; Electric
  (setq-local electric-indent-chars
              (append "{}()<>" electric-indent-chars))

  ;; Configuration that is only possible if tree-sitter is present and ready
  ;; for TLA+ code.
  ;; FIXME: We only support tree-sitter-based parsing, so if you do NOT have
  ;; tree-sitter, we should really error and print a message.
  (when (treesit-ready-p 'tlaplus)
    (treesit-parser-create 'tlaplus)

    ;; Font-locking (Syntax Highlighting)
    ;; (setq-local treesit-font-lock-feature-list
    ;;             '((comment definition)
    ;;               (keyword preprocessor string type)
    ;;               (assignment constant escape-sequence label literal)
    ;;               (bracket delimiter error function operator property variable)))
    (setq-local treesit-font-lock-feature-list
                tla+-mode-treesit-font-lock-feature-list)
    (setq-local treesit-font-lock-settings (tla+-mode--font-lock-settings))

    ;; Finally, set up Emacs' treesit manager & tree-sitter for use.
    (treesit-major-mode-setup))

  ;; Indentation should use spaces not tabs
  (setq-local indent-tabs-mode 'nil))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.tla" . tla+-mode))

;;;
;;; Top-bar menu for TLA+-mode
(easy-menu-define tla+-mode-menu (list tla+-mode-map)
  "Menu for `tla+-mode'."
  '("TLA+"
    ["Do something (PLACEHOLDER)" (lambda () ())
     :help "Do something (PLACEHOLDER)"]))

(provide 'tla+-mode)
;;; tla+-mode.el ends here

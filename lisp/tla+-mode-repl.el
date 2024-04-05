;;; tla+-mode-repl.el --- Configure TLA+'s REPL  -*- lexical-binding:t; coding:utf-8 -*-

;; Copyright (C) 2024 Raven Hallsby

;; Author: Raven Hallsby <karl@hallsby.com>
;; Maintainer: Raven Hallsby <karl@hallsby>

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

;; TLA+'s toolbox also contains a REPL version of TLC for tinkering.
;; We use Emacs' excellent comint-mode to make an easy-to-use and intuitive
;; REPL experience that wraps TLC's REPL.

;;; Code:

(require 'comint)
(require 'tla+-mode-progs)
(eval-when-compile (require 'rx)) ; Highlight keywords in REPL

(autoload 'comint-mode "comint")

(defcustom tla+-tlc-repl-arguments
  (list)
  "Arguments to provide when starting TLA+'s REPL.
This is used by `run-tla+'."
  :version "29.1"
  :type '(repeat 'string)
  :group 'tla+)

(defvar tla+-tlc-repl-mode-map
  (let ((map (nconc (make-sparse-keymap) comint-mode-map)))
    ;; Allow <tab> to perform completion
    (keymap-set map "<tab>" #'completion-at-point)
    map)
  "Basic mode-map for `run-tla+'.")

(defvar tla+-tlc-repl-prompt-regexp
  "^\\(?:tla?:\\)"
  "Prompt for `run-tla+'.
NOTE: The default prompt used by tlc2-repl is \"(tla+) \".")

(defvar tla+-tlc-repl-buffer-name "*TLA+*"
  "Name of the buffer to use for the `run-tla+' comint instance.")

(defun run-tla+ ()
  "Run an inferior instance of `tlc2-repl' inside Emacs."
  (interactive)
  (save-excursion
    (tla+-shell-with-environment
      (let* ((tla+-tlc-repl-program tla+-tlc-repl-path)
             (buffer (get-buffer-create tla+-tlc-repl-buffer-name))
             (proc-alive (comint-check-proc buffer))
             (process (get-buffer-process buffer)))
        ;; If the process is dead then re-create the process and reset the
        ;; mode.
        (unless proc-alive
          (with-current-buffer buffer
            (apply #'make-comint-in-buffer "TLA+" buffer
                   tla+-tlc-repl-program nil tla+-tlc-repl-arguments)
            (tla+-tlc-repl-mode)))
        ;; Regardless, provided we have a valid buffer, we pop to it.
        (when buffer
          (pop-to-buffer buffer))))))

(defun tla+-repl--initialize ()
  "Helper function to initialize TLA+'s TLC REPL."
  (setq comint-process-echoes t)
  (setq comint-use-prompt-regexp t))

(define-derived-mode tla+-repl-mode comint-mode "TLA+-REPL"
  "Major mode for `run-tla+-repl'.

\\<tla+-tlc-repl-mode-map>"
  :group 'tla+

  ;; Set comint's knowledge of the REPL's prompt
  (setq comint-prompt-regexp tla+-tlc-repl-prompt-regexp)
  ;; Make entire buffer read-only. This is contentious as some prefer the
  ;; buffer to be overwritable.
  (setq comint-prompt-read-only t)
  ;; Ensure commands like M-{ and M-} work.
  (set (make-local-variable 'paragraph-separate) "\\'")
  ;; We do not use tree-sitter for the REPL, because that does not really
  ;; make sense.
  (set (make-local-variable 'font-lock-defaults) '(tla+-tlc-repl-font-lock-keywords t))
  ;; Make the REPL prompt the beginning of the "paragraph".
  (set (make-local-variable 'paragraph-start) tla+-tlc-repl-prompt-regexp))

(add-hook 'tla+-tlc-repl-mode-hook 'tla+-tlc-repl--initialize)

(defconst tla+-tlc-repl-keywords
  '("assume" "connect" "consistencylevel" "count" "create column family"
    "create keyspace" "del" "decr" "describe cluster" "describe"
    "drop column family" "drop keyspace" "drop index" "get" "incr" "list"
    "set" "show api version" "show cluster name" "show keyspaces"
    "show schema" "truncate" "update column family" "update keyspace" "use")
  "List of keywords to highlight in `tla+-tlc-repl-font-lock-keywords'.")

(defvar tla+-tlc-repl-font-lock-keywords
  (list
   ;; highlight all the reserved commands.
   `(,(concat "\\_<" (regexp-opt tla+-tlc-repl-keywords) "\\_>") . font-lock-keyword-face))
  "Additional expressions to highlight in `tla+-tlc-repl-mode'.")

(provide 'tla+-mode-progs)
;;; tla+-mode-repl.el ends here

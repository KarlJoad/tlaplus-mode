;;; tla+-mode-progs.el --- Variables setting paths to TLA+ programs -*- lexical-binding:t; coding:utf-8 -*-

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

;; TLA+'s tools use a variety of different programs to do their actual work.
;; Many of these tools are just command-line tools that can be invoked by Emacs
;; through a keybinding. However, the user could install these packages
;; anywhere.

;;; Code:

;; Paths to the various tools in the TLA+ toolbox.

(defcustom tla+-java-path "java"
	"Path to the `java' binary."
  :version "29.1"
	:type 'file
	:group 'tla+)

(defcustom tla+-tlatools-path
	nil
	"Path to the TLA+ `tlatools.jar' toolbox java archive."
  :version "29.1"
	:type 'file
	:group 'tla+)

(defcustom tla+-tlc-repl-path
  "tlc2-repl"
  "Path to the TLC REPL.
This path is used by `run-tla+'."
  :version "29.1"
  :type 'file
  :group 'tla+)

(defcustom tla+-dvipdf-path
	"dvipdf"
	"Path to the `dvipdf' program."
  :version "29.1"
	:type 'file
	:group 'tla+)

(defcustom tla+-dvips-path
	"dvips"
	"Path to the `dvips' program."
  :version "29.1"
	:type 'file
	:group 'tla+)

(defcustom tla+-repl-process-environment nil
  "List of overridden environment variables for subprocesses to inherit.
Each element should be a string of the form ENVVARNAME=VALUE.
When this variable is non-nil, values are exported into the
process environment before starting it.  Any variables already
present in the current environment are superseded by variables
set here."
  :version "29.1"
  :type '(repeat string)
  :group 'tla+)

(defmacro tla+-shell-with-environment (&rest body)
  "Modify shell environment during execution of BODY.
Temporarily sets variable `process-environment' and variable
`exec-path' during execution of body.  If `default-directory'
points to a remote machine then modifies
`tramp-remote-process-environment' and `TLA+-shell-remote-exec-path'
instead."
  (declare (indent 0) (debug (body)))
  `(tla+-repl--with-environment
    (tla+-repl--calculate-process-environment)
    (lambda () ,@body)))

(defun tla+-repl--with-environment (extraenv bodyfun)
  ;; FIXME: This is where the generic code delegates to Tramp.
  (let* ((vec
          (and (file-remote-p default-directory)
               (fboundp 'tramp-dissect-file-name)
               (ignore-errors
                 (tramp-dissect-file-name default-directory 'noexpand)))))
    (if vec
        (tla+-shell--tramp-with-environment vec extraenv bodyfun)
      (let ((process-environment
             (append extraenv process-environment))
            (exec-path
             (tla+-repl-calculate-exec-path)))
        (funcall bodyfun)))))

(defun tla+-repl-calculate-exec-path ()
  "Calculate variable`exec-path'.
Prepends `python-shell-exec-path' and adds the binary directory
for virtualenv if `python-shell-virtualenv-root' is set - this
will use the python interpreter from inside the virtualenv when
starting the shell.  If `default-directory' points to a remote host,
the returned value appends `python-shell-remote-exec-path' instead
of variable`exec-path'."
  (let ((new-path (copy-sequence
                   (if (file-remote-p default-directory)
                       ;; python-shell-remote-exec-path
                       exec-path
                     exec-path)))

        ;; Windows and POSIX systems use different venv directory structures
        ;; (virtualenv-bin-dir (if (eq system-type 'windows-nt) "Scripts" "bin"))
        )
    ;; (python-shell--add-to-path-with-priority
    ;;  new-path python-shell-exec-path)
    ;; (if (not python-shell-virtualenv-root)
    ;;     new-path
    ;;   (python-shell--add-to-path-with-priority
    ;;    new-path
    ;;    (list (expand-file-name virtualenv-bin-dir python-shell-virtualenv-root)))
    ;;   new-path)
    ;; Always return a new path
    new-path))

(defun tla+-repl--calculate-process-environment ()
  "Return a list of entries to add to the `process-environment'.
Prepends `TLA+-shell-process-environment', sets extra
TLA+paths from `TLA+-shell-extra-TLA+paths' and sets a few
virtualenv related vars."
  (let* (;; (virtualenv (when TLA+-shell-virtualenv-root
         ;;               (directory-file-name TLA+-shell-virtualenv-root)))
         (res tla+-repl-process-environment))
    ;; (when TLA+-shell-unbuffered
    ;;   (push "PYTHONUNBUFFERED=1" res))
    ;; (when TLA+-shell-extra-TLA+paths
    ;;   (push (concat "TLC2_REPL_PATH=" (TLA+-shell-calculate-TLA+path)) res))
    ;; (if (not virtualenv)
    ;;     nil
    ;;   (push "TLA+-HOME" res)
    ;;   (push (concat "VIRTUAL_ENV=" virtualenv) res))
    res))

;;;
(defcustom tla+-tlatex-arguments
  (list "-shade" "-number")
	;; " -shade -number "
	"List of strings to pass as arguments to `TLaTeX'."
  :version "29.1"
	:type '(repeat 'string)
	:group 'tla+)

(defcustom tla+-tlc-deadlock
  't
  ;; " -deadlock "
	"Should `TLC' check for deadlocks?"
  :version "29.1"
	:type 'boolean
  :safe #'booleanp
	:group 'tla+)

(defcustom tla+-tlc-simulate
  't
	;; " -simulate "
	"Should `TLC' perform simulation?"
  :version "29.1"
	:type 'boolean
  :safe #'booleanp
	:group 'tla+)

(defcustom tla+-tlc-depth
	1000
  ;; -depth tla+-tls-depth
	"Set maximum number of steps `TLC' may perform."
  :version "29.1"
	:type 'integer
  :safe #'integerp
	:group 'tla+)

(defcustom tla+-tlc-coverage
	"  "
	"Tell `TLC' to print coverage every X minutes."
  :version "29.1"
	:type 'string
	:group 'tla+)

(defcustom tla+-tlc-workers
  2
	;; " -workers 2 "
	"The number of worker threads should `TLC' use."
  :version "29.1"
	:type 'integer
  :safe #'integerp
	:group 'tla+)

(defcustom tla+-option-list
	'()
	"Alist of options to pass to `TLC'.

The key is a symbol for the name of the option to set, the value is a string
with its value."
  :version "29.1"
	:type '(alist :key-type 'symbol :value-type 'string)
  :group 'tla+)

(defcustom tla+-dot-convert
	"out.png"
	"If non-nil, convert `states.dot' to the filename given by the string."
  :version "29.1"
	:type 'string
  :group 'tla+)

(defcustom tla+-dot-binary
	nil
	"Path to `dot' binary."
  :version "29.1"
	:type 'file
  :group 'tla+)

(provide 'tla+-mode-progs)
;;; tla+-mode-progs.el ends here

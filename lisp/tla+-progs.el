;;; tla+-progs.el --- Programs used by TLA+

;; Copyright (C) 2024 Raven Hallsby

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

;;; Code:

(defcustom tla+-java-path "java"
  "Path to the `java' binary."
  :type 'file
  :group 'tla+)

(defcustom tla+-tlatools-path
  nil
  "Path to the TLA+ `tlatools.jar' toolbox java archive."
  :type 'file
  :group 'tla+)

(defcustom tla+-tools-classpath
  '()
  "List of directories to add to Java's class path to search for TLA+ tools."
  :type '(repeat directory)
  :group 'tla+)

;;
;; TLA+ has native support for converting a TLA+ specification to LaTeX for pretty-printing.
(defcustom tla+-dvipdf-path
  "dvipdf"
  "Path to the `dvipdf' program."
  :type 'file
  :group 'tla+)

(defcustom tla+-dvips-path
  "dvips"
  "Path to the `dvips' program."
  :type 'file
  :group 'tla+)

(defcustom tla+-tlatex-arguments
  (list "-shade" "-number")
  "Arguments which will be used when running `TLaTeX'."
  :type '(repeat string)
  :group 'tla+)

;;
;; TLC, TLA+'s bounded finite-value model checker
;; "-deadlock"
(defcustom tla+-tlc-deadlock
  't
  "Tell `TLC' to check for deadlocks (-deadlock)."
  :type 'boolean
  :group 'tla+)

;; "-simulate"
(defcustom tla+-tlc-simulate
  'nil
  "Tell `TLC' to do simulation (-simulate)."
  :type 'boolean
  :group 'tla+)

;; "-depth 1000"
(defcustom tla+-tlc-depth
  100
  "Maximum number of steps for `TLC' to take when checking a specification."
  :type 'natnum
  :group 'tla+)

(defcustom tla+-tlc-coverage
  "  "
  "Tell `TLC' to print coverage every X minutes."
  :type 'natnum
  :group 'tla+)

;; "-workers 2"
(defcustom tla+-tlc-workers
  2
  "Number of worker threads `TLC' should use when checking."
  :type 'natnum
  :group 'tla+)

(defcustom tla+-option-list
  '()
  "Assoc list for TLC Options."
  :type 'string
  :group 'tla+)

;;
;; TLA+ & TLC allows visualization of the states gone through using dot.
(defcustom tla+-dot-binary
  nil
  "Path to `dot' binary."
  :type 'file
  :group 'tla+)

(defcustom tla+-dot-out-file
  "out.pdf"
  "If non-nil, convert states.dot to this filename."
  :type 'string
  :group 'tla+)

(provide 'tla+-progs)
;;; tla+-progs.el ends here

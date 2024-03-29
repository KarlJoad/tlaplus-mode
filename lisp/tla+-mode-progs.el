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

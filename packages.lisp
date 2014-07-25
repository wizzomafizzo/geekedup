;;;; geekedup package

(load "~/quicklisp/setup.lisp")

(loop for p in
	 '(split-sequence lisp-unit cl-irc bordeaux-threads drakma
	   cxml-stp net-telent-date sqlite)
	 do (ql:quickload p))

(in-package "COMMON-LISP-USER")
(defpackage #:geekedup (:use :cl))

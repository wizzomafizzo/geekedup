;;;; geekedup: the amazing irc bot!

(load "packages.lisp")
(load "common.lisp")
(load "database.lisp")
(load "rss.lisp")
(load "commands.lisp")

(in-package :geekedup)

(defparameter *config* '((server . "irc.freenode.net")
						 (nick . "bitchimightbe__")
						 (join . "##wizzotest")
						 (command-prefix . #\,)))

; (public-alias actual-function-symbol admin-only?)
(defparameter *commands* '(("say" cmd-say nil)
						   ("add" cmd-new-factoid nil)
						   ("seen" cmd-seen nil)
						   ("grab" cmd-grab-quote nil)
						   ("quote" cmd-quote nil)
						   ("rq" cmd-random-quote nil)
						   ("ping" cmd-ping nil)
						   ("checkrss" cmd-check-rss t)
						   ("ignore" cmd-ignore t)
						   ("mkadmin" cmd-make-admin t)
						   ("mknormal" cmd-make-normal t)))

(defparameter *rss-feeds* '("http://www.reddit.com/r/Hiphopcirclejerk/new/.rss?limit=3"
							"http://www.reddit.com/r/kramacourt/new/.rss?limit=3"))
(defparameter *last-rss-check* 0)
(defparameter *rss-check-interval* (* 60 15))

(defparameter *db* (sqlite:connect "geekedup.db"))
(defparameter *connection* nil)

(defparameter *rss-thread* (bordeaux-threads:make-thread #'rss-thread))

;; main

;(cl-irc:read-message-loop *connection*)

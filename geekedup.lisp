;;;; geekedup: the amazing irc bot!

(load "packages.lisp")
(load "irc.lisp")
(load "database.lisp")
(load "rss.lisp")
(load "commands.lisp")

(in-package :geekedup)

(defun clean-up ()
  (bordeaux-threads:destroy-thread *RSS-THREAD*))

(defun main ()
  ;; NOTE: may be a race condition here since it starts before the irc connection
  ;; is created but that should be faster than an rss check
  (defvar *rss-thread* (bordeaux-threads:make-thread #'rss-thread))
  (run-bot)
  (cl-irc:read-message-loop *connection*))

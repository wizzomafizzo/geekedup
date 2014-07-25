;;; database

(in-package :geekedup)

(defmacro db-non-query (&rest body)
  `(sqlite:execute-non-query *db* ,@body))

(defmacro db-single (&rest body)
  `(sqlite:execute-single *db* ,@body))

(defmacro db-to-list (&rest body)
  `(sqlite:execute-to-list *db* ,@body))

(defun init-db ()
  (db-non-query "create table users (nick text, privs text)")
  (db-non-query "create table factoids (name text, msg text)")
  (db-non-query "create table seen (nick text, channel text, msg text, timestamp integer)")
  (db-non-query "create table quotes (nick text, msg text)"))

;; users
(defun add-new-user (nick &optional (privs "normal"))
  (db-non-query "insert into users values (?, ?)" nick privs))

(defun set-user-privs (nick privs)
  (if (get-user-privs nick)
	  (db-non-query "update users set privs = ? where nick = ?" privs nick)
	  (add-new-user nick privs)))

(defun set-user-admin (nick)
  (set-user-privs nick "admin"))

(defun set-user-ignore (nick)
  (set-user-privs nick "ignore"))

(defun set-user-normal (nick)
  (set-user-privs nick "normal"))

(defun get-user-privs (nick)
  (db-single "select privs from users where nick = ?" nick))

(defun user-admin? (nick)
  (if (equal (get-user-privs nick) "admin") t))

(defun user-ignored? (nick)
  (if (equal (get-user-privs nick) "ignore") t))

;; factoids

(defun add-new-factoid (name msg)
  (db-non-query "insert into factoids values (?, ?)" name msg))

(defun get-factoid (name)
  (db-single "select msg from factoids where name = ?" name))

;; seen

(defun add-new-last-seen (nick channel msg)
  (db-non-query "insert into seen values (?, ?, ?, ?)"
				nick channel msg (get-universal-time)))

(defun update-last-seen (nick channel msg)
  (if (get-last-seen nick channel)
	  (db-non-query "update seen set msg = ?, channel = ?, timestamp = ? where nick = ?"
					msg channel (get-universal-time) nick)
	  (add-new-last-seen nick channel msg)))

(defun get-last-seen (nick channel)
  (car (db-to-list "select msg, timestamp from seen where nick = ? and channel = ?"
				   nick channel)))

;; quotes

(defun add-new-quote (nick msg)
  (db-non-query "insert into quotes values (?, ?)" nick msg))

(defun get-last-quote (nick)
  (caar (db-to-list "select msg from quotes where nick = ? order by rowid desc limit 1" nick)))

(defun get-random-quote (&optional nick)
  (if nick
	  (car (db-to-list "select nick, msg from quotes where nick = ? order by random() limit 1" nick))
	  (car (db-to-list "select nick, msg from quotes order by random() limit 1"))))

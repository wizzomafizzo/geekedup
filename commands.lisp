(in-package :geekedup)

(defvar *commands* '(("say" cmd-say nil)
					 ("add" cmd-new-factoid nil)
					 ("seen" cmd-seen nil)
					 ("grab" cmd-grab-quote nil)
					 ("quote" cmd-quote nil)
					 ("rq" cmd-random-quote nil)
					 ("ping" cmd-ping nil)
					 ("checkrss" cmd-check-rss t)
					 ("ignore" cmd-ignore t)
					 ("mkadmin" cmd-make-admin t)
					 ("mknormal" cmd-make-normal t)
					 ("join" cmd-join t)
					 ("part" cmd-part t)
					 ("quit" cmd-quit t)
					 ("restart" cmd-restart t)))

(defun lookup-cmd (name)
  (cdr (assoc name *commands* :test #'string-equal)))

(defun cmd-join (message)
  (let ((channel (cmd-args message)))
	(list 'join channel)))

(defun cmd-part (message)
  (let ((channel (cmd-args message)))
	(list 'part channel)))

(defun cmd-quit (message)
  (if message '(quit)))

(defun cmd-restart (message)
  (if message '(restart)))

(defun cmd-ignore (message)
  (let ((nick (cmd-args message)))
	(if nick
		(progn
		  (set-user-ignore nick)
		  (list 'say "they are dead to me")))))

(defun cmd-make-admin (message)
  (let ((nick (cmd-args message)))
	(if nick
		(progn
		  (set-user-admin nick)
		  (list 'say "wow u r so powerful")))))

(defun cmd-make-normal (message)
  (let ((nick (cmd-args message)))
	(if nick
		(progn
		  (set-user-normal nick)
		  (list 'say "kk")))))

(defun cmd-say (message)
  (list 'say (cmd-args message)))

(defun cmd-new-factoid (message)
  (let ((factoid (parse-cmd (cmd-args message) :no-prefix t)))
	(if (cdr factoid)
		(progn
		  (list 'say (add-new-factoid (car factoid) (cdr factoid)))
		  (list 'say "factoid added")))))

(defun cmd-quote (message)
  (let ((user-quote (get-last-quote (cmd-args message))))
	(if user-quote
		(list 'say (format-quote (cmd-args message) user-quote))
		(list 'say "who?"))))

(defun cmd-grab-quote (message)
  (let* ((last-seen (get-last-seen (cmd-args message)
								   (message-channel message))))
	(if last-seen
		(progn
		  (add-new-quote (cmd-args message) (car last-seen))
		  (list 'say "tada!"))
		(list 'say "who?"))))

(defun cmd-seen (message)
  (let ((last-seen (get-last-seen (cmd-args message)
								  (message-channel message))))
	(if last-seen
		(list 'say (format-quote (cmd-args message) (car last-seen)))
		(list 'say "i haven't seen them"))))

(defun cmd-random-quote (message)
  (let* ((nick (cmd-args message))
		 (user-quote (get-random-quote nick)))
	(if user-quote
		(list 'say (apply #'format-quote user-quote))
		(list 'say "who?"))))

(defun cmd-ping (message)
  (list 'say (format-reply (message-nick message) "pong!")))

(defun cmd-check-rss (message)
  (let ((total-new (check-rss-feeds (message-channel message))))
	(list 'say (format nil "~a new things" total-new))))

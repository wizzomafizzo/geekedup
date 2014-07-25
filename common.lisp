(in-package :geekedup)

; specific reply to a user
(defun format-reply (nick msg)
  (format nil "~a: ~a" nick msg))

(defun lookup-cmd (name)
  (cdr (assoc name *commands* :test #'string-equal)))

(defun format-quote (nick msg)
  (concatenate 'string "<" nick "> " msg))

; basically cl-irc:privmsg minus the connection value, make testing
; in isolation easier
(defstruct message
  (nick nil :type string)
  (host nil :type string)
  (channel nil :type string)
  (msg nil :type string)
  (timestamp nil :type integer))

(defun test-message ()
  (make-message :nick "wizzo"
				:host "something.com"
				:channel "##wizzotest"
				:msg ",say something"
				:timestamp 0))


; lookup bot config value
(defun config (key)
  (cdr (assoc key *config*)))

; internal logging function
(defun log-bot (msg)
  (print msg))

(defun trim-spaces (string)
  (string-trim '(#\Space) string))

(defun can-run-cmd? (nick cmd)
  (let ((needs-admin? (cadr (lookup-cmd cmd))))
	(if needs-admin?
		(if (user-admin? nick) t)
		t)))

; ",foo bar baz fnord" => ("foo" "bar baz fnord")
(defun parse-cmd (msg &key no-prefix)
  (let* ((cmd-string (if no-prefix
						 (trim-spaces msg)
						 (subseq (trim-spaces msg) 1)))
		 (split (split-sequence:split-sequence #\Space cmd-string))
		 (cmd (car split))
		 (cmd-chop-len (+ (length cmd) 1)))
	(if (< cmd-chop-len (length cmd-string))
		(cons cmd (trim-spaces (subseq cmd-string cmd-chop-len)))
		(cons cmd nil))))

; work out what command of factoid should be run from a full message
(defun run-cmd (message)
  (let* ((cmd (parse-cmd (message-msg message)))
		 (command (lookup-cmd (car cmd)))
		 (factoid (get-factoid (car cmd))))
	(cond
	  (command (if (can-run-cmd? (message-nick message)
								 (car cmd))
				   (funcall (car command) message)
				   (list 'say "not allowed ;(")))
	  (factoid (list 'say factoid))
	  (t (list 'say "wat")))))

(defun cmd-args (message)
  (cdr (parse-cmd (message-msg message))))

; (say/join/part/quit/reconnect/do data)
(defun process-cmd (privmsg message)
  (if (and (equal (config 'command-prefix) (char (message-msg message) 0))
		 (not (user-ignored? (message-nick message))))
	  (let ((response (run-cmd message)))
		(cond ((eq (car response) 'say)
			   (cl-irc:privmsg (cl-irc:connection privmsg)
							   (message-channel message)
							   (string (cadr response))))))))

; main hook for all cl-irc privmsg
(defun process-msg (privmsg)
  (let ((message (make-message :nick (cl-irc:source privmsg)
							   :host (cl-irc:host privmsg)
							   :channel (car (cl-irc:arguments privmsg))
							   :msg (cadr (cl-irc:arguments privmsg))
							   :timestamp (cl-irc:received-time privmsg))))
	(process-cmd privmsg message)
	(update-last-seen (message-nick message)
					  (message-channel message)
					  (message-msg message))))

(defun irc-message-logger (message)
  (let ((log-file (concatenate 'string "./" (car (cl-irc:arguments message)) ".log")))
	(with-open-file (stream log-file :direction :output :if-exists :append)
	  (format stream "~a ~a" (cl-irc:received-time message) (cl-irc:raw-message-string message)))))

; clear and add all custom cl-irc hooks
(defun setup-hooks ()
  (cl-irc:remove-hooks *connection* 'cl-irc:ctcp-action-message)
  (cl-irc:remove-hooks *connection* 'cl-irc:irc-privmsg-message)
  (cl-irc:add-hook *connection* 'cl-irc:ctcp-action-message #'process-msg)
  (cl-irc:add-hook *connection* 'cl-irc:irc-privmsg-message #'process-msg)
  (cl-irc:add-hook *connection* 'cl-irc:irc-privmsg-message #'irc-message-logger))

; initiate irc connection and set global var, join home channels
(defun run-bot ()
  (setf *connection* (cl-irc:connect :server (config 'server)
									 :nickname (config 'nick)))
  (setup-hooks)
  (cl-irc:join *connection* (config 'join))
  (cl-irc:privmsg *connection* (config 'join) "hello world"))

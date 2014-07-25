(in-package :geekedup)

;; rss parsing

; TODO: handle bad connection/invalid rss data

(defun child-as-string (child-name element)
  (stp:string-value (first (stp:filter-children (stp:of-name child-name) element))))

(defun get-rss-feed (url)
  (let* ((feed-data (drakma:http-request url))
		 (feed (cxml:parse feed-data (stp:make-builder))))
	(mapcar (lambda (item) (list :title (child-as-string "title" item)
							:link (child-as-string "link" item)
							:date (net.telent.date:parse-time (child-as-string "pubDate" item))))
			(stp:filter-recursively (stp:of-name "item") feed))))

(defun format-rss-item (item)
  (format nil "~a // ~a" (getf item :title) (getf item :link)))

(defun get-all-new-rss ()
  ; make a list of every rss item from every feed
  (let ((items (loop for x in *rss-feeds* append (get-rss-feed x))))
	; filter items older than last check date
	(loop for x in items
	   when (>= (getf x :date) *last-rss-check*)
		 collect x)))

(defun check-rss-feeds (out-channel)
  (let ((feed-items (get-all-new-rss)))
	(mapc #'(lambda (x) (cl-irc:privmsg *connection* out-channel
								   (format-rss-item x)))
		  feed-items)
	(setf *last-rss-check* (get-universal-time))
	(length feed-items)))

(defun rss-thread ()
  (loop while t do
	   (check-rss-feeds (config 'join))
	   (cl-irc:privmsg *connection* (config 'join) "checked rss")
	   (sleep *rss-check-interval*)))

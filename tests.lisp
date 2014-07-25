
;;; Tests

(define-test test-parse-cmd
  (assert-equal '("cmd" . "foo bar baz")
				(parse-cmd "cmd foo bar baz"))
  (assert-equal '("cmd" . "foo bar baz")
				(parse-cmd "cmd      foo bar baz   "))
  (assert-equal '("cmd")
				(parse-cmd "cmd"))
  (assert-equal '("cmd" . "foo bar baz")
				(parse-cmd "    cmd      foo bar baz   ")))

;(lisp-unit:run-tests)

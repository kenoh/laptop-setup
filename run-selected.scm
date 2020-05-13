#!/bin/guile \
-s
!#
(use-modules ((ice-9 getopt-long) #:select (getopt-long option-ref))
             ((ice-9 popen) #:select (open-pipe* close-pipe)))

(define option-spec '((check (single-char #\c) (value #f))))
(define check (option-ref (getopt-long (command-line) option-spec) 'check #f))
(define roles (option-ref (getopt-long (command-line) option-spec) '() '()))

(define (prep-yml roles)
    (with-output-to-file "test.yml"
        (lambda ()
            (display "---\n")
            (display "- hosts: localhost\n")
            (display "  become_user: root\n")
            (display "  roles:\n")
            (for-each display (map (lambda (role) (format #t "    - ~a\n" role)) roles)))))

(define (cleanup)
    (system* "rm" "test.yml")
    (system* "rm" "test.retry"))

(define (play)
    (let ((cmd (append '("ansible-playbook" "-i" "inventory.txt" "--ask-become-pass")
                       (if check '("--check") '())
                       '("test.yml"))))
     (display cmd)(display "\n")
     (apply system* cmd)))

(define (my-assert bool msg)
    (unless bool
      (display msg (current-error-port))
      (exit #f)))
 
(define (system-no-output* . args)
  (let ((port (apply open-pipe* OPEN_READ args)))
     (read port)
     (close-pipe port)))


;; main
(begin
    (my-assert (eq? 0 (system-no-output* "which" "ansible-playbook")) "Could not fine ansible-playbook executable.\n")
    (my-assert (eq? 0 (system-no-output* "test" "!" "-e" "test.yml")) "test.yml should not be present. Please, remove it before running again.\n")
    (my-assert (< 0 (length roles)) "Please, provide roles' names as arguments.\n")
    (display "All good!\n")
    (prep-yml roles)
    (play)
    (cleanup))

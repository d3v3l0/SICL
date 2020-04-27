(cl:in-package #:sicl-boot-phase-6)

(defun import-from-host (boot)
  (with-accessors ((e5 sicl-boot:e5)
                   (e6 sicl-boot:e6)
                   (e7 sicl-boot:e7))
      boot
    (import-functions-from-host
     '(cons car cdr cadr cddr caddr cdddr (setf cdr) rplacd
       atom eq not member symbolp functionp
       +)
     e6)))
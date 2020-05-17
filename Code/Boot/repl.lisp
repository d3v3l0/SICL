(cl:in-package #:sicl-boot)

(defun repl (e5)
  (loop with client = (make-instance 'sicl-boot:client)
        do (format t "SICL> ")
           (finish-output *standard-output*)
           (let* ((form (eclector.reader:read))
                  (value (cleavir-cst-to-ast:eval client form e5)))
             (funcall (sicl-genv:fdefinition 'print-object e5)
                      value
                      *standard-output*)
             (format t "~%")
             (finish-output *standard-output*))))

             
                       
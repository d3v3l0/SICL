(cl:in-package #:sicl-boot-phase-0)

(defun compile-file (client relative-pathname environment)
  (let ((*package* *package*)
        (input-pathname (asdf:system-relative-pathname '#:sicl relative-pathname)))
    (with-open-file (input-stream input-pathname :direction :input)
      (let ((first-form (eclector.reader:read input-stream nil nil)))
        (assert (and (consp first-form)
                     (eq (first first-form) 'in-package)))
        (setf *package* (find-package (second first-form))))
      (let* ((csts (loop with eof-marker = (list nil)
                         for cst = (eclector.concrete-syntax-tree:cst-read input-stream nil eof-marker)
                         until (eq cst eof-marker)
                         collect cst))
             (cst (cst:cons (cst:cst-from-expression 'progn)
                            (apply #'cst:list csts)))
             (ast (let ((cleavir-cst-to-ast::*origin* nil))
                    (cleavir-cst-to-ast:cst-to-ast client cst environment))))
        (let* ((pos (position #\/ relative-pathname :from-end t))
               (lisp-filename (subseq relative-pathname (1+ pos)))
               (dot-pos (position #\. lisp-filename))
               (root (subseq lisp-filename 0 dot-pos))
               (filename (concatenate 'string root ".fasl"))
               (output-relative-pathname (concatenate 'string
                                                      "Boot/New/Phase-0/ASTs/"
                                                      filename))
               (output-pathname (asdf:system-relative-pathname '#:sicl output-relative-pathname)))
          (cleavir-io:write-model output-pathname "V0" ast))))))

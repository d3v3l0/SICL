(cl:in-package #:cleavir-cst-to-ast)

;;; Check the syntax of a single LET or LET* binding.  If the syntax
;;; is incorrect, signal an error.
(defun check-binding (cst)
  (cond ((or (and (cst:atom cst)
                  (symbolp (cst:raw cst)))
             (and (cst:consp cst)
                  (cst:atom (cst:first cst))
                  (symbolp (cst:raw (cst:first cst)))
                  (or (cst:null (cst:rest cst))
                      (and (cst:consp (cst:rest cst))
                           (cst:null (cst:rest (cst:rest cst)))))))
         nil)
        ((cst:atom cst)
         (error 'binding-must-be-symbol-or-list
                :expr (cst:raw cst)
                :origin (cst:source cst)))
        ((or (and (cst:atom (cst:rest cst))
                  (not (cst:null (cst:rest cst))))
             (not (cst:null (cst:rest (cst:rest cst)))))
         (error 'binding-must-have-length-one-or-two
                :expr (cst:raw cst)
                :origin (cst:source cst)))
        (t
         (error 'variable-must-be-a-symbol
                :expr (cst:raw (cst:first cst))
                :origin (cst:source (cst:first cst))))))

;;; Check the syntax of the bindings of a LET or a LET* form.  If the
;;; syntax is incorrect, signal an error and propose a restart for
;;; fixing it up.
(defun check-bindings (cst)
  (check-cst-proper-list cst 'bindings-must-be-proper-list)
  (loop for remaining = cst then (cst:rest remaining)
        until (cst:null remaining)
        do (check-binding (cst:first remaining))))

;;; We convert a LET form CST by transforming it into an equivalent
;;; LAMBDA form CST.

(defmethod convert-let (cst environment system)
  (when (cst:null (cst:rest cst))
    (error 'let-or-let*-must-have-at-least-one-argument
           :expr (cst:raw cst)
           :origin (cst:source cst)))
  (cst:db origin (let-cst bindings-cst . body-forms-cst) cst
    (declare (ignore let-cst))
    (check-bindings bindings-cst)
    (let* ((binding-csts (cst:listify bindings-cst))
           (variable-csts (loop for binding-cst in binding-csts
                                collect (if (cst:atom binding-cst)
                                            binding-cst
                                            (cst:first binding-cst))))
           (initform-csts (loop for binding-cst in binding-csts
                                collect (if (or (cst:atom binding-cst)
                                                (cst:null (cst:rest binding-cst)))
                                            (make-atom-cst nil origin)
                                            (cst:second binding-cst))))
           (lambda-form-cst
             (make-instance 'cst:cons-cst
               :raw `((lambda ,(mapcar #'cst:raw variable-csts)
                        ,@(cst:raw body-forms-cst))
                      ,(mapcar #'cst:raw initform-csts))
               :source origin
               :first (cst:cons (make-atom-cst 'lambda origin)
                                (cst:cons (cst:cstify variable-csts)
                                          body-forms-cst)
                                :source origin)
               :rest (cst:cstify initform-csts))))
      (convert lambda-form-cst environment system))))

;;; We convert a LET* form CST by transforming it into nested LET form
;;; CSTs and then converting those instead.  This is not trivial,
;;; because we need to associate the right declarations with the
;;; corresponding LET form CST.

(defmethod convert-let* (cst environment system)
  (when (cst:null (cst:rest cst))
    (error 'let-or-let*-must-have-at-least-one-argument
           :expr (cst:raw cst)
           :origin (cst:source cst)))
  (cst:db origin (let*-cst bindings-cst . body-forms-cst) cst
    (declare (ignore let*-cst))
    (check-bindings bindings-cst)
    (multiple-value-bind (declaration-csts forms-cst)
        (cst:separate-ordinary-body body-forms-cst)
      (let* ((canonical-declaration-specifiers
              (cst:canonicalize-declarations system declaration-csts))
             (binding-csts (cst:listify bindings-cst))
             (variable-csts
               (loop for binding-cst in binding-csts
                     collect (if (cst:atom binding-cst)
                                 binding-cst
                                 (cst:first binding-cst)))))
        (multiple-value-bind (item-specific-dspecs remaining-dspecs)
            (itemize-declaration-specifiers (mapcar #'list variable-csts)
                                            canonical-declaration-specifiers)
          (loop with remaining-dspecs-cst = (cst:cstify remaining-dspecs)
                with result = (cst:cons (make-atom-cst 'locally origin)
                                        (if (null remaining-dspecs)
                                            forms-cst
                                            (cst:cons
                                             (cst:cons (make-atom-cst 'declare origin)
                                                       remaining-dspecs-cst
                                                       :source (cst:source remaining-dspecs-cst))
                                             forms-cst
                                             :source origin))
                                        :source origin)
                for binding-cst in (reverse binding-csts)
                for declaration-csts in (reverse item-specific-dspecs)
                do (setf result
                         (cst:cons
                          (make-atom-cst 'let origin)
                          (cst:cons (cst:list binding-cst)
                                    (if (null declaration-csts)
                                        (cst:list result)
                                        (cst:list
                                         (cst:cons (make-atom-cst 'declare)
                                                   (cst:cstify declaration-csts))
                                         result))
                                    :source origin)
                          :source origin))
                finally (return (convert result environment system))))))))

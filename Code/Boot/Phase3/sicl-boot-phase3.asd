(cl:in-package #:common-lisp-user)

(asdf:defsystem :sicl-boot-phase3
  :depends-on (:sicl-boot-phase2)
  :serial t
  :components
  ((:file "packages")
   (:file "rename-package-1")
   (:file "import")
   (:file "import-to-environment")
   (:file "list-utilities")
   (:file "ensure")
   (:file "defclass-support")
   (:file "defclass-defmacro")
   (:file "define-built-in-class-defmacro")
   (:file "defgeneric-defmacro")
   (:file "make-method-lambda-support")
   (:file "make-method-lambda-defuns")
   (:file "defmethod-support")
   (:file "defmethod-defmacro")
   (:file "mop-class-hierarchy")
   (:file "environment-classes")
   (:file "finalize-all-target-classes")
   (:file "global-environment")
   (:file "patch-all-target-objects")
   (:file "shared-initialize-support")
   (:file "update-functions")
   (:file "xensure-class")
   (:file "xensure-built-in-class")
   (:file "xensure-generic-function")
   (:file "xensure-method")
   (:file "rename-package-2")))

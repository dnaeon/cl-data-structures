(cl:in-package #:cl-ds.sets.skip-list)


(defclass mutable-skip-list-set (cl-ds.sets:fundamental-set
                                 cl-ds.common.skip-list:fundamental-skip-list)
  ((%test-function :initarg :test-function
                   :accessor access-test-function)))


(defmethod cl-ds:clone ((object mutable-skip-list-set))
  (lret ((result (call-next-method)))
    (setf (access-test-function result) (access-test-function object))))


(defmethod cl-ds:empty-clone ((object mutable-skip-list-set))
  (lret ((result (call-next-method)))
    (setf (access-test-function result) (access-test-function object))))


(defclass mutable-skip-list-set-range (cl-ds.common.skip-list:fundamental-skip-list-range)
  ())


(defmethod cl-ds:whole-range ((object mutable-skip-list-set))
  (make-instance 'mutable-skip-list-set-range
                 :current-node (~> object
                                   cl-ds.common.skip-list:read-pointers
                                   (aref 0))))


(defmethod cl-ds:consume-front ((range mutable-skip-list-set-range))
  (let ((result (call-next-method)))
    (if (null result)
        (values nil nil)
        (values (cl-ds.common.skip-list:skip-list-node-content result)
                t))))


(defmethod cl-ds:peek-front ((range mutable-skip-list-set-range))
  (let ((result (call-next-method)))
    (if (null result)
        (values nil nil)
        (values (cl-ds.common.skip-list:skip-list-node-content result)
                t))))


(defmethod cl-ds:traverse ((range mutable-skip-list-set-range)
                           function)
  (ensure-functionf function)
  (call-next-method range
                    (lambda (node)
                      (declare (type cl-ds.common.skip-list:skip-list-node
                                     node)
                               (optimize (speed 3)))
                      (~>> node
                           cl-ds.common.skip-list:skip-list-node-content
                           (funcall function))))
  range)


(defmethod cl-ds:across ((range mutable-skip-list-set-range)
                         function)
  (ensure-functionf function)
  (call-next-method range
                    (lambda (node)
                      (declare (type cl-ds.common.skip-list:skip-list-node
                                     node)
                               (optimize (speed 3)))
                      (~>> node
                           cl-ds.common.skip-list:skip-list-node-content
                           (funcall function))))
  range)


(defmethod cl-ds.meta:position-modification
    ((function cl-ds.meta:put!-function)
     (structure mutable-skip-list-set)
     container
     location
     &rest all)
  (declare (ignore all container))
  (bind (((:values current prev)
          (cl-ds.common.skip-list:skip-list-locate-node structure location))
         (result (aref current 0)))
    (bind ((content (cl-ds.common.skip-list:skip-list-node-content result)))
      (if (~> structure read-test-function (funcall content))
          cl-ds.utils:todo
          cl-ds.utils:todo))))


(defmethod cl-ds.meta:position-modification
    ((function cl-ds.meta:erase!-function)
     (structure mutable-skip-list-set)
     container
     location
     &rest all)
  (declare (ignore all container))
  (bind (((:values current prev)
          (cl-ds.common.skip-list:skip-list-locate-node structure location))
         (result (aref current 0)))
    (when (null result)
      cl-ds.utils:todo)
    (bind ((content (cl-ds.common.skip-list:skip-list-node-content result)))
      (if (~> structure read-test-function (funcall content))
          cl-ds.utils:todo
          cl-ds.utils:todo))))


(defmethod cl-ds:at ((container mutable-skip-list-set)
                     location
                     &rest more-locations)
  (cl-ds:assert-one-dimension more-locations)
  (let ((result (~> container
                    (cl-ds.common.skip-list:skip-list-locate-node location)
                    (aref 0))))
    (when (null result)
      (return-from cl-ds:at (values nil nil)))
    (let ((content (cl-ds.common.skip-list:skip-list-node-content result)))
      (if (~> container read-test-function (funcall content))
          (values t t)
          (values nil nil)))))


(defun make-mutable-skip-list-set (ordering test
                                   &key (maximum-level 32))
  (check-type maximum-level positive-fixnum)
  (make-instance 'mutable-skip-list-set
                 :ordering-function ordering
                 :maximum-level maximum-level
                 :test-function test
                 :pointers (make-array maximum-level
                                       :initial-element nil)))


(defmethod cl-ds:make-from-traversable (traversable
                                        (class (eql 'mutable-skip-list-set))
                                        &rest arguments)
  (lret ((result (apply #'make-mutable-skip-list-set arguments)))
    (cl-ds:traverse traversable
                    (lambda (x) (cl-ds:put! result x)))))

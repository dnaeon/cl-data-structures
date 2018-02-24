(in-package #:cl-data-structures.math)


(defclass moments-function (cl-ds.alg:aggregation-function)
  ()
  (:metaclass closer-mop:funcallable-standard-class))


(defgeneric moments (range from count about &key key)
  (:generic-function-class moments-function)
  (:method (range from count about &key (key #'identity))
    (cl-ds.alg:apply-aggregation-function range
                                          #'moments
                                          :count count
                                          :from from
                                          :about about
                                          :key key)))


(defclass moments-state ()
  ((%moments :initarg :moments
             :reader read-last-moments)
   (%start :initarg :start
           :reader read-start)
   (%count :initform 0
           :accessor access-count)
   (%lambdas :initarg :lambdas
             :accessor read-lambdas)))


(defmethod cl-ds.alg:make-state ((function moments-function)
                                 &rest all
                                 &key count about from)
  (declare (ignore all))
  (assert (> from 0))
  (bind ((lambdas (make-array count))
         (result (make-array count :element-type 'number)))
    (iterate
      (for i from from)
      (for index from 0 below count)
      (setf (aref lambdas index) (let ((power i))
                                   (lambda (value)
                                     (expt (- value about) power)))))
    (make 'moments-state :moments result
                         :lambdas lambdas
                         :start from)))


(defmethod cl-ds.alg:aggregate ((function moments-function)
                                state
                                element)
  (check-type state moments-state)
  (bind (((:slots %lambdas %moments %count) state))
    (incf %count)
    (iterate
      (for i from 0 below (length %lambdas))
      (incf (aref %moments i) (funcall (aref %lambdas i) element)))))


(defmethod cl-ds.alg:state-result ((function moments-function)
                                   state)
  (check-type state moments-state)
  (let ((moments (read-last-moments state))
        (count (access-count state)))
    (map-into moments (rcurry #'/ count) moments)
    (make-instance 'cl-ds.adapters:offset-vector-range
                   :vector moments
                   :offset (read-start state))))

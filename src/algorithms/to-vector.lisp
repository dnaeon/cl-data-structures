(cl:in-package #:cl-data-structures.algorithms)


(cl-ds.alg.meta:define-aggregation-function
    to-vector to-vector-function

  (:range &key key element-type force-copy size)
  (:range &key
          (key #'identity) (element-type t)
          (force-copy t) (size 16))

  (%vector)

  ((&key element-type size &allow-other-keys)
   (setf %vector (make-array size :element-type element-type
                                  :adjustable t
                                  :fill-pointer 0)))
  ((element)
   (vector-push-extend element %vector))

  (%vector))


(defmethod cl-ds.alg.meta:apply-range-function
    ((range vector)
     (function to-vector-function)
     &rest all
     &key force-copy key element-type size
     &allow-other-keys)
  (declare (ignore all size))
  (if (and (not force-copy)
           (subtypep element-type (array-element-type range))
           (eq key #'identity))
      range
      (call-next-method)))

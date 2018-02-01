(in-package #:cl-data-structures.algorithms)


(defclass abstract-chain-of-ranges (cl-ds:fundamental-forward-range)
  ((%content :initarg :content
             :initform (make 'flexichain:standard-flexichain)
             :reader read-content)
   (%original-content :initarg :original-content
                      :type list
                      :reader read-original-content)))


(defclass forward-chain-of-ranges (abstract-chain-of-ranges)
  ())


(defclass bidirectional-chain-of-ranges (abstract-chain-of-ranges)
  ())


(defclass random-access-chain-of-ranges (abstract-chain-of-ranges)
  ())


(defun chain (&rest ranges)
  (map nil
       (lambda (x) (check-type x cl-ds:fundamental-forward-range))
       ranges)
  (let ((fundamental-type (common-fundamental-range-class ranges)))
    (assert fundamental-type)
    (make (eswitch (fundamental-type)
            ('fundamental-forward-range 'forward-chain-of-ranges)
            ('fundamental-bidirectional-range 'bidirectional-chain-of-ranges)
            ('fundamental-random-access-range 'random-access-chain-of-ranges))
          :original-content ranges)))

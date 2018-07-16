(in-package #:cl-user)


(defpackage :cl-data-structures.sequences
  (:use #:cl-ds.utils
        #:common-lisp
        #:cl-data-structures.aux-package)
  (:nicknames #:cl-ds.seqs)
  (:export
   #:fundamental-sequence
   #:functional-sequence
   #:mutable-sequence
   #:transactional-sequence))


(defpackage :cl-data-structures.sequences.rrb-vector
  (:use #:common-lisp
        #:cl-ds.utils
        #:cl-data-structures.aux-package)
  (:nicknames #:cl-ds.seqs.rrb)
  (:export
   #:functional-rrb-vector
   #:make-functional-rrb-vector
   #:make-mutable-rrb-vector
   #:make-transactional-rrb-vector
   #:mutable-rrb-vector
   #:transactional-rrb-vector))

(cl:in-package #:cl-user)


(defpackage :cl-data-structures.streaming-algorithms
  (:use #:common-lisp #:cl-data-structures.aux-package)
  (:nicknames #:cl-ds.sa)
  (:shadow cl:union)
  (:local-nicknames
   (#:hll #:cl-data-structures.streaming-algorithms.hyperloglog)
   (#:ph #:cl-data-structures.streaming-algorithms.polynomial-hashing))
  (:export
   #:approximated-counts
   #:approximated-set-cardinality
   #:approximated-top-k
   #:bloom-filter
   #:clean-sketch
   #:fundamental-data-sketch
   #:gather-minhash-corpus
   #:hyperloglog-jaccard
   #:make-hash-array
   #:make-minhash
   #:make-one-bit-minhash
   #:minhash
   #:minhash-jaccard/double-float
   #:minhash-jaccard/fixnum
   #:minhash-jaccard/single-float
   #:one-bit-minhash-jaccard/single-float
   #:one-bit-minhash-jaccard/double-float
   #:one-bit-minhash-jaccard/fixnum
   #:union))

(in-package #:cl-user)


(defpackage :cl-data-structures.dicts
  (:use #:common-lisp
        #:cl-data-structures.aux-package
        #:cl-data-structures.utils)
  (:nicknames #:cl-ds.dicts)
  (:export
   #:fundamental-dictionary
   #:fundamental-hashing-dictionary
   #:bucket
   #:dictionary
   #:find-content
   #:functional-dictionary
   #:functional-hashing-dictionary
   #:hashing-dictionary
   #:lazy-dictionary
   #:lazy-hashing-dictionary
   #:make-bucket
   #:mutable-dictionary
   #:mutable-hashing-dictionary
   #:read-equal-fn
   #:read-hash-fn
   #:transactional-dictionary
   #:transactional-hashing-dictionary))


(defpackage :cl-data-structures.dicts.hamt
  (:use #:common-lisp
        #:cl-data-structures.aux-package
        #:cl-data-structures.utils
        #:cl-data-structures.common.hamt
        #:cl-data-structures.common.abstract)
  (:nicknames #:cl-ds.dicts.hamt)
  (:export
   #:functional-hamt-dictionary
   #:hamt-dictionary
   #:hamt-dictionary-at
   #:hamt-dictionary-size
   #:make-functional-hamt-dictionary
   #:make-mutable-hamt-dictionary
   #:mutable-hamt-dictionary
   #:read-max-depth
   #:transactional-hamt-dictionary))

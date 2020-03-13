(cl:in-package #:cl-user)


(defpackage :cl-data-structures.utils
  (:use #:common-lisp #:cl-data-structures.aux-package)
  (:nicknames #:cl-ds.utils)
  (:export
   #:add-into-queue
   #:add-sinks
   #:add-to-list
   #:adjust-size-to-fill-pointer
   #:all-parents
   #:ancestor-p
   #:and*
   #:at-list
   #:as-cons-tree
   #:binary-search
   #:bucket-sort
   #:bind-lambda
   #:cartesian
   #:cartesian-table
   #:cases
   #:clone
   #:cloning-information
   #:cloning-list
   #:cond+
   #:cond-compare
   #:copy-slots
   #:copy-without
   #:cycle-over-address
   #:define-list-of-slots
   #:draw-random-vector
   #:draw-sample-vector
   #:each-in-matrix
   #:end-execution
   #:ensure-call-ahead-of
   #:erase-from-vector
   #:extendable-vector
   #:fill-distance-matrix-from-vector
   #:future-carousel
   #:half-matrix
   #:homogenousp
   #:fixnum-hash
   #:if-else
   #:ignore-errors*
   #:import-all-package-symbols
   #:insert-or-replace
   #:inverted-hash-table
   #:lambda-list-to-bindings
   #:lambda-list-to-call-form
   #:lazy-let
   #:lazy-shuffle
   #:let-generator
   #:lexicographic-compare
   #:index
   #:lolol
   #:lower-bound
   #:lparallel-future
   #:make-distance-matrix-from-vector
   #:make-future-carousel
   #:make-half-matrix
   #:make-new-skip-vector
   #:make-pipe-fragment
   #:make-skip-vector
   #:merge-ordered-vectors
   #:method-lambda-list-to-function-lambda-list
   #:mref
   #:mutate-matrix
   #:normalize-sequence-to-span
   #:normalize-sequence-to-sum
   #:on-ordered-intersection
   #:optimize-value
   #:or*
   #:ordered-exclusion
   #:ordered-intersection
   #:ordered-p
   #:parallel-fill-distance-matrix-from-vector
   #:parallel-make-distance-matrix-from-vector
   #:pipe-fragment
   #:pop-last
   #:quasi-clone
   #:quasi-clone*
   #:quasi-other-class
   #:quasi-other-class*
   #:read-size
   #:rebind
   #:remove-fill-pointer
   #:scan
   #:select-top
   #:skip-vector-without
   #:generator
   #:sref
   #:start-execution
   #:swap-if
   #:swapop
   #:todo
   #:transform
   #:try-find
   #:try-find-cell
   #:try-remove
   #:unfold-table
   #:with-keys
   #:with-rebind
   #:with-slots-for
   #:with-vectors
   #:prevent-duplicates
   ))

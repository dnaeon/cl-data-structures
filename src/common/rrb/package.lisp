(in-package #:cl-user)


(defpackage :cl-data-structures.common.rrb
  (:use #:common-lisp
        #:cl-data-structures.common.abstract
        #:cl-data-structures.aux-package)
  (:nicknames #:cl-ds.common.rrb)
  (:export
   #:+bit-count+
   #:+depth+
   #:+maximum-children-count+
   #:+tail-mask+
   #:access-last-size
   #:access-lower-bound
   #:nref
   #:access-root
   #:access-shift
   #:access-size
   #:access-start
   #:access-tail
   #:access-tail-size
   #:access-upper-bound
   #:copy-on-write
   #:copy-on-write-without-tail
   #:copy-on-write-without-tail
   #:descend-into-tree
   #:destructive-write
   #:destructive-write-without-tail
   #:insert-tail
   #:make-node-content
   #:make-rrb-node
   #:node-content
   #:read-element-type
   #:remove-tail
   #:rrb-at
   #:rrb-container
   #:rrb-node
   #:rrb-node-push!
   #:rrb-node-push-into-copy
   #:rrb-range
   #:transactional-copy-on-write
   #:transactional-copy-on-write-without-tail))

(in-package :cl-user)
(defpackage rrb-test-suite
  (:use :prove :cl))
(in-package :rrb-test-suite)
(cl-ds.utils:import-all-package-symbols :cl-data-structures.common.rrb :rrb-test-suite)

(progn
  (prove:plan 2)
  (is (tail-offset 32) 0)
  (is (tail-offset 500) 480)
  (prove:finalize))

(progn
  (let* ((tail (make-array +maximum-children-count+
                           :initial-element nil))
         (tag (make-ownership-tag))
         (container (make-instance 'rrb-container
                                   :tail tail
                                   :size 0)))
    (map-into tail #'identity
              (iota +maximum-children-count+))
    (let ((new-root (insert-tail container
                         tag
                         #'copy-on-write
                         tail)))
      (is (access-shift container) 0)
      (is (rrb-node-content new-root) tail :test #'eq)
      (is (rrb-node-ownership-tag new-root) tag)
      (let ((another-tail (make-array +maximum-children-count+
                                      :initial-element nil)))
        (map-into another-tail #'identity
                  (iota +maximum-children-count+
                        :start +maximum-children-count+))
        (setf (access-root container) new-root)
        (setf (access-size container) 32)
        (setf (access-tail-size container) 0)
        (let ((another-root (insert-tail container
                                         tag
                                         #'copy-on-write
                                         another-tail)))
          (print another-root)
          (is (rrb-node-ownership-tag another-root) tag)
          (is-type (~> another-root rrb-node-content (aref 1))
                   'rrb-node)
          (is-type (~> another-root rrb-node-content (aref 0))
                   'rrb-node)
          (is (~> another-root rrb-node-content (aref 1) rrb-node-content)
              another-tail
              :test #'eq)
          (ok (not (eq another-root new-root)))
          (setf (access-root container) another-root))))
    (setf (access-shift container) 1)
    (setf (access-size container) (* +maximum-children-count+ +maximum-children-count+))
    (iterate
      (for i from 2 below 32)
      (iterate
        (for c from 0 below 32)
        (setf (~> container access-root rrb-node-content (aref i))
              (make-rrb-node :content
                              (map 'vector #'identity
                                   (iota +maximum-children-count+
                                         :start (* i +maximum-children-count+)))
                             :ownership-tag tag))))
    (let* ((another-tail (map 'vector #'identity
                             (iota +maximum-children-count+
                                   :start 1024)))
           (another-root (insert-tail container
                                      tag
                                      #'copy-on-write
                                      another-tail))
           (result (with-collector (result)
                     (labels ((impl (node)
                                (if (rrb-node-p node)
                                    (iterate
                                      (for elt in-vector (rrb-node-content node))
                                      (until (null elt))
                                      (impl elt))
                                    (result node))))
                       (impl another-root)))))
      (is result (iota (+ 1024 32))
          :test #'equal)
      (is (iterate
            (for elt in-vector (rrb-node-content another-root))
            (counting elt))
          2))))

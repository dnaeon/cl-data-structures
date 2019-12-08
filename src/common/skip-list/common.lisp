(cl:in-package #:cl-data-structures.common.skip-list)


(defstruct skip-list-node
  (pointers #() :type simple-vector)
  (content nil :type t))


(cl-ds.utils:define-list-of-slots skip-list-node ()
  (pointers skip-list-node-pointers)
  (level skip-list-node-level)
  (content skip-list-node-content))


(-> skip-list-node-level (skip-list-node) fixnum)
(defun skip-list-node-level (skip-list-node)
  (declare (optimize (speed 0) (debug 3) (safety 3)))
  (~> skip-list-node skip-list-node-pointers length))


(-> skip-list-node-at (skip-list-node cl-ds.utils:index) t)
(defun skip-list-node-at (skip-list-node index)
  (declare (optimize (speed 0) (debug 3) (safety 3)))
  (~> skip-list-node skip-list-node-pointers (aref index)))


(-> (setf skip-list-node-at)
    ((or null skip-list-node) skip-list-node cl-ds.utils:index)
    (or null skip-list-node))
(defun (setf skip-list-node-at) (new-value skip-list-node index)
  (declare (optimize (speed 0) (debug 3) (safety 3)))
  (cl-ds.utils:with-slots-for (skip-list-node skip-list-node)
    (setf (aref pointers index) new-value)))


(-> skip-list-node-clone (skip-list-node) skip-list-node)
(defun skip-list-node-clone (skip-list-node)
  (declare (optimize (speed 0) (debug 3) (safety 3)))
  (bind ((table (make-hash-table :test 'eq))
         (stack (vect))
         ((:labels impl (skip-list-node))
          (if (null skip-list-node)
              nil
              (if-let ((existing-node (gethash skip-list-node table)))
                existing-node
                (cl-ds.utils:with-slots-for (skip-list-node skip-list-node)
                  (lret ((result (make-skip-list-node
                                  :pointers (copy-array pointers)
                                  :content content)))
                    (setf (gethash skip-list-node table) result
                          (gethash result table) result)
                    (vector-push-extend (skip-list-node-pointers result)
                                        stack)))))))
    (iterate
      (with result = (impl skip-list-node))
      (for fill-pointer = (fill-pointer stack))
      (until (zerop fill-pointer))
      (for pointers = (aref stack (1- fill-pointer)))
      (decf (fill-pointer stack))
      (cl-ds.utils:transform #'impl pointers)
      (finally (return result)))))


(-> copy-into! (simple-vector simple-vector &optional fixnum) simple-vector)
(declaim (inline copy-into!))
(defun copy-into! (destination source
                   &optional
                     (limit (min (length (the simple-vector destination))
                                 (length (the simple-vector source)))))
  (declare (optimize (speed 3) (debug 0) (safety 0))
           (type fixnum limit))
  (iterate
    (declare (type fixnum i))
    (for i from 0 below limit)
    (setf (aref destination i) (aref source i))
    (finally (return destination))))


(-> skip-list-node-update-pointers! (skip-list-node simple-vector) skip-list-node)
(defun skip-list-node-update-pointers! (skip-list-node new-pointers)
  (declare (optimize (speed 3) (debug 0) (safety 0)))
  (cl-ds.utils:with-slots-for (skip-list-node skip-list-node)
    (copy-into! pointers new-pointers))
  skip-list-node)


(-> new-node-update-pointers! (skip-list-node simple-vector) skip-list-node)
(defun new-node-update-pointers! (spliced-node pointers)
  (declare (optimize (speed 0) (debug 3) (safety 3)))
  (iterate
    (declare (type fixnum i))
    (with spliced-level = (skip-list-node-level spliced-node))
    (for i from 0 below (length pointers))
    (for rest = (aref pointers i))
    (when (null rest)
      (next-iteration))
    (cl-ds.utils:with-slots-for (rest skip-list-node)
      (iterate
        (declare (type fixnum j))
        (for j from 0 below (min level spliced-level))
        (setf (aref pointers j) spliced-node)))
    (finally (return spliced-node))))


(-> random-level (positive-fixnum) positive-fixnum)
(defun random-level (maximum-level)
  (declare (optimize (speed 0) (safety 3) (debug 3)))
  (iterate
    (declare (type fixnum i))
    (for i from 1 to maximum-level)
    (until (zerop (random 2)))
    (finally (return i))))


(-> make-skip-list-node-of-level (fixnum) skip-list-node)
(defun make-skip-list-node-of-level (level)
  (declare (optimize (speed 0) (safety 3) (debug 3)))
  (make-skip-list-node :pointers (make-array level :initial-element nil)))


(-> make-skip-list-node-of-random-level (fixnum) skip-list-node)
(defun make-skip-list-node-of-random-level (maximum-level)
  (declare (optimize (speed 0) (safety 3) (debug 3)))
  (make-skip-list-node-of-level (random-level maximum-level)))


(declaim (notinline locate-node))
(-> locate-node (simple-vector t function) (values simple-vector simple-vector))
(defun locate-node (pointers item test)
  (declare (optimize (speed 0) (safety 3) (debug 3)
                     (compilation-speed 0) (space 0)))
  (let* ((pointers-length (length pointers))
         (prev-result (make-array pointers-length
                                  :initial-element nil))
         (last (1- pointers-length)))
    (declare (type fixnum last pointers-length))
    (iterate
      (declare (type fixnum i))
      (for i from last downto 0)
      (for node = (aref pointers i))
      (when (null node)
        (next-iteration))
      (for content = (skip-list-node-content node))
      (when (funcall test item content)
        (return-from locate-node (values pointers prev-result))))
    (iterate
      (declare (type fixnum i)
               (type simple-vector result))
      (with result = (copy-array pointers))
      (with i = last)
      (for node = (aref result i))
      (cl-ds.utils:with-slots-for (node skip-list-node)
        (when (and node (funcall test content item))
          (copy-into! prev-result result level)
          (copy-into! result pointers)
          (setf i level)))
      (decf i)
      (while (>= i 0))
      (finally (return (values result prev-result))))))


(-> insert-node-between! (simple-vector simple-vector skip-list-node) skip-list-node)
(defun insert-node-between! (pointers previous-pointers skip-list-node)
  (declare (optimize (speed 0) (debug 3) (safety 3)))
  (new-node-update-pointers! skip-list-node previous-pointers)
  (skip-list-node-update-pointers! skip-list-node pointers)
  skip-list-node)


(defclass fundamental-skip-list ()
  ((%size :initarg :size
          :reader cl-ds:size
          :type fixnum
          :accessor access-size)
   (%ordering-function :initarg :ordering-function
                       :reader read-ordering-function)
   (%pointers :initarg :pointers
              :reader read-pointers
              :type simple-vector)
   (%maximum-level :initarg :maximum-level
                   :accessor access-maximum-level))
  (:default-initargs :size 0))


(cl-ds.utils:define-list-of-slots fundamental-skip-list ()
  (size access-size)
  (ordering-function read-ordering-function)
  (pointers read-pointers)
  (maximum-level access-maximum-level))


(defmethod cl-ds.utils:cloning-information append ((object fundamental-skip-list))
  '((:pointers read-pointers)
    (:size cl-ds:size)
    (:ordering-function read-ordering-function)
    (:maximum-level access-maximum-level)))

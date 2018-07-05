(in-package #:cl-ds.utils)


(-> pop-last (extendable-vector) t)
(defun pop-last (vector)
  "If fill pointer is larger than zero reduce fill pointer and @b(returns) last vector element.

 @b(Side effects:) reduce fill pointer of vector.

 @b(Exceptional situations:) will return nil if fill pointer is equal 0."
  (unless (zerop (fill-pointer vector))
    (prog1
        (aref vector (1- (fill-pointer vector)))
      (decf (fill-pointer vector)))))


(-> erase-from-vector (extendable-vector &rest index) vector)
(defun erase-from-vector (vector &rest indexes)
  "Remove elements under indexes from vector, preserving order of elements.

 @b(Side effects:) Reduces fill pointer. Removes elements from vector and shifts elements that are left."
  (let ((indexes (sort indexes #'<))
        (count 0))
    (iterate
      (for sub on indexes)
      (for next = (cadr sub))
      (for index = (car sub))
      (for start = (- index count))
      (for end = (and next (fill-pointer vector)))
      (replace vector vector
               :start1 start
               :end1 end
               :start2 (1+ start))
      (incf count)
      (finally (progn (decf (fill-pointer vector) count)
                      (return vector))))))


(-> copy-without (vector &rest index) vector)
(defun copy-without (vector &rest indexes)
  (declare (optimize (speed 3)))
  (let* ((s (length indexes))
         (vs (length vector))
         (nvs (- vs s))
         (next-array (make-array nvs
                                 :element-type (array-element-type vector)
                                 :adjustable (adjustable-array-p vector)))
         (indexes (sort indexes #'<))
         (last 0)
         (count 0)
         (position 0))
    (iterate
      (for sub on indexes)
      (for index = (car sub))
      (for next = (or (cadr sub) nvs))
      (replace next-array vector
               :start2 last
               :end2 index
               :start1 position)
      (incf position (- index last))
      (setf last (1+ index))
      (incf count))
    (replace next-array vector
             :start2 last
             :end2 nil
             :start1 position)
    next-array))


(declaim (inline swapop))
(-> swapop (extendable-vector index) vector)
(defun swapop (vector index)
  "Swaps element under INDEX with last element of VECTOR. Pops last element and returns VECTOR.

   @b(Values and parameters:)
   @begin(list)
   @item(vector -- input vector)
   @item(index -- under which index element will be removed?)
   @end(list)

   @b(Side Effects:) changes element under INDEX to last element in the vector, reduces fill-pointer."
  (unless (zerop (fill-pointer vector))
    (rotatef (aref vector (1- (fill-pointer vector)))
             (aref vector index))
    (decf (fill-pointer vector)))
  vector)


(declaim (inline swap-if))
(defun swap-if (vector test &key (key #'identity) (start 0))
  (iterate
    (with end = (length vector))
    (with result = 0)
    (for i from (1- end) downto start)
    (for removal = (funcall test (funcall key (aref vector i))))
    (when removal
      (incf result)
      (rotatef (aref vector i)
               (aref vector (decf end))))
    (finally (return result))))

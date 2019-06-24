(in-package #:cl-data-structures.streaming-algorithms)


(defclass bloom-filter (fundamental-data-sketch)
  ((%counters :initarg :counters
              :type simple-bit-vector
              :accessor access-counters)
   (%hashes :initarg :hashes
            :type vector
            :accessor access-hashes)
   (%count :initarg :count
           :type fixnum
           :accessor access-count)
   (%space :initarg :space
           :type fixnum
           :accessor access-space)))


(defmethod cl-ds.utils:cloning-information append
    ((sketch bloom-filter))
  '((:counters access-counters)
    (:hashes access-hashes)
    (:count access-count)
    (:space access-space)))


(defmethod compatible-p ((first bloom-filter) &rest more)
  (push first more)
  (and (cl-ds.utils:homogenousp more :key #'access-count)
       (cl-ds.utils:homogenousp more :key #'access-space)
       (cl-ds.utils:homogenousp more :key (compose #'access-counters
                                                   #'length))
       (cl-ds.utils:homogenousp more :key #'access-hashes
                                     :test #'vector=)))


(defmethod initialize-instance :after ((sketch bloom-filter) &rest all)
  (declare (ignore all))
  (bind (((:slots %space %counters %count %hashes) sketch))
    (check-type %space integer)
    (check-type %count integer)
    (check-type %counters (simple-array bit (*)))
    (check-type %hashes (simple-array fixnum (* 2)))
    (unless (eql (array-dimension (access-counters sketch) 0)
                 (access-space sketch))
      (error 'cl-ds:incompatible-arguments
             :parameters '(hashes space)
             :values `(,(access-hashes sketch) ,(access-space sketch))
             :format-control "First dimension of the COUNTERS is expected to be equal to SPACE."))
    (unless (eql (array-dimension %hashes 0)
                 %count)
      (error 'cl-ds:incompatible-arguments
             :parameters '(hashes space)
             :values `(,%hashes ,%space)
             :format-control "First dimension of the hashes is expected to be equal to space."))))


(defmethod cl-ds:clone ((object bloom-filter))
  (cl-ds.utils:quasi-clone* object
    :counters (~> object access-counters copy-array)))


(defmethod union ((first bloom-filter) &rest more)
  (cl-ds.utils:quasi-clone* first
    :counters (apply #'cl-ds.utils:transform
                     #'max
                     (~> first access-counters copy-array)
                     (mapcar #'access-counters more))))


(defmethod cl-ds:at ((container bloom-filter) location &rest more-locations)
  (unless (endp more-locations)
    (error 'cl-ds:dimensionality-error
           :bounds '(1)
           :value (1+ (length more-locations))
           :format-control "Approximated-counts does not accept more-locations"))
  (iterate
    (with hash = (ldb (byte 32 0)
                      (funcall (access-hash-fn container)
                               location)))
    (with counts = (access-counters container))
    (with hashes = (access-hashes container))
    (with count = (access-count container))
    (with space = (access-space container))
    (for j from 0 below count)
    (for value = (aref counts (hashval hashes space j hash)))
    (when (zerop value)
      (leave (values nil t)))
    (finally (return (values t t)))))


(cl-ds.alg.meta:define-aggregation-function
    bloom-filter bloom-filter-function

  (:range &key hash-fn space count key hashes data-sketch)
  (:range &key hash-fn space count (key #'identity) hashes
          (data-sketch
           (clean-sketch
            #'bloom-filter
            :count count
            :space space
            :hashes hashes
            :hash-fn hash-fn)))

  (%data-sketch)

  ((&key data-sketch &allow-other-keys)
   (check-type data-sketch bloom-filter)
   (setf %data-sketch data-sketch))

  ((element)
   (iterate
     (with hash = (funcall (access-hash-fn %data-sketch) element))
     (with hashes = (access-hashes %data-sketch))
     (with counters = (access-counters %data-sketch))
     (with space = (access-space %data-sketch))
     (for j from 0 below (access-count %data-sketch))
     (for position = (hashval hashes space j hash))
     (setf (aref counters position) 1)))

  (%data-sketch))


(defmethod clean-sketch ((function bloom-filter-function)
                         &rest all &key hashes hash-fn space count)
  (declare (ignore all))
  (ensure-functionf hash-fn)
  (check-type space integer)
  (check-type count integer)
  (check-type hashes (or null (simple-array fixnum (* 2))))
  (cl-ds:check-argument-bounds space (< 0 space))
  (cl-ds:check-argument-bounds count (< 0 count))
  (make 'bloom-filter
        :counters (make-array
                   space
                   :initial-element 0
                   :element-type 'non-negative-fixnum)
        :hashes (or hashes (make-hash-array count))
        :hash-fn (ensure-function hash-fn)
        :space space
        :count count))

(in-package :cl-ds.dicts.hamt)


#|

Constants.

|#

(eval-always (define-constant +path-array-size+ 12))


#|

Basic types

|#

(deftype maybe-node ()
  `(or null hash-node bottom-node))


(deftype node-position ()
  `(values maybe-node fixnum))


(deftype hash-node-index ()
  `(integer 0 63))


(deftype just-node ()
  `(or hash-node bottom-node))

#|

Macros

|#

(defmacro hash-do ((node index &optional (count (gensym)))
                   (root hash &optional (max-depth 10))
                   &key on-leaf on-nil on-every)
  "Macro used for writing code going down into hash tree."
  (with-gensyms (!pos !block !leaf)
    (once-only (hash root max-depth)
      `(block ,!block
         (assert (<= ,max-depth 10))
         (do ((,!pos 6 (+ ,!pos 6))
              (,index (ldb (byte 6 0) ,hash)
                      (ldb (byte 6 ,!pos) ,hash))
              (,count 0 (1+ ,count))
              (,!leaf (and ,root (not (hash-node-p ,root)))
                      (hash-node-contains-leaf ,node ,index))
              (,node ,root (and (hash-node-contains ,node ,index)
                                (hash-node-access ,node ,index))))
             ((= ,count ,max-depth)
              (values ,node
                      ,count))
           (declare (type fixnum ,hash ,!pos ,index ,count))
           (progn
             ,(when on-nil
                `(unless ,node
                   (return-from ,!block
                     ,on-nil)))
             ,(when on-leaf
                `(when ,!leaf
                   (return-from ,!block
                     ,on-leaf)))
             ,on-every
             (when (or ,!leaf (null ,node))
               (return-from ,!block ,node))))))))


(defmacro with-hash-tree-functions (container &body body)
  "Simple macro adding local functions (all forwards to the container closures)."
  (once-only (container)
    `(fbind ((equal-fn (read-equal-fn ,container))
             (hash-fn (read-hash-fn ,container)))
       (declare (ignorable (function hash-fn)
                           (function equal-fn)))
       (flet ((compare-fn (a b)
                (the boolean (same-location a b (read-equal-fn ,container)))))
         (declare (ignorable (function compare-fn)))
         ,@body))))


(defmacro with-hamt-path (node root hash max-depth &key on-every on-leaf on-nil operation)
  (with-gensyms (!count !path !indexes !depth !index !block)
    `(block ,!block
       (let* ((,!path (make-array ,+path-array-size+))
              (,!indexes (make-array ,+path-array-size+ :element-type 'fixnum))
              (,!depth 0))
         (declare (type fixnum ,!depth)
                  (type (simple-array fixnum (,+path-array-size+)) ,!indexes)
                  (type (simple-vector ,+path-array-size+) ,!path)
                  (dynamic-extent ,!path ,!indexes ,!depth))
         (hash-do
             (,node ,!index ,!count)
             (,root ,hash ,max-depth)
             :on-every (progn
                         (flet ((perform-operation (next)
                                  (return-from ,!block (,operation ,!indexes ,!path ,!depth next))))
                           (declare (ignorable (function perform-operation)))
                           (macrolet ((delay-operation (next)
                                        `(let ((,',!depth ,',!depth)
                                               (,',node ,',node))
                                           (lambda ()
                                             (return-from ,',!block (,',operation ,',!indexes ,',!path ,',!depth ,next))))))
                             ,on-every))
                         (setf (aref ,!path ,!count) ,node
                               (aref ,!indexes ,!count) ,!index)
                         (incf ,!depth))
             :on-nil (let ((next ,on-nil))
                       (,operation ,!indexes ,!path ,!depth next))
             :on-leaf (let ((next ,on-leaf))
                        (,operation ,!indexes ,!path ,!depth next)))))))


(defun copy-on-write (max-depth indexes path depth conflict)
  (declare (optimize (speed 3)))
  (declare (type (vector fixnum) indexes)
           (type vector path)
           (type fixnum depth)
           (type maybe-node conflict))
  (let ((ac (if (or (hash-node-p conflict)
                    (null conflict))
                ;;if we didn't find element or element was found but depth was already maximal,
                ;;we will just return element, otherwise attempt to divide (rehash) conflicting node into few more
                conflict
                (rebuild-rehashed-node depth
                                       max-depth
                                       conflict))))
    (with-vectors (path indexes)
      (iterate
        (for i from (- depth 1) downto 0) ;reverse order (starting from deepest node)
        (for node = (path i))
        (for index = (indexes i))
        (setf ac (if ac
                     (if (hash-node-contains node index)
                         (hash-node-replace-in-the-copy node ac index)
                         (hash-node-insert-into-copy node ac index))
                     (if (eql 1 (hash-node-size node))
                         (if-let ((data (hash-node-data node)))
                           (make-conflict-node (list data)))
                         (hash-node-remove-from-the-copy node index))))
        (finally (return ac))))))


(defmacro with-copy-on-write-hamt (node container hash &key on-every on-leaf on-nil)
  (with-gensyms (!path !depth !indexes !copy-on-write !max-depth)
    (once-only (container)
      `(let ((,!max-depth (read-max-depth ,container)))
         (flet ((,!copy-on-write (,!indexes ,!path ,!depth conflict) ;path and indexes have constant size BUT only part of it is used, that's why length is passed here
                  (declare (type (simple-array fixnum) ,!indexes)
                           (type simple-array ,!path)
                           (type fixnum ,!depth)
                           (type maybe-node conflict))
                  (copy-on-write ,!max-depth ,!indexes ,!path ,!depth conflict)))
           (declare (dynamic-extent (function ,!copy-on-write))
                    (inline ,!copy-on-write))
           (with-hamt-path ,node (access-root ,container) ,hash ,!max-depth
             :on-leaf ,on-leaf
             :on-every ,on-every
             :on-nil ,on-nil
             :operation ,!copy-on-write))))))


(defmacro with-destructive-erase-hamt (node container hash &key on-leaf on-nil on-every)
  (with-gensyms (!path !depth !indexes !rewrite !max-depth)
    (once-only (container)
      `(let ((,!max-depth (read-max-depth ,container)))
         (flet ((,!rewrite (,!indexes ,!path ,!depth conflict) ;path and indexes have constant size BUT only part of it is used, that's why length is passed here
                  (declare (type (simple-array fixnum) ,!indexes)
                           (type simple-array ,!path)
                           (type fixnum ,!depth)
                           (type maybe-node conflict))
                  (with-vectors (,!path ,!indexes)
                    (iterate
                      (for i from (- ,!depth 1) downto 0) ;reverse order (starting from deepest node)
                      (for node = (,!path i))
                      (for index = (,!indexes i))
                      (for ac initially conflict
                           ;;rehash actually returns cl:hash-table, build-rehashed-node transforms it into another hash-node, depth is increased by 1 this way
                           then (if ac
                                    (progn (hash-node-replace! node ac index)
                                           (finish))
                                    (if (eql 1 (hash-node-size node))
                                        ac
                                        (hash-node-remove! node index))))
                      (finally (return ac))))))
           (declare (dynamic-extent (function ,!rewrite))
                    (inline ,!rewrite))
           (with-hamt-path ,node (access-root ,container) ,hash ,!max-depth
             :on-leaf ,on-leaf
             :on-nil ,on-nil
             :operation ,!rewrite
             :on-every ,on-every))))))


(defmacro set-in-leaf-mask (node position bit)
  `(setf (ldb (byte 1 ,position) (hash-node-leaf-mask ,node)) ,bit))


(defmacro set-in-node-mask (node position bit)
  `(setf (ldb (byte 1 ,position) (hash-node-node-mask ,node)) ,bit))


#|

Tree structure of HAMT

|#

(defstruct hash.location.value
  (hash 0 :type fixnum)
  location
  value)


(declaim (inline make-hash.location.value))


(defstruct hash-node
  (leaf-mask 0 :type (unsigned-byte 64))
  (node-mask 0 :type (unsigned-byte 64))
  (content #() :type simple-array)
  data)


(declaim (inline make-hash-node))


(defclass bottom-node () ()
  (:documentation "Base class of the last (conflict) node. Subclasses present to dispatch relevant logic."))


(-> same-location (hash.location.value hash.location.value (-> (t t) boolean)) boolean)
(defun same-location (existing new-location equal-fn)
  (declare (optimize (speed 3)))
  (and (eql (hash.location.value-hash existing)
            (hash.location.value-hash new-location))
       (funcall equal-fn
                (hash.location.value-location existing)
                (hash.location.value-location new-location))))


(defclass conflict-node (bottom-node)
  ((%conflict :initarg :conflict
              :accessor access-conflict
              :initform (list)
              :type list
              :documentation "List of elements with conflicting hash."))
  (:documentation "Conflict node simply holds list of elements that are conflicting."))


(-> destructive-erase-node (vector (vector fixnum) fixnum) t)
(defun destructive-erase-node (path indexes length)
  (with-vectors (path indexes)
    (iterate
      (for i from (- length 1) downto 0) ;;next to last, because last has to be a conflicting node
      (for n = (path i))
      (for index = (indexes i))
      (for del = (eql 1 (hash-node-size n)))
      (unless del
        (hash-node-remove! n index))
      (while del))))


(-> reconstruct-data-from-subtree! (hash-node) maybe-node)
(-> reconstruct-data-from-subtree (hash-node) maybe-node)
(labels ((scan-impl (path indexes node depth) ;;recursivly scan-impl structure
           (with-vectors ((children (hash-node-content node)) path indexes)
             (iterate
               (for i from 0 below 64)
               (cond ((hash-node-contains-leaf node i)
                      (let ((index (hash-node-to-masked-index node i)))
                        (setf (path depth) (children index)
                              (indexes (1- depth)) i)
                        (leave (1+ depth))))
                     ((hash-node-contains-node node i)
                      (let* ((index (hash-node-to-masked-index node i))
                             (subnode (children index)))
                        (setf (path depth) subnode
                              (indexes (1- depth)) i)
                        (when-let ((result (scan-impl path indexes subnode (1+ depth))))
                          (leave result))))
                     (t nil))))))

  (defun reconstruct-data-from-subtree (node)
    (declare (optimize (speed 3)))
    (let* ((path (make-array +path-array-size+))
           (indexes (make-array +path-array-size+ :element-type 'fixnum)))
      (declare (dynamic-extent path indexes))
      (with-vectors (path indexes)
        (setf (path 0) node)
        (when-let ((length (scan-impl path indexes node 1)))
          (let* ((last (access-conflict (path (1- length))))
                 (next-list (cdr last))
                 (item (car last))
                 (reconstructed-node (copy-on-write 5 ;;this value is not going to be used. I just like number 5. ;-)
                                                    (range-sub-vector indexes 1 length)
                                                    (range-sub-vector path 1 length)
                                                    (- length 2)
                                                    (and next-list (make-conflict-node next-list)))))
            (if reconstructed-node
                (hash-node-replace-in-the-copy node reconstructed-node (indexes 0))
                (if (eql (hash-node-size node) 1)
                    (make-conflict-node (list item))
                    (let ((new-node (hash-node-remove-from-the-copy node (indexes 0))))
                      (setf (hash-node-data new-node) item)
                      new-node))))))))

  (defun reconstruct-data-from-subtree! (node)
    (let* ((path (make-array +path-array-size+))
           (indexes (make-array +path-array-size+ :element-type 'fixnum)))
      (declare (dynamic-extent path indexes))
      (with-vectors (path indexes)
        (setf (path 0) node
              (indexes 0) 0)
        (if-let ((length (scan-impl path indexes node 1)))
          (let* ((last (path (1- length)))
                 (conflict (access-conflict last))
                 (next-list (cdr conflict))
                 (item (car conflict)))
            (cond+ (item next-list)
              ((t t) (progn (setf (access-conflict last) next-list
                                  (hash-node-data node) item)
                            node))
              ((t nil) (progn (setf (hash-node-data node) item)
                              (destructive-erase-node path indexes (1- length))
                              (if (zerop (hash-node-size node))
                                  (make-conflict-node (list next-list))
                                  node))))))))))


(-> make-conflict-node (list) conflict-node)
(defun make-conflict-node (content)
  (assure conflict-node (make-instance 'conflict-node :conflict content)))


(defclass box-node (bottom-node)
  ((%content :initarg :content
             :reader read-content
             :documentation "Internal value of box"))
  (:documentation "Box node holds only one element inside."))


(defgeneric empty-node-p (bottom-node))


(defgeneric contains-p (bottom-node item fn))


(defmethod contains-p ((node conflict-node) item fn)
  (find item (access-conflict node) :test fn))


(defmethod empty-node-p ((node box-node))
  (slot-boundp node '%content))


(defmethod empty-node-p ((node conflict-node))
  (endp (access-conflict node)))


(define-constant +hash-level+ 6)

#|

Interface class.

|#

(defclass fundamental-hamt-container (cl-ds:fundamental-container)
  ((%root :type (or hash-node bottom-node null)
          :accessor access-root
          :initarg :root
          :documentation "Hash node pointing to root of the whole hash tree.")
   (%hash-fn :type (-> (x) fixnum)
             :reader read-hash-fn
             :initarg :hash-fn
             :documentation "Closure used for key hashing. Setted by the user.")
   (%equal-fn :type (-> (t t) boolean)
              :reader read-equal-fn
              :initarg :equal-fn
              :documentation "Closure used for comparing items at the bottom level lists.")
   (%max-depth :initarg :max-depth
               :type (integer 0 10)
               :reader read-max-depth
               :documentation "Maximal depth of tree.")
   (%size :initarg :size
          :initform 0
          :type positive-integer
          :accessor access-size
          :documentation "How many elements are in there?"))
  (:documentation "Base class of other containers. Acts as any container for bunch of closures (those vary depending on the concrete container) and root of the tree."))


(defclass hamt-dictionary (fundamental-hamt-container
                           cl-ds.dicts:dictionary)
  ())


#|

Functions with basic bit logic.

|#

(-> hash-node-whole-mask (hash-node) (unsigned-byte 64))
(defun hash-node-whole-mask (node)
  (logior (hash-node-node-mask node) (hash-node-leaf-mask node)))


(declaim (inline hash-node-whole-mask))


(-> hash-node-to-masked-index (hash-node (hash-node-index)) hash-node-index)
(defun hash-node-to-masked-index (hash-node index)
  (declare (optimize (speed 3) (debug 0) (safety 0) (compilation-speed 0) (space 0)))
  (~>> hash-node
       hash-node-whole-mask
       (ldb (byte index 0))
       logcount))


(declaim (inline hash-node-to-masked-index))


(-> hash-node-contains (hash-node hash-node-index) boolean)
(defun hash-node-contains (hash-node index)
  (declare (optimize (speed 3) (debug 0) (safety 0) (compilation-speed 0) (space 0)))
  (~>> (hash-node-whole-mask hash-node)
       (ldb (byte 1 index))
       zerop
       not))


(-> hash-node-contains-leaf (hash-node hash-node-index) boolean)
(defun hash-node-contains-leaf (hash-node index)
  (declare (optimize (speed 3) (debug 0) (safety 0) (compilation-speed 0) (space 0)))
  (~>> (hash-node-leaf-mask hash-node)
       (ldb (byte 1 index))
       zerop
       not))


(-> hash-node-contains-node (hash-node hash-node-index) boolean)
(defun hash-node-contains-node (hash-node index)
  (declare (optimize (speed 3) (debug 0) (safety 0) (compilation-speed 0) (space 0)))
  (~>> (hash-node-node-mask hash-node)
       (ldb (byte 1 index))
       zerop
       not))


(declaim (inline hash-node-contains))
(declaim (inline hash-node-contains-leaf))
(declaim (inline hash-node-contains-node))


(-> hash-node-access (hash-node hash-node-index) t)
(defun hash-node-access (hash-node index)
  (declare (optimize (speed 3) (debug 0) (safety 0) (compilation-speed 0) (space 0)))
  (handler-case
      (~>> (hash-node-to-masked-index hash-node index)
           (aref (hash-node-content hash-node)))))


(declaim (inline hash-node-access))


(-> hash-node-size (hash-node) (integer 0 64))
(defun hash-node-size (node)
  (logcount (hash-node-whole-mask node)))

#|

Copy nodes and stuff.

|#

(-> hash-node-replace-in-the-copy (hash-node t hash-node-index) hash-node)
(defun hash-node-replace-in-the-copy (hash-node item index)
  (declare (optimize (speed 3) (debug 0) (safety 0) (compilation-speed 0) (space 0)))
  (let* ((content (copy-array (hash-node-content hash-node)))
         (leaf-mask (hash-node-leaf-mask hash-node))
         (node-mask (hash-node-node-mask hash-node))
         (data (hash-node-data hash-node)))
    (declare (type (unsigned-byte 64) leaf-mask node-mask))
    (if (hash-node-p item)
        (setf (ldb (byte 1 index) node-mask) 1
              (ldb (byte 1 index) leaf-mask) 0)
        (setf (ldb (byte 1 index) node-mask) 0
              (ldb (byte 1 index) leaf-mask) 1))
    (setf (aref content (logcount (ldb (byte index 0) (logior leaf-mask node-mask))))
          item)
    (make-hash-node :leaf-mask leaf-mask
                    :node-mask node-mask
                    :content content
                    :data data)))


(declaim (inline hash-node-replace-in-the-copy))


(-> hash-node-insert-into-copy (hash-node t hash-node-index) hash-node)
(defun hash-node-insert-into-copy (hash-node content index)
  (let ((position (hash-node-to-masked-index hash-node index)))
    (with-vectors ((current-array (hash-node-content hash-node))
                   (new-array (make-array (1+ (array-dimension current-array 0)))))
      (assert (~> (array-dimension new-array 0)
                  (<= 64)))
      ;;before new element
      (iterate

        (for i from 0 below position)
        (setf (new-array i)
              (current-array i)))

      ;;new element
      (setf (new-array position)
            content)

      ;;after new element
      (iterate
        (for i from position below (array-dimension current-array 0))
        (setf (new-array (1+ i))
              (current-array i)))

      ;;just make new hash-node
      (let ((node-mask (hash-node-node-mask hash-node))
            (leaf-mask (hash-node-leaf-mask hash-node))
            (data (hash-node-data hash-node)))
        (if (hash-node-p content)
            (setf (ldb (byte 1 index) node-mask) 1)
            (setf (ldb (byte 1 index) leaf-mask) 1))
        (make-hash-node :node-mask node-mask
                        :leaf-mask leaf-mask
                        :content new-array
                        :data data)))))


(defun non-empty-hash-table-p (table)
  (and (typep table 'hash-table)
       (not (zerop (hash-table-count table)))))


(deftype non-empty-hash-table ()
  `(satisfies non-empty-hash-table-p))


(defgeneric rehash (conflict level cont)
  (:documentation "Attempts to divide conflct into smaller ones. Retudnerd hash table maps position of conflict to conflict itself and should contain at least one element"))


(defgeneric single-elementp (conflict)
  (:documentation "Checks if conflict node holds just a single element. Returns t if it does, returns nil if it does not."))


(-> rebuild-rehashed-node (fixnum fixnum bottom-node) just-node)
(-> build-rehashed-node (fixnum fixnum (simple-vector 64)) just-node)
(defun build-rehashed-node (depth max-depth content)
  (let ((mask 0)
        (node-mask 0)
        (leaf-mask 0)
        (size 0))
    (iterate
      (for elt in-vector content)
      (for index from 0)
      (when elt
        (incf size)
        (setf (ldb (byte 1 index) mask) 1)))
    (with-vectors ((array (make-array size)))
      (iterate
        (for conflict in-vector content)
        (for index from 0)
        (when conflict
          (for i = (logcount (ldb (byte index 0) mask)))
          (setf (array i)
                (rebuild-rehashed-node depth
                                       max-depth
                                       conflict))
          (if (hash-node-p (array i))
              (setf (ldb (byte 1 index) node-mask) 1)
              (setf (ldb (byte 1 index) leaf-mask) 1))))
      (make-hash-node :leaf-mask leaf-mask
                      :node-mask node-mask
                      :content array))))


(defun rebuild-rehashed-node (depth max-depth conflict)
  (flet ((cont (array)
           (build-rehashed-node (1+ depth) max-depth array)))
    (declare (dynamic-extent #'cont))
    (if (or (>= depth max-depth) (single-elementp conflict))
        conflict
        (rehash conflict depth
                #'cont))))


(-> build-node (hash-node-index just-node) hash-node)
(defun build-node (index content)
  (if (hash-node-p content)
      (make-hash-node :node-mask (ash 1 index)
                      :content (make-array 1 :initial-element content))
      (make-hash-node :leaf-mask (ash 1 index)
                      :content (make-array 1 :initial-element content))))


(-> hash-node-insert! (hash-node t hash-node-index) hash-node)
(defun hash-node-insert! (node content index)
  (assert (zerop (ldb (byte 1 index) (hash-node-whole-mask node))))
  (let* ((next-size (~> node
                        hash-node-content
                        (array-dimension 0)
                        1+))
         (next-mask (~>> node
                         hash-node-whole-mask
                         (dpb 1 (byte 1 index))))
         (masked-index (~>> next-mask
                            (ldb (byte index 0))
                            logcount)))
    (with-vectors ((n (make-array next-size)) (s (hash-node-content node)))
      (iterate
        (for i from 0 below next-size)
        (cond-compare (i masked-index)
                      (setf (n i) (s i))
                      (setf (n i) content)
                      (setf (n i) (s (1- i)))))
      (setf (hash-node-content node) n)
      (if (hash-node-p content)
          (set-in-node-mask node index 1)
          (set-in-leaf-mask node index 1))
      node)))


(defun hash-node-replace! (node content index)
  (assert (not (zerop (ldb (byte 1 index) (hash-node-whole-mask node)))))
  (with-vectors ((a (hash-node-content node)))
    (setf (a (hash-node-to-masked-index node index))
          content)
    (if (hash-node-p content)
        (progn (set-in-node-mask node index 1)
               (set-in-leaf-mask node index 0))
        (progn (set-in-node-mask node index 0)
               (set-in-leaf-mask node index 1))))
  node)


(-> hash-node-remove-from-the-copy (hash-node fixnum) hash-node)
(-> hash-node-remove! (hash-node fixnum) hash-node)
(flet ((new-array (node index)
         (copy-without (hash-node-content node)
                       (1- (logcount (ldb (byte (1+ index) 0)
                                          (hash-node-whole-mask node)))))))

  (defun hash-node-remove-from-the-copy (node index)
    "Returns copy of node, but without element under index. Not safe, does not check if element is actually present."
    (make-hash-node :leaf-mask (dpb 0 (byte 1 index) (hash-node-leaf-mask node))
                    :node-mask (dpb 0 (byte 1 index) (hash-node-node-mask node))
                    :content (new-array node index)
                    :data (hash-node-data node)))

  (defun hash-node-remove! (node index)
    (setf (hash-node-content node)
          (new-array node index))
    (set-in-leaf-mask node index 0)
    (set-in-node-mask node index 0)
    node))


(-> map-hash-tree ((-> (bottom-node) t) hash-node) hash-node)
(defun map-hash-tree (fn root)
  (iterate
    (with stack = (make-array 32
                              :element-type 'maybe-node
                              :adjustable t
                              :fill-pointer 1
                              :initial-element root))
    (for current = (pop-last stack))
    (while current)
    (for (node . hash-path) = current)
    (etypecase node
      (bottom-node (funcall fn node))
      (hash-node (with-accessors ((mask hash-node-whole-mask)
                                  (content hash-node-content)) node
                   (iterate
                     (for i from 0 below 64)
                     (with index = 0)
                     (unless (~> (ldb (byte 1 i) mask)
                                 zerop)
                       (vector-push-extend (aref content index)
                                           stack)
                       (incf index)))))
      (t (assert (null node)))))
  root)


(-> contains-part-of-hash (fixnum fixnum (integer 0 64)) boolean)
(defun contains-part-of-hash (hash partial-hash depth)
  (~>> hash
       (logxor partial-hash)
       (ldb (byte depth 0))
       zerop))

(defmethod hash-of-bottom-node ((node conflict-node) container)
  (declare (type fundamental-hamt-container container))
  (with-hash-tree-functions container
    (~> node
        access-conflict
        caar
        hash-fn)))


(defmethod rehash ((conflict conflict-node) level cont)
  (declare (type conflict-node conflict))
  (let ((result (make-array 64 :initial-element nil))
        (byte (byte +hash-level+ (* +hash-level+ level))))
    (declare (dynamic-extent byte)
             (dynamic-extent result))
    (iterate
      (for item in (access-conflict conflict))
      (for hash = (hash.location.value-hash item))
      (for index = (ldb byte hash))
      (push item (access-conflict (ensure (aref result index)
                                    (make 'conflict-node)))))
    (funcall cont result)))


(defmethod single-elementp ((conflict conflict-node))
  (endp (cdr (access-conflict conflict))))


(defgeneric print-hamt (obj stream &optional indent)
  (:method ((obj hash-node) stream &optional indent)
    (ensure indent 0)
    (format stream "~v@{~a~:*~}<HN: " indent " ")
    (format stream "~b~%" (hash-node-whole-mask obj))
    (iterate
      (for elt in-vector (hash-node-content obj))
      (for i from 1)
      (print-hamt elt stream (1+ indent))
      (unless (eql i (length (hash-node-content obj)))
        (format stream "~%")))
    (format stream ">")
    obj)
  (:method ((obj (eql nil)) stream &optional indent)
    (ensure indent 0)
    (format stream "~v@{~a~:*~}EMPTY" indent " ")
    obj)
  (:method ((obj conflict-node) stream &optional indent)
    (ensure indent 0)
    (format stream "~v@{~a~:*~}(" indent " ")
    (iterate
      (for sub on (access-conflict obj))
      (for elt = (car sub))
      (for key = (hash.location.value-location elt))
      (for value = (hash.location.value-value elt))
      (if (cdr sub)
          (format stream "~A:~A, " key value)
          (format stream "~A:~A" key value)))
    (format stream ")")
    obj))


(defmethod print-object ((obj hash-node) stream)
  (print-hamt obj stream)
  obj)


(defmethod print-object ((obj conflict-node) stream)
  (print-hamt obj stream)
  obj)

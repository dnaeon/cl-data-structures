(cl:in-package #:cl-ds.rf)


(defmethod make-submodel-with-model ((main-model random-forest-classifier)
                                     data
                                     arguments)
  (make-submodel (submodel-class main-model) data arguments))


(defmethod make-node ((main-model random-forest-classifier)
                      data arguments)
  (let ((split-attempts (split-attempts main-model))
        (tree-maximum-depth (tree-maximum-depth main-model))
        (tree-minimal-size (tree-minimal-size main-model)))
    (labels ((summary-group-to-node (group depth)
               (bind (((group-class content) group)
                      (size (cl-ds:at content :count))
                      (group-data (cl-ds:at content :content)))
                 (cons group-class
                       (when (>= size tree-minimal-size)
                         (node (1- depth) group-data)))))
             (gini-impurity (summary data-size)
               (cl-ds.alg:accumulate summary
                                     #'+
                                     :initial-value 0.0
                                     :key (lambda (group &aux (x (cdr group)))
                                            (* (cl-ds:at x :count)
                                               (/ (cl-ds:at x :gini)
                                                  data-size)))))
             (node (data depth)
               (when (<= depth 0)
                 (return-from node nil))
               (iterate outer
                 (repeat split-attempts)
                 (for submodel = (make-submodel-with-model main-model
                                                           data
                                                           arguments))
                 (train submodel data)
                 (for submodel-predictions = (predict main-model data))
                 (for data-size = (length data))
                 (for grouped-predictions = (cl-ds.alg:group-by
                                                submodel-predictions
                                              :key #'second))
                 (for summary = (cl-ds.alg:summary grouped-predictions
                                  :count (cl-ds.alg:count-elements)
                                  :content (cl-ds.alg:to-vector :key #'first)
                                  :gini (cl-ds.math:gini-impurity
                                         :key #'cadar)))
                 (for classes-count = (cl-ds:size summary))
                 (for gini-impurity = (gini-impurity summary
                                                     data-size))
                 (finding (list* summary submodel)
                          minimizing gini-impurity
                          into result)
                 (finally
                  (iterate
                    (with summary = (car result))
                    (with submodel = (cdr result))
                    (with size = (cl-ds:size summary))
                    (with children = (make-array size))
                    (for i from 0 below size)
                    (for (values group more) = (cl-ds:consume-front result))
                    (setf (aref children i)
                          (summary-group-to-node group depth))
                    (finally (return-from outer
                               (make 'tree-node
                                     :submodel submodel
                                     :children children))))))))
      (node data tree-maximum-depth))))
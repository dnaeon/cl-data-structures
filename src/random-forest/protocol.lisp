(cl:in-package #:cl-ds.rf)


(defgeneric submodel-predict (submodel context))
(defgeneric make-submodel-prediction-contexts-of-class (class submodels))
(defgeneric make-submodel-prediction-contexts (model count))
(defgeneric make-submodel-of-class (class creation-context data))
(defgeneric make-submodel-creation-context (main-model))
(defgeneric make-submodel-creation-context-of-class (class))
(defgeneric make-submodel (main-model creation-context data))
(defgeneric make-node (main-model data))
(defgeneric submodel-class (main-model))
(defgeneric predict (model data))
(defgeneric encode-data-into-contexts (model contexts data))
(defgeneric encode-data-into-contexts-of-class (class contexts data))
(defgeneric encode-data-into-context (submodel context data))
(defgeneric tree-count (model))
(defgeneric tree-maximum-depth (model))
(defgeneric submodels (model))
(defgeneric split-attempts (model))
(defgeneric tree-minimal-size (model))
(defgeneric make-model (class data arguments))
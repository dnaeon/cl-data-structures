(in-package #:cl-user)
(defpackage moments-tests
  (:use #:cl #:prove #:serapeum #:cl-ds #:iterate #:alexandria :metabang-bind)
  (:shadowing-import-from #:iterate #:collecting #:summing #:in))

(in-package #:moments-tests)


(plan 4)


(bind ((xpr (xpr (:x 0)
              (when (< x 100)
                (send-recur 5 :x (1+ x)))))
       (moments (cl-ds.math:moments xpr 2 3 5)))
  (is (cl-ds:size moments) 3)
  (is (cl-ds:at moments 2) 0)
  (is (cl-ds:at moments 3) 0)
  (is (cl-ds:at moments 4) 0))


(finalize)
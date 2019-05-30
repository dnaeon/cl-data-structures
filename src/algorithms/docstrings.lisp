(in-package #:cl-data-structures.algorithms)
(eval-always
  (scribble:configure-scribble :package :cl-data-structures.algorithms)
  (named-readtables:in-readtable :scribble))


(docs:define-docs
  :formatter docs.ext:rich-aggregating-formatter

  (function accumulate
    (:description "Like CL:REDUCE but works on all traversable objects."
     :see-also (cumulative-accumulate)))

  (function cumulative-accumulate
    (:description "Like ACCUMULATE, but produces range with all intermediate accumulation states."
     :see-also (accumulate)))

  (function distinct
    (:arguments ((range "Input range.")
                 (test "Function used to compare elements. Defaults to EQL.")
                 (hash-function "Function used for hashing. Defaults to #'sxhash.")
                 (key "Key function, used to extract values for test."))
     :exceptional-situations "Will signal a TYPE-ERROR if either TEST, HASH-FUNCTION or KEY is not funcallable."
     :returns "FUNDAMENTAL-FORWARD-RANGE instance."
     :description "Returns forward range that skips elements that were already seen."))

  (function split-into-chunks
    (:description "Divides aggregation process into partitions up to size."
     :returns "Instance of SPLIT-INTO-CHUNKS-PROXY range subclass."
     :exceptional-situations ("Will signal type error if CHUNK-SIZE is not INTEGER."
                              "Will signal ARGUMENT-OUT-OF-BOUNDS if CHUNK-SIZE is not above 0.")
     :examples [(let ((data (cl-ds.alg:to-vector (cl-ds.alg:split-into-chunks #(1 2 3 4 5 6) 2))))
                  (prove:is (cl-ds:size data) 3)
                  (prove:is (cl-ds:at data 0) #(1 2) :test 'equalp)
                  (prove:is (cl-ds:at data 1) #(3 4) :test 'equalp)
                  (prove:is (cl-ds:at data 2) #(5 6) :test 'equalp))]))

  (function partition-if
    (:description "Groups consecutive elements in the range into a partition if TEST called on the previous value in the range and the current value in the range returns non-NIL, creates new partition otherwise. This does not change the content of the RANGE, but it will force aggregation to be performed on every group independently. Order of the groups is preserved in the aggregation result."
     :examples [(let* ((data '((1 "w") (1 "o") (1 "r") (1 "d") (2 "a") (2 "s") (3 "l") (3 "a") (3 "w")))
                       (partitioned (cl-ds.alg:partition-if data (lambda (prev next) (= (first prev) (first next)))))
                       (aggregated (cl-ds.alg:to-vector partitioned :element-type 'character
                                                                    :key (alexandria:compose #'alexandria:first-elt
                                                                                             #'second))))
                  (prove:is (cl-ds.alg:to-vector aggregated) #("word" "as" "law") :test #'equalp))]
     :notes ("Aggregation on the returned range is performed eagerly."
             "Can be considered to be alternative to the GROUP-BY, suitable for the ordered data.")
     :returns "FUNDAMENTAL-RANDOM-ACCESS-RANGE instance."
     :arguments ((range "An input range.")
                 (test "A function of two arguments used to check if elements belong to the same partition."))))

  (function to-list
    (:description "Collects all elements into a CL:LIST."
     :returns "CL:LIST with the content of the RANGE."
     :exceptional-situations ("Will signal a TYPE-ERROR if KEY is not funcallable.")))

  (function translation
    (:description "Substitutes element in the range with one found in the DICT, if present. If not, leaves element unchanged."
     :returns "ON-EACH-RANGE subclass."
     :exceptional-situations ("Will signal a TYPE-ERROR if KEY is not funcallable.")))

  (function to-vector
    (:description "Collects all elements into a CL:VECTOR."
     :returns "CL:VECTOR with the content of the RANGE."
     :notes ("There is no way to know ahead of time how large vector will be created, and therefore multiple reallocations may be performed during aggregation. A user can supply :SIZE to mitigate that."
             "To avoid copying in the case when RANGE is also a vector, pass NIL as :FORCE-COPY.")
     :exceptional-situations ("Will signal a TYPE-ERROR if KEY is not funcallable."
                              "Will signal same conditions as make-array would when ELEMENT-TYPE or SIZE are invalid.")
     :arguments ((range "Object to aggregate.")
                 (:key "Key function used to extract value to the result vector.")
                 (:element-type ":ELEMENT-TYPE for the result vector.")
                 (:size "Initial size of the internal vector. Supplie to minimize memory allocations count.")
                 (:force-copy "When false, TO-VECTOR called with CL:VECTOR is allowed to return the input."))))

  (function to-hash-table
    (:description "Collects all elements into a CL:HASH-TABLE."
     :exceptional-situations ("Will signal a TYPE-ERROR if either KEY, HASH-TABLE-VALUE, HASH-TABLE-KEY is not funcallable."
                              "Will signal a TYPE-ERROR if TABLE is not of type CL:HASH-TABLE."
                              "Will signal conditions just like MAKE-HASH-TABLE would if either SIZE or TEST is invalid.")
     :arguments ((:key "Key function used to extract value to the result vector.")
                 (:test "Test fo the MAKE-HASH-TABLE.")
                 (:size "Size for the MAKE-HASH-TABLE.")
                 (:table "Optional, initial HASH-TABLE.")
                 (:hash-table-key "Function used to extract key for the HASH-TABLE. Defaults to IDENTITY.")
                 (:hash-table-value "Function used to extract value for the HASH-TABLE. Defaults to IDENTITY."))
     :returns "CL:HASH-TABLE with the content of the RANGE."))

  (function on-each
    (:description "Creates a new range by applying the FUNCTION to each element of the RANGE."
     :arguments ((range "Input range.")
                 (function "Function called on the RANGE content.")
                 (key "Function used to extract content for the FUNCTION. Defaults to the CL:IDENTITY."))
     :returns "FUNDAMENTAL-FORWARD-RANGE instance."
     :exceptional-situations "Will signal a TYPE-ERROR if KEY or FUNCTION is not funcallable."
     :notes "Works almost like cl:map-and-friends, but lazily evaluates content."))

  (function count-elements
    (:description "Counts the number of elements. Useful mostly in conjunction with a GROUP-BY."
     :returns "Integer."
     :arguments ((range "Input range."))
     :examples [(let ((data #(1 2 3 4 5)))
                  (prove:is (length data) (cl-ds.alg:count-elements data))
                  (prove:is 3 (cl-ds:at (cl-ds.alg:count-elements (cl-ds.alg:group-by data :key #'evenp))
                                        nil)))]
     :see-also (group-by)))

  (function enumerate
    (:description "Gathers unique elements in the RANGE and assigns a number to each (starting with zero, incrementing)."
     :returns "CL:HASH-TABLE, unique elements used as keys, numbers stored as values."
     :exceptional-situations ("Will signal a TYPE-ERROR if either KEY, HASH-TABLE-KEY is not funcallable."
                              "Will signal a TYPE-ERROR if TABLE is not of type CL:HASH-TABLE."
                              "Will signal conditions just like MAKE-HASH-TABLE would if either SIZE or TEST is invalid.")
     :arguments ((:key "Key function used to extract value to the result vector.")
                 (:test "Test fo the MAKE-HASH-TABLE.")
                 (:size "Size for the MAKE-HASH-TABLE.")
                 (:table "Optional, initial HASH-TABLE.")
                 (:hash-table-key "Function used to extract key for the HASH-TABLE. Defaults to IDENTITY."))))

  (function hash-join
    (:description "Joins multiple ranges using the hash join algorithm."
     :returns "FUNDAMENTAL-FORWARD-RANGE instance."
     :arguments ((primary-range "Input range.")
                 (primary-key "Key function used to extract values from the PRIMARY-RANGE.")
                 (secondary-range-forms "List of forms describing the other ranges.")
                 (:test "Test for the inner HASH-TABLE.")
                 (:join-function "Function applied to each group. Defaults to CL:LIST.")
                 (:key "Key function. Defaults to CL:IDENTITY."))
     :examples [(let ((result (cl-ds.alg:hash-join #(1 2 3 4) #'identity
                                                   (list (cl-ds:field :data #(1 2 3)
                                                                      :key #'identity)))))
                  (map nil (lambda (x) (prove:is (first x) (second x))) result))]))

  (function chain
    (:description "Concatenate multiple ranges into one."
     :examples [(prove:is (cl-ds.alg:to-vector (cl-ds.alg:chain '(1 2 3) '(4 5 6)))
                          #(1 2 3 4 5 6)
                          :test #'equalp)]
     :exceptional-situations ("Raises TYPE-ERROR if any of the input ranges is not (OR CL:SEQUENCE FUNDAMENTAL-FORWARD-RANGE).")
     :returns "FUNDAMENTAL-FORWARD-RANGE instance."))

  (function shuffled-range
    (:description "Creates a range of shuffled integers from FROM, to TO."
     :arguments ((from "The lowest integer.")
                 (to "The highest integer."))
     :exceptional-situations ("Raises TYPE-ERROR if FROM or TO is not an integer."
                              "TO must be equal or greater than FROM, otherwise the incompatible-arguments error is signaled.")
     :returns "FUNDAMENTAL-FORWARD-RANGE instance."))

  (function summary
    (:description "The summary is a macro allowing performance of multiple aggregations in one function call."
     :examples [(let ((result (cl-ds.alg:summary (cl-ds:iota-range :to 250)
                                :min (cl-ds.alg:accumulate #'min)
                                :max (cl-ds.alg:accumulate #'max))))
                  (prove:is (cl-ds:at result :min) 0)
                  (prove:is (cl-ds:at result :max) 249))]
     :arguments ((range "Range to aggregate.")
                 (forms "Description of function invocation in the form of the plist. Key is a label used to identify value in the result range, a value is an aggregation function form (function and the function arguments). The range will be inserted as the first argument in the aggregation function call by default, or in the place of any symbol with name '_' if such symbol is present."))
     :returns "Range of results. Use cl-ds:at with label to extract result of each individual aggregation form."
     :notes ("Currently, this macro does support only the single stage aggregation functions."
             "This macro expands to %SUMMARY call. Programmer may opt to write %SUMMARY call directly despite extra boilerplate required."
             "Particularly useful when the iteration over the range requires considerable time alone and therefore repeating it should be avoided for efficiency sake.")))

  (function only
    (:description "A layer function. Creates a range that skips elements that PREDICATE (KEY element) => NIL."
     :exceptional-situations "Will signal a TYPE-ERROR if either PREDICATE or KEY is not funcallable."
     :arguments ((range "Input range.")
                 (predicate "Test used to check if element should be skipped.")
                 (key "Key function used to extract a value for predicate."))
     :returns "Either forward, bidirectional or random-access range, depending on the RANGE."))

  (function without
    (:description "A layer function. Creates a range that skips elements that PREDICATE (KEY element) => T."
     :exceptional-situations "Will signal a TYPE-ERROR if either PREDICATE or KEY is not funcallable."
     :arguments ((range "Input range.")
                 (predicate "Test used to check if an element should be skipped.")
                 (key "Key function used to extract a value for the predicate."))
     :returns "Either forward, bidirectional or random-access range, depending on the RANGE."))

  (function flatten-lists
    (:description "A layer function. Flattens each list in the input range to the atoms."
     :exceptional-situations "Will signal a TYPE-ERROR if KEY is not funcallable."
     :arguments ((range "Input range.")
                 (key "Function used to extract lists from elements of the RANGE. Defaults to CL:IDENTITY."))
     :notes ("Pretty much the same purpose ALEXANDRIA:FLATTEN.")
     :returns "FUNDAMENTAL-FORWARD-RANGE instance."))

  (function latch
    (:description "Combines primary range with multiple latch ranges. The returned range contains elements picked from the primary range, where, on corresponding positions, each of the latch ranges contains a non-nil value."
     :arguments ((range "Primary input range.")
                 (latch "Range with boolean values.")
                 (more-latches "Ranges with boolean values."))
     :returns "FUNDAMENTAL-FORWARD-RANGE instance."))

  (function zip
    (:description "Combines multiple ranges into a single range by applying FUNCTION elementwise."
     :exceptional-situations ("Raises TYPE-ERROR if any of the input ranges is not (OR CL:SEQUENCE FUNDAMENTAL-FORWARD-RANGE)."
                              "Will raise TYPE-ERROR if FUNCTION is not FUNCALLABLE.")
     :notes "Can be considered to be lazy variant of CL:MAP function called on multiple sequences."
     :examples ([(prove:is (cl-ds.alg:to-vector (cl-ds.alg:zip #'list '(1 2 3) '(4 5 6)))
                           #((1 4) (2 5) (3 6))
                           :test #'equalp)])
     :returns "New fundamental-forward-range instance."
     :arguments ((function "Function used to join contents of the RANGES.")
                 (ranges "Input."))))

  (function repeat
    (:description "A layer function. Constructs new range from the RANGE. The new range is cyclic and will reset to initial position once the end is reached when calling the CONSUME-FRONT function or after calling TRAVERSE. This happens always by default, and can be limited to a number of times by supplying optional TIMES argument. This function can be therefore used to go over the same range multiple times in a aggregation function."
     :arguments ((range "Input range used to construct the result.")
                 (times "How many times the range will be repeated? Unlimited by default."))
     :exceptional-situations ("Will raise the TYPE-ERROR when TIMES is not of the type (OR NULL POSITIVE-INTEGER).")
     :returns "FUNDAMENTAL-FORWARD-RANGE instance."))

  (function restrain-size
    (:description "A layer function. Constructs new range from the RANGE. New range contains a limit on how many times consume-front can be called on it before returning (values nil nil), effectively reducing size of the RANGE."
     :arguments ((range "Input range used to construct the result.")
                 (size "What should be the limit on the new range?"))
     :returns "FUNDAMENTAL-FORWARD-RANGE instance."
     :exceptional-situations ("Will raise a TYPE-ERROR when the SIZE is not of the type INTEGER."
                              "Will raise ARGUMENT-OUT-OF-BOUNDS when the SIZE is negative.")))

  (function extremum
    (:description "An aggregation function. Finds the extremum (the first value that would occur if the whole range was sorted according to the FN). This can be used to find either the maximum or the minimum."
     :exceptional-situations "Will signal a TYPE-ERROR if either FN, KEY or VALUE-KEY is not funcallable."
     :arguments ((range "Input range.")
                 (fn "Comparsion function.")
                 (key "Function used to extract values from the elements in the RANGE.")
                 (value-key "Like KEY, but using this instead will preserve the complete element in the result. This argument can be used in combination with KEY, in which case KEY is applied before the VALUE-KEY."))
     :notes ("Shadows alexandria:extremum.")
     :returns "Single extremum value."))

  (function extrema
    (:description "An aggregation function. Finds extrema (both minimum and maximum) in the RANGE, according to the FN comparsion function."
     :exceptional-situations "Will signal a TYPE-ERROR if either FN, KEY or VALUE-KEY is not funcallable."
     :arguments ((range "Input range.")
                 (fn "Comparsion function.")
                 (key "Function used to extract values from the elements in the RANGE.")
                 (value-key "Like KEY, but using this instead will preserve the complete element in the result. This argument can be used in combination with KEY, in which case KEY is applied before the VALUE-KEY."))
     :notes ("Shadows serapeum:extrema.")
     :returns "Dotted pair. The first value is the extremum that would occur as the first element in the sequence sorted according to the FN, second value is an element that would occur as the last."))

  (function cartesian
    (:description "Combines RANGES into a singular range that contains results of FUNCTION application on cartesian combination of all elements in the input RANGES."
     :arguments ((function "Function used to combine input ranges.")
                 (range "First input range.")
                 (more-ranges "All other ranges."))
     :exceptional-situations "Will raise a TYPE-ERROR if any of the RANGES is of a wrong type."
     :returns "FUNDAMENTAL-FORWARD-RANGE instance."))

  (function group-by
    (:description "Groups RANGE into partitions according to the TEST. This does not change the content of the RANGE, but will force aggregation to be performed on every group independently."
     :exceptional-situations ("Will signal a TYPE-ERROR if KEY is not funcallable."
                              "Will pass TEST to MAKE-HASH-TABLE and therefore will signal same conditions as MAKE-HASH-TABLE.")
     :arguments ((range "Range that is supposed to be groupped.")
                 (key "Key function, used to extract value for TEST.")
                 (test "Test for inner hashtable (either eq, eql or equal)."))
     :returns "GROUP-BY-RANGE instance (either forward, bidirectional or random access, based on the class of the RANGE)."
     :examples [(let* ((data #(1 2 3 4 5 6 7 8 9 10))
                       (sums (cl-ds.alg:accumulate (cl-ds.alg:group-by data :key #'evenp) #'+)))
                  (prove:is (cl-ds:size sums) 2)
                  (prove:is (cl-ds:at sums t) 30)
                  (prove:is (cl-ds:at sums nil) 25))])))

(in-package #:cl-data-structures.streaming-algorithms)
(eval-always
  (scribble:configure-scribble :package :cl-data-structures.streaming-algorithms)
  (named-readtables:in-readtable :scribble))

(docs:define-docs
  :formatter docs.ext:rich-aggregating-formatter

  (function
    approximated-set-cardinality
    (:description "Calculates estimated set cardinality using HyperLogLog algorithm. This requires only a constant ammount of memory."
     :arguments ((range "Object to aggregate.")
                 (bits "How many bits per register should be used? Should be at least 4, and 20 at most. Large values are prefered for accurate results.")
                 (hash-fn "Hashing function. SXHASH will do for strings.")
                 (key "Function used to extract extract value from each element."))
     :notes ("This algorithm gives solid estimates for large sets, not so good for small sets."
             "Fairly sensitive to a hash function. Large avalanche factor is very helpful."
             "Can be used to (for instance) estimate number of keys for hash table before creating one. Good estimate will minimize rehashing and reduce both memory that needs to allocated and time required to fill hash table.")
     :returns "Object storing internal state. Use CL-DS:VALUE to extract estimate from it."
     :examples [(let ((data (cl-ds:xpr (:i 0)
                              (when (< i 500000)
                                (cl-ds:send-recur (random 99999999999) :i (1+ i))))))
                  (prove:ok (< 490000
                               (cl-ds:value
                                (cl-data-structures.streaming-algorithms:approximated-set-cardinality
                                 data
                                 20
                                 #'sxhash))
                               510000)))]))

  (function
    approximated-counts
    (:description "Calculates estimated counts using Min-Count sketch alogrithm. This requiret only a constant ammount of memory."
     :arguments ((range "Object to aggregate.")
                 (hash-fn "Hashing function. SXHASH will do for strings.")
                 (space "Positive integer. Size of the counters array")
                 (count "Number of hashing functions used."))
     :returns "Object storing internal state. Use CL-DS:AT to extract count estimate for element from it. CL-DS:SIZE can be used to extract the total size of range that was aggregated."
     :notes ("Quality of the estimate directly depends on DEPTH and WIDTH."
             "Sensitive to a hash function. Large avalanche factor is very helpful.")))

  (function
    bloom-filter
    (:description "Creates bloom filter out of elements in the range. Bloom filter is memory efficient data structures allowing to check if item is absent from the range (if at returns nil, item is certainly absent, if at returns t item either present or not)."
     :returns "Bloom filter object. Use cl-ds:at to check if element is present. False positives are possible, false negatives are not possible."
     :arguments ((range "Input for the creation of the bloom filter.")
                 (space "Positive-fixnum. What is the bloom vector size?")
                 (count "How many bits are used for each item?")
                 (:key "Function used to extract value for to hashing.")
                 (:hashes "Optional hashes vector. Needs to be supplied if ensuring same hash values between different filters is required.")))))

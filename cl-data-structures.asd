(in-package #:cl-user)


(asdf:defsystem cl-data-structures
  :name "cl-data-structures"
  :version "0.0.0"
  :license "BSD simplified"
  :author "Lisp Mechanics"
  :maintainer "Lisp Mechanics"
  :depends-on ( :iterate          :alexandria
                :serapeum         :prove
                :prove-asdf       :documentation-utils-extensions
                :more-conditions  :closer-mop
                :lparallel        :flexichain
                :metabang-bind    :bordeaux-threads
                :scribble         :osicat
                :cl-fad           :cl-progress-bar
                :trivial-garbage  :cl-ppcre)
  :defsystem-depends-on (:prove-asdf)
  :serial T
  :pathname "src"
  :components ((:file "aux-package")
               (:file "package")
               (:module "utils"
                :components ((:file "package")
                             (:file "macros")
                             (:file "types")
                             (:file "higher-order")
                             (:file "cartesian")
                             (:file "ordered-algorithms")
                             (:file "lists")
                             (:file "trivial")
                             (:file "modification-algorithms")
                             (:file "distances")
                             (:file "lazy-shuffle")
                             (:file "arrays")
                             (:file "trees")
                             (:file "bind")
                             (:file "parallel-tools")
                             (:file "lambda-lists")
                             (:file "skip-vector")
                             (:file "embedding")
                             (:file "cloning")
                             (:file "docstrings")
                             (:module "metric-functions"
                              :components ((:file "package")
                                           (:file "levenshtein")
                                           (:file "hellinger")
                                           (:file "average-metric")
                                           (:file "hausdorff")
                                           (:file "euclid")
                                           (:file "earth-mover")
                                           (:file "svr")
                                           (:file "docstrings")))
                             (:module "distance-functions"
                              :components ((:file "package")
                                           (:file "sinkhorn")
                                           (:file "bhattacharyya")
                                           (:file "docstrings")))
                             (:module "clustering"
                              :components ((:file "package")
                                           (:file "common")
                                           (:module "k-means"
                                            :components ((:file "package")
                                                         (:file "types")
                                                         (:file "internal")
                                                         (:file "external")
                                                         (:test-file "tests")))
                                           (:module "clara-pam"
                                            :components ((:file "package")
                                                         (:file "types")
                                                         (:file "internal")
                                                         (:file "external")
                                                         (:file "docstrings")
                                                         (:test-file "tests")))))
                             (:test-file "distances-tests")
                             (:test-file "ordered-algorithms-tests")
                             (:test-file "lazy-shuffle-tests")))
               (:module "api"
                :components ((:file "meta")
                             (:file "meta-docstrings")
                             (:file "fundamental-classes")
                             (:file "trait-classes")
                             (:file "generics")
                             (:file "conditions")
                             (:file "expression-wrapper")
                             (:file "delay")
                             (:file "macros")
                             (:file "functions")
                             (:file "field")
                             (:file "aux")
                             (:file "docstrings")
                             (:test-file "expression-tests")))
               (:module "adapters"
                :components ((:file "package")
                             (:file "hash-table")
                             (:file "vector")
                             (:file "list")
                             (:test-file "vector-tests")))
               (:module "common"
                :components ((:file "package")
                             (:file "modification-operation-status")
                             (:file "eager-modification-operation-status")
                             (:file "lazy-box")
                             (:file "lazy-range")
                             (:file "content-tuple")
                             (:file "ranges")
                             (:file "sequence-window")
                             (:file "docstrings")
                             (:test-file "sequence-window-tests")
                             (:module "abstract"
                              :components ((:file "package")
                                           (:file "common")))
                             (:module "2-3-tree"
                              :components ((:file "package")
                                           (:file "common")
                                           (:test-file "tests.lisp")))
                             (:module "hamt"
                              :components ((:file "package")
                                           (:file "common")))
                             (:module "rrb"
                              :components ((:file "package")
                                           (:file "common")))
                             (:module "egnat"
                              :components ((:file "package")
                                           (:file "classes")
                                           (:file "generics")
                                           (:file "common")
                                           (:file "methods")
                                           (:file "docstrings")
                                           (:test-file "tests")))))
               (:module "dicts"
                :components ((:file "packages")
                             (:file "trait-classes")
                             (:file "common")
                             (:file "api")
                             (:file "docstrings")
                             (:module "hamt"
                              :components ((:file "api")
                                           (:file "docstrings")
                                           (:test-file "transactions-tests")
                                           (:test-file "range-test")
                                           (:test-file "lazy-tests")))
                             (:module "srrb"
                              :components ((:file "types")
                                           (:file "internal")
                                           (:file "api")
                                           (:test-file "tests")))
                             (:test-file "functional-dictionary-test-suite")
                             (:test-file "mutable-dictionary-test-suite")
                             (:test-file "transactional-dictionary-test-suite")))
               (:module "sequences"
                :components ((:file "packages")
                             (:file "common")
                             (:module "rrb"
                              :components ((:file "api")
                                           (:file "docstrings")
                                           (:test-file "tests")))))
               (:module "queues"
                :components ((:file "packages")
                             (:file "common")
                             (:file "docstrings")
                             (:module "2-3-tree"
                              :components ((:file "api")
                                           (:test-file "tests")))))
               (:module "metric-space"
                :components ((:file "packages")
                             (:file "trait-classes")
                             (:file "common")
                             (:file "api")
                             (:file "docstrings")
                             (:module "egnat"
                              :components ((:file "api")
                                           (:test-file "tests")))))
               (:module "algorithms"
                :components ((:file "package")
                             (:module "meta"
                              :components ((:file "macros")
                                           (:file "classes")
                                           (:file "generics")
                                           (:file "methods")
                                           (:file "docstrings")
                                           (:test-file "meta-tests")))
                             (:file "common")
                             (:file "on-each")
                             (:file "count")
                             (:file "to-vector")
                             (:file "shuffled-range")
                             (:file "filtering")
                             (:file "common-range-category")
                             (:file "summary")
                             (:file "change-each!")
                             (:file "accumulate")
                             (:file "group-by")
                             (:file "without")
                             (:file "only")
                             (:file "cartesian")
                             (:file "restrain-size")
                             (:file "repeat")
                             (:file "latch")
                             (:file "extrema")
                             (:file "extremum")
                             (:file "cumulative-accumulate")
                             (:file "split-into-chunks")
                             (:file "hash-join")
                             (:file "chain")
                             (:file "zip")
                             (:file "flatten-lists")
                             (:file "partition-if")
                             (:file "distinct")
                             (:file "docstrings")
                             (:test-file "split-into-chunks-test")
                             (:test-file "partition-if-test")
                             (:test-file "hash-join-test")
                             (:test-file "without-test")
                             (:test-file "extrema-test")
                             (:test-file "summary-test")
                             (:test-file "chain-test")
                             (:test-file "on-each-test")
                             (:test-file "zip-test")))
               (:module "file-system"
                :components ((:file "package")
                             (:file "common")
                             (:file "line-by-line")
                             (:file "tokenize")
                             (:file "find")
                             (:file "docstrings")))
               (:module "threads"
                :components ((:file "package")
                             (:file "buffer-range")
                             (:file "in-parallel")
                             (:file "docstrings")))
               (:module "clustering"
                :components ((:file "package")
                             (:file "clara")
                             (:file "k-means")
                             (:file "docstrings")))
               (:module "math"
                :components ((:module "aux"
                              :components ((:file "package")
                                           (:file "gamma")))
                             (:file "package")
                             (:file "average")
                             (:file "variance")
                             (:file "mutual-information")
                             (:file "simple-linear-regression")
                             (:file "median-absolute-deviation")
                             (:file "hodges-lehmann")
                             (:file "co-occurence-table")
                             (:file "standard-deviation")
                             (:file "moments")
                             (:file "statistical-summary")
                             (:file "chi-squared")
                             (:file "bootstrap")
                             (:file "moving-average")
                             (:file "hmm")
                             (:file "docstrings")
                             (:test-file "moments-tests")
                             (:test-file "chi-squared-tests")
                             (:test-file "mutual-information-tests")
                             (:test-file "statistical-summary-tests")
                             (:test-file "simple-linear-regression-tests")))
               (:module "streaming-algorithms"
                :components ((:file "package")
                             (:file "common")
                             (:file "approximated-set-cardinality")
                             (:file "approximated-counts")
                             (:file "bloom-filter")
                             (:file "docstrings")))
               (:module "counting"
                :components ((:file "package")
                             (:file "generics")
                             (:file "types")
                             (:file "internal")
                             (:file "apriori")
                             (:file "methods")
                             (:file "docstrings")
                             (:test-file "tests")))))

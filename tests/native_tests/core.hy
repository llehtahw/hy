;; Copyright 2021 the authors.
;; This file is part of Hy, which is free software licensed under the Expat
;; license. See the LICENSE.

(import
  [itertools [repeat cycle islice]]
  pytest)

;;;; some simple helpers

(defn assert-true [x]
  (assert (= True x)))

(defn assert-false [x]
  (assert (= False x)))

(defn assert-equal [x y]
  (assert (= x y)))

(defn assert-none [x]
  (assert (is x None)))

(defn assert-requires-num [f]
  (for [x ["foo" [] None]]
    (try (f x)
         (except [TypeError] True)
         (else (assert False)))))

(defn test-coll? []
  "NATIVE: testing coll?"
  (assert-true (coll? [1 2 3]))
  (assert-true (coll? {"a" 1 "b" 2}))
  (assert-true (coll? (range 10)))
  (assert-false (coll? "abc"))
  (assert-false (coll? 1)))

(defn test-butlast []
  "NATIVE: testing butlast function"
  (assert-equal (list (butlast (range 10)))
                [0 1 2 3 4 5 6 7 8])
  (assert-equal (list (butlast [1]))
                [])
  (assert-equal (list (butlast []))
                [])
  ; with an infinite sequence
  (import itertools)
  (assert-equal (list (islice (butlast (itertools.count 10)) 5))
                [10 11 12 13 14]))

(defn test-dec []
  "NATIVE: testing the dec function"
  (assert-equal 0 (dec 1))
  (assert-equal -1 (dec 0))
  (assert-equal 0 (dec (dec 2)))
  (assert-requires-num dec))

(defn test-setv []
  "NATIVE: testing setv mutation"
  (setv x 1)
  (setv y 1)
  (assert-equal x y)
  (setv y 12)
  (setv x y)
  (assert-equal x 12)
  (assert-equal y 12)
  (setv y (fn [x] 9))
  (setv x y)
  (assert-equal (x y) 9)
  (assert-equal (y x) 9)
  (try (do (setv a.b 1) (assert False))
       (except [e [NameError]] (assert (in "name 'a' is not defined" (str e)))))
  (try (do (setv b.a (fn [x] x)) (assert False))
       (except [e [NameError]] (assert (in "name 'b' is not defined" (str e)))))
  (import itertools)
  (setv foopermutations (fn [x] (itertools.permutations x)))
  (setv p (set [(, 1 3 2) (, 3 2 1) (, 2 1 3) (, 3 1 2) (, 1 2 3) (, 2 3 1)]))
  (assert-equal (set (itertools.permutations [1 2 3])) p)
  (assert-equal (set (foopermutations [3 1 2])) p)
  (setv permutations- itertools.permutations)
  (setv itertools.permutations (fn [x] 9))
  (assert-equal (itertools.permutations p) 9)
  (assert-equal (foopermutations foopermutations) 9)
  (setv itertools.permutations permutations-)
  (assert-equal (set (itertools.permutations [2 1 3])) p)
  (assert-equal (set (foopermutations [2 3 1])) p))

(defn test-distinct []
  "NATIVE: testing the distinct function"
  (setv res (list (distinct [ 1 2 3 4 3 5 2 ])))
  (assert-equal res [1 2 3 4 5])
  ;; distinct of an empty list should be []
  (setv res (list (distinct [])))
  (assert-equal res [])
  ;; now with an iter
  (setv test_iter (iter [1 2 3 4 3 5 2]))
  (setv res (list (distinct test_iter)))
  (assert-equal res [1 2 3 4 5])
  ; make sure we can handle None in the list
  (setv res (list (distinct [1 2 3 2 5 None 3 4 None])))
  (assert-equal res [1 2 3 5 None 4]))

(defn test-drop-last []
  "NATIVE: testing drop-last function"
  (assert-equal (list (drop-last 5 (range 10 20)))
                [10 11 12 13 14])
  (assert-equal (list (drop-last 0 (range 5)))
                [0 1 2 3 4])
  (assert-equal (list (drop-last 100 (range 100)))
                [])
  ; with an infinite sequence
  (import itertools)
  (assert-equal (list (islice (drop-last 100 (itertools.count 10)) 5))
                [10 11 12 13 14]))

(defn test-empty? []
  "NATIVE: testing the empty? function"
  (assert-true (empty? ""))
  (assert-false (empty? "None"))
  (assert-true (empty? (,)))
  (assert-false (empty? (, None)))
  (assert-true (empty? []))
  (assert-false (empty? [None]))
  (assert-true (empty? {}))
  (assert-false (empty? {"a" None}))
  (assert-true (empty? (set)))
  (assert-false (empty? (set [None]))))

(defn test-even []
  "NATIVE: testing the even? function"
  (assert-true (even? -2))
  (assert-false (even? 1))
  (assert-true (even? 0))
  (assert-requires-num even?))

(defn test-every? []
  "NATIVE: testing the every? function"
  (assert-true (every? even? [2 4 6]))
  (assert-false (every? even? [1 3 5]))
  (assert-false (every? even? [2 4 5]))
  (assert-true (every? even? [])))

(setv globalvar 1)
(defn test-exec []
  (setv localvar 1)
  (setv code "
result['localvar in locals'] = 'localvar' in locals()
result['localvar in globals'] = 'localvar' in globals()
result['globalvar in locals'] = 'globalvar' in locals()
result['globalvar in globals'] = 'globalvar' in globals()
result['x in locals'] = 'x' in locals()
result['x in globals'] = 'x' in globals()
result['y in locals'] = 'y' in locals()
result['y in globals'] = 'y' in globals()")

  (setv result {})
  (exec code)
  (assert-true (get result "localvar in locals"))
  (assert-false (get result "localvar in globals"))
  (assert-false (get result "globalvar in locals"))
  (assert-true (get result "globalvar in globals"))
  (assert-false (or
    (get result "x in locals") (get result "x in globals")
    (get result "y in locals") (get result "y in globals")))

  (setv result {})
  (exec code {"x" 1 "result" result})
  (assert-false (or
    (get result "localvar in locals") (get result "localvar in globals")
    (get result "globalvar in locals") (get result "globalvar in globals")))
  (assert-true (and
    (get result "x in locals") (get result "x in globals")))
  (assert-false (or
    (get result "y in locals") (get result "y in globals")))

  (setv result {})
  (exec code {"x" 1 "result" result} {"y" 1})
  (assert-false (or
    (get result "localvar in locals") (get result "localvar in globals")
    (get result "globalvar in locals") (get result "globalvar in globals")))
  (assert-false (get result "x in locals"))
  (assert-true (get result "x in globals"))
  (assert-true (get result "y in locals"))
  (assert-false (get result "y in globals")))

(defn test-filter []
  "NATIVE: testing the filter function"
  (setv res (list (filter pos? [ 1 2 3 -4 5])))
  (assert-equal res [ 1 2 3 5 ])
  ;; test with iter
  (setv res (list (filter pos? (iter [ 1 2 3 -4 5 -6]))))
  (assert-equal res [ 1 2 3 5])
  (setv res (list (filter neg? [ -1 -4 5 3 4])))
  (assert-false (= res [1 2]))
  ;; test with empty list
  (setv res (list (filter neg? [])))
  (assert-equal res [])
  ;; test with None in the list
  (setv res (list (filter even? (filter numeric? [1 2 None 3 4 None 4 6]))))
  (assert-equal res [2 4 4 6])
  (setv res (list (filter none? [1 2 None 3 4 None 4 6])))
  (assert-equal res [None None]))

(defn test-flatten []
  "NATIVE: testing the flatten function"
  (setv res (flatten [1 2 [3 4] 5]))
  (assert-equal res [1 2 3 4 5])
  (setv res (flatten ["foo" (, 1 2) [1 [2 3] 4] "bar"]))
  (assert-equal res ["foo" 1 2 1 2 3 4 "bar"])
  (setv res (flatten [1]))
  (assert-equal res [1])
  (setv res (flatten []))
  (assert-equal res [])
  (setv res (flatten (, 1)))
  (assert-equal res [1])
  ;; test with None
  (setv res (flatten (, 1 (, None 3))))
  (assert-equal res [1 None 3])
  (try (flatten "foo")
       (except [e [TypeError]] (assert (in "not a collection" (str e)))))
  (try (flatten 12.34)
       (except [e [TypeError]] (assert (in "not a collection" (str e))))))

(defn test-float? []
  "NATIVE: testing the float? function"
  (assert-true (float? 4.2))
  (assert-false (float? 0))
  (assert-false (float? -3))
  (assert-true (float? -3.2))
  (assert-false (float? "foo")))

(defn test-symbol? []
  "NATIVE: testing the symbol? function"
  (assert-false (symbol? "hello"))
  (assert-false (symbol? [1 2 3]))
  (assert-false (symbol? '[a b c]))
  (assert-true (symbol? 'im-symbol)))

(defn test-list? []
  "NATIVE: testing the list? function"
  (assert-false (list? "hello"))
  (assert-true (list? [1 2 3])))

(defn test-tuple? []
  "NATIVE: testing the tuple? function"
  (assert-false (tuple? [4 5]))
  (assert-true (tuple? (, 4 5))))

(defn test-gensym []
  "NATIVE: testing the gensym function"
  (setv s1 (hy.gensym))
  (assert (isinstance s1 hy.models.Symbol))
  (assert (= 0 (.find s1 "_G\uffff")))
  (setv s2 (hy.gensym "xx"))
  (setv s3 (hy.gensym "xx"))
  (assert (= 0 (.find s2 "_xx\uffff")))
  (assert (not (= s2 s3)))
  (assert (not (= (str s2) (str s3)))))

(defn test-inc []
  "NATIVE: testing the inc function"
  (assert-equal 3 (inc 2))
  (assert-equal 0 (inc -1))
  (assert-requires-num inc)

  (defclass X [object]
    (defn __add__ [self other] (.format "__add__ got {}" other)))
  (assert-equal (inc (X)) "__add__ got 1"))

(defn test-integer? []
  "NATIVE: testing the integer? function"
  (assert-true (integer? 0))
  (assert-true (integer? 3))
  (assert-true (integer? -3))
  (assert-true (integer? (int "-3")))
  (assert-true (integer? (int 3)))
  (assert-false (integer? 4.2))
  (assert-false (integer? None))
  (assert-false (integer? "foo")))

(defn test-integer-char? []
  "NATIVE: testing the integer-char? function"
  (assert-true (integer-char? "1"))
  (assert-true (integer-char? "-1"))
  (assert-true (integer-char? (str (int 300))))
  (assert-false (integer-char? "foo"))
  (assert-false (integer-char? None)))

(defn test-iterable []
  "NATIVE: testing iterable? function"
  ;; should work for a string
  (setv s (str "abcde"))
  (assert-true (iterable? s))
  ;; should work for unicode
  (setv u "hello")
  (assert-true (iterable? u))
  (assert-true (iterable? (iter u)))
  ;; should work for a list
  (setv l [1 2 3 4])
  (assert-true (iterable? l))
  (assert-true (iterable? (iter l)))
  ;; should work for a dict
  (setv d {:a 1 :b 2 :c 3})
  (assert-true (iterable? d))
  ;; should work for a tuple?
  (setv t (, 1 2 3 4))
  (assert-true (iterable? t))
  ;; should work for a generator
  (assert-true (iterable? (repeat 3)))
  ;; shouldn't work for an int
  (assert-false (iterable? 5)))

(defn test-iterator []
  "NATIVE: testing iterator? function"
  ;; should not work for a list
  (setv l [1 2 3 4])
  (assert-false (iterator? l))
  ;; should work for an iter over a list
  (setv i (iter [1 2 3 4]))
  (assert-true (iterator? i))
  ;; should not work for a dict
  (setv d {:a 1 :b 2 :c 3})
  (assert-false (iterator? d))
  ;; should not work for a tuple?
  (setv t (, 1 2 3 4))
  (assert-false (iterator? t))
  ;; should work for a generator
  (assert-true (iterator? (repeat 3)))
  ;; should not work for an int
  (assert-false (iterator? 5)))

(defn test-neg []
  "NATIVE: testing the neg? function"
  (assert-true (neg? -2))
  (assert-false (neg? 1))
  (assert-false (neg? 0))
  (assert-requires-num neg?))

(defn test-zero []
  "NATIVE: testing the zero? function"
  (assert-false (zero? -2))
  (assert-false (zero? 1))
  (assert-true (zero? 0)))

(defn test-none []
  "NATIVE: testing for `is None`"
  (assert-true (none? None))
  (setv f None)
  (assert-true (none? f))
  (assert-false (none? 0))
  (assert-false (none? "")))

(defn test-numeric? []
  "NATIVE: testing the numeric? function"
  (assert-true (numeric? 1))
  (assert-true (numeric? 3.4))
  (assert-true (numeric? 0.0))
  (assert-true (numeric? -1.45))
  (assert-false (numeric? "Foo"))
  (assert-false (numeric? None)))

(defn test-odd []
  "NATIVE: testing the odd? function"
  (assert-true (odd? -3))
  (assert-true (odd? 1))
  (assert-false (odd? 0))
  (assert-requires-num odd?))

(defn test-parse-args []
  "NATIVE: testing the parse-args function"
  ; https://github.com/hylang/hy/issues/1875
  (setv parsed-args (parse-args [["strings" :nargs "+" :help "Strings"]
                                 ["-n" :action "append" :type int :help "Numbers" "--numbers"]]
                                ["a" "b" "-n" "1" "--numbers" "2"]
                                :description "Parse strings and numbers from args"))
  (assert-equal parsed-args.strings ["a" "b"])
  (assert-equal parsed-args.numbers [1 2]))

(defn test-pos []
  "NATIVE: testing the pos? function"
  (assert-true (pos? 2))
  (assert-false (pos? -1))
  (assert-false (pos? 0))
  (assert-requires-num pos?))

(defn test-some []
  "NATIVE: testing the some function"
  (assert-true (some even? [2 4 6]))
  (assert-none (some even? [1 3 5]))
  (assert-true (some even? [1 2 3]))
  (assert-none (some even? []))
  ; 0, "" (empty string) and [] (empty list) are all logical false
  (assert-none (some (fn [x] x) [0 "" []]))
  ; non-empty string is logical true
  (assert-equal (some (fn [x] x) [0 "this string is non-empty" []])
                "this string is non-empty")
  ; None if collection is empty
  (assert-none (some even? [])))

(defn test-string? []
  "NATIVE: testing string?"
  (assert-true (string? "foo"))
  (assert-true (string? ""))
  (assert-false (string? 5.3))
  (assert-true (string? (str 5.3)))
  (assert-false (string? None)))

(defn test-doto []
  "NATIVE: testing doto macro"
  (setv collection [])
  (doto collection (.append 1) (.append 2) (.append 3))
  (assert-equal collection [1 2 3])
  (setv res (doto (set) (.add 2) (.add 1)))
  (assert-equal res (set [1 2]))
  (setv res (doto [] (.append 1) (.append 2) .reverse))
  (assert-equal res [2 1]))

(defn test-is-keyword []
  "NATIVE: testing the keyword? function"
  (assert (keyword? ':bar))
  (assert (keyword? ':baz))
  (setv x :bar)
  (assert (keyword? x))
  (assert (not (keyword? "foo")))
  (assert (not (keyword? ":foo")))
  (assert (not (keyword? 1)))
  (assert (not (keyword? None))))

(defn test-import-init-hy []
  "NATIVE: testing import of __init__.hy"
  (import tests.resources.bin)
  (assert (in "_null_fn_for_import_test" (dir tests.resources.bin))))

(defn test-constantly []
  "NATIVE: test constantly"
  (setv helper (constantly 42))

  (assert-true (= (helper) 42))
  (assert-true (= (helper 1 2 3) 42))
  (assert-true (= (helper 1 2 :foo 3) 42)))

(defn test-comment []
  (assert-none (comment <h1>This is merely a comment.</h1>
                        <p> Move along. (Nothing to see here.)</p>)))

(defn test-doc [capsys]
  ;; https://github.com/hylang/hy/issues/1970
  ;; Let's first make sure we can doc the builtin macros
  ;; before we create the user macros.
  (doc doc)
  (setv [out err] (.readouterr capsys))
  (assert (in "Gets help for a macro function" out))

  (doc "#@")
  (setv [out err] (.readouterr capsys))
  (assert (in "with-decorator tag macro" out))

  (defmacro <-mangle-> []
    "a fancy docstring"
    '(+ 2 2))
  (doc <-mangle->)
  (setv [out err] (.readouterr capsys))
  ;; https://github.com/hylang/hy/issues/1946
  (assert (.startswith (.strip out)
            f"Help on function {(hy.mangle '<-mangle->)} in module "))
  (assert (in "a fancy docstring" out))
  (assert (empty? err))

  (defmacro "#pillgrums" [x]
    "Look at the quality of that picture!"
    x)
  (doc "#pillgrums")
  (setv [out err] (.readouterr capsys))
  (assert (in "Look at the quality of that picture!" out))
  (assert (empty? err))

  ;; make sure doc raises an error instead of
  ;; presenting a default value help screen
  (with [(pytest.raises NameError)]
    (doc does-not-exist)))


(defn test-do-n []
  (setv n 0)

  (do-n 1 (+= n 1))
  (assert (= n 1))
  (do-n 3 (+= n 1))
  (assert (= n 4))
  (do-n 0 (+= n 1))
  (assert (= n 4))
  (do-n -2 (+= n 1))
  (assert (= n 4))

  (do-n 2 (+= n 1) (+= n 2))
  (assert (= n 10))

  (do-n 2 (+= n 1) (+= n 2) (break))
  (assert (= n 13)))


(defn test-list-n []

  (assert (= (list-n 4 1) [1 1 1 1]))

  (setv l (list (range 10)))
  (assert (= (list-n 3 (.pop l)) [9 8 7])))

(defn test-cfor []
  (assert (= (cfor tuple x (range 10) :if (odd? x) x) (, 1 3 5 7 9)))
  (assert (= (cfor all x [1 3 8 5] (< x 10))) True)
  (assert (= (cfor dict x "ABCD" [x True])
             {"A" True  "B" True  "C" True  "D" True})))

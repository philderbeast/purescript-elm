## Module Elm.Default

This module re-exports the things which Elm imports by default.

So, if you want the Elm default imports, you can do

`import Elm.Default`


### Re-exported from Data.Maybe:

#### `Maybe`

``` purescript
data Maybe a
  = Just a
  | Nothing
```

The `Maybe` type is used to represent optional values and can be seen as
something like a type-safe `null`, where `Nothing` is `null` and `Just x`
is the non-null value `x`.

##### Instances
``` purescript
Functor Maybe
Apply Maybe
Applicative Maybe
Alt Maybe
Plus Maybe
Alternative Maybe
Bind Maybe
Monad Maybe
MonadZero Maybe
Extend Maybe
Invariant Maybe
(Semigroup a) => Semigroup (Maybe a)
(Semigroup a) => Monoid (Maybe a)
(Eq a) => Eq (Maybe a)
(Ord a) => Ord (Maybe a)
(Bounded a) => Bounded (Maybe a)
(Show a) => Show (Maybe a)
```

### Re-exported from Elm.Basics:

#### `Tuple`

``` purescript
data Tuple a b
  = Tuple a b
```

A simple product type for wrapping a pair of component values.

##### Instances
``` purescript
(Show a, Show b) => Show (Tuple a b)
(Eq a, Eq b) => Eq (Tuple a b)
(Ord a, Ord b) => Ord (Tuple a b)
(Bounded a, Bounded b) => Bounded (Tuple a b)
Semigroupoid Tuple
(Semigroup a, Semigroup b) => Semigroup (Tuple a b)
(Monoid a, Monoid b) => Monoid (Tuple a b)
(Semiring a, Semiring b) => Semiring (Tuple a b)
(Ring a, Ring b) => Ring (Tuple a b)
(CommutativeRing a, CommutativeRing b) => CommutativeRing (Tuple a b)
(HeytingAlgebra a, HeytingAlgebra b) => HeytingAlgebra (Tuple a b)
(BooleanAlgebra a, BooleanAlgebra b) => BooleanAlgebra (Tuple a b)
Functor (Tuple a)
Invariant (Tuple a)
Bifunctor Tuple
(Semigroup a) => Apply (Tuple a)
Biapply Tuple
(Monoid a) => Applicative (Tuple a)
Biapplicative Tuple
(Semigroup a) => Bind (Tuple a)
(Monoid a) => Monad (Tuple a)
Extend (Tuple a)
Comonad (Tuple a)
(Lazy a, Lazy b) => Lazy (Tuple a b)
Foldable (Tuple a)
Bifoldable Tuple
Traversable (Tuple a)
Bitraversable Tuple
```

#### `Order`

``` purescript
type Order = Ordering
```

Represents the relative ordering of two things.
The relations are less than, equal to, and greater than.

Equivalent to Purescript's `Ordering`.

#### `Float`

``` purescript
type Float = Number
```

The Purescript equivalent of Elm's `Float` is `Number`.

#### `Bool`

``` purescript
type Bool = Boolean
```

The Purescript equivalent of Elm's `Bool` is `Boolean`.

#### `Pow`

``` purescript
class Pow a where
  pow :: a -> a -> a
```

A class for things that can be raised to a power.

##### Instances
``` purescript
Pow Int
Pow Number
```

#### `xor`

``` purescript
xor :: forall a. BooleanAlgebra a => a -> a -> a
```

The exclusive-or operator. `true` if exactly one input is `true`.

#### `uncurry`

``` purescript
uncurry :: forall a b c. (a -> b -> c) -> Tuple a b -> c
```

Turn a function of two arguments into a function that expects a tuple.

#### `turns`

``` purescript
turns :: Float -> Float
```

Convert turns to standard Elm angles (radians).
One turn is equal to 360&deg;.

#### `truncate`

``` purescript
truncate :: Float -> Int
```

Truncate a number, rounding towards zero.

#### `toString`

``` purescript
toString :: forall a. Show a => a -> String
```

Turn any kind of value into a string.

    toString 42 == "42"
    toString [1,2] == "[1,2]"
    toString "he said, \"hi\"" == "\"he said, \\\"hi\\\"\""

Equivalent to Purescript's `show`.

#### `toPolar`

``` purescript
toPolar :: Tuple Float Float -> Tuple Float Float
```

Convert Cartesian coordinates `Tuple x y` to polar coordinates `Tuple r theta`.

*Note that it would normally be better to use a record type here, rather than
tuples. However, it seems best to match the Elm API as closely as possible.*

*If you want some more sophisticated handling of complex numbers, see
[purescript-complex](http://pursuit.purescript.org/packages/purescript-complex).*

#### `toFloat`

``` purescript
toFloat :: Int -> Float
```

Convert an integer into a float.

Equivalent to Purescript's `toNumber`.

#### `tan`

``` purescript
tan :: Radians -> Number
```

Returns the tangent of the argument.

#### `sqrt`

``` purescript
sqrt :: Number -> Number
```

Returns the square root of the argument.

#### `snd`

``` purescript
snd :: forall a b. Tuple a b -> b
```

Returns the second component of a tuple.

#### `sin`

``` purescript
sin :: Radians -> Number
```

Returns the sine of the argument.

#### `round`

``` purescript
round :: Number -> Int
```

Convert a `Number` to an `Int`, by taking the nearest integer to the
argument. Values outside the `Int` range are clamped.

#### `rem`

``` purescript
rem :: forall a. EuclideanRing a => a -> a -> a
```

Find the remainder after dividing one number by another.

    7 `rem` 2 == 1
    -1 `rem` 4 == -1

Equivalent to Purescript's `Prelude.mod`.

#### `radians`

``` purescript
radians :: Float -> Float
```

Convert radians to standard Elm angles (radians).

#### `pi`

``` purescript
pi :: Number
```

The ratio of the circumference of a circle to its diameter, around 3.14159.

#### `not`

``` purescript
not :: forall a. HeytingAlgebra a => a -> a
```

#### `negate`

``` purescript
negate :: forall a. Ring a => a -> a
```

`negate x` can be used as a shorthand for `zero - x`.

#### `mod`

``` purescript
mod :: forall a. (Ord a, EuclideanRing a) => a -> a -> a
```

Perform [modular arithmetic](http://en.wikipedia.org/wiki/Modular_arithmetic).

       7 % 2 == 1
    (-1) % 4 == 3

Note that this is not the same as Purescript's `Prelude.mod` --
for that, see `Basics.rem`.

#### `min`

``` purescript
min :: forall a. Ord a => a -> a -> a
```

Take the minimum of two values. If they are considered equal, the first
argument is chosen.

#### `max`

``` purescript
max :: forall a. Ord a => a -> a -> a
```

Take the maximum of two values. If they are considered equal, the first
argument is chosen.

#### `logBase`

``` purescript
logBase :: Float -> Float -> Float
```

Calculate the logarithm of a number with a given base.

    logBase 10.0 100.0 == 2.0
    logBase 2.0 256.0 == 8.0

#### `isNaN`

``` purescript
isNaN :: Number -> Boolean
```

Test whether a number is NaN

#### `isInfinite`

``` purescript
isInfinite :: Float -> Bool
```

Determine whether a float is positive or negative infinity.

    isInfinite (0.0 / 0.0)   == false
    isInfinite (sqrt (-1.0)) == false
    isInfinite (1.0 / 0.0)   == true
    isInfinite 1.0           == false

Notice that NaN is not infinite! For float `n` to be finite implies that
`not (isInfinite n || isNaN n)` evaluates to `true`.

Note that this is not equivalent to the negation of Javascript's `isFinite()`.

#### `intDiv`

``` purescript
intDiv :: forall a. EuclideanRing a => a -> a -> a
```

Integer division. The remainder is discarded.

In Purescript, you can simply use `/`.

#### `identity`

``` purescript
identity :: forall a. a -> a
```

Given a value, returns exactly the same value. This is called
[the identity function](http://en.wikipedia.org/wiki/Identity_function).

The Purescript equivalent is `id`.

#### `fst`

``` purescript
fst :: forall a b. Tuple a b -> a
```

Returns the first component of a tuple.

#### `fromPolar`

``` purescript
fromPolar :: Tuple Float Float -> Tuple Float Float
```

Convert polar coordinates `Tuple r theta` to Cartesian coordinates `Tuple x y`.

*Note that it would normally be better to use a record type here, rather than
tuples. However, it seems best to match the Elm API as closely as possible.*

*If you want some more sophisticated handling of complex numbers, see
[purescript-complex](http://pursuit.purescript.org/packages/purescript-complex).*

#### `floor`

``` purescript
floor :: Number -> Int
```

Convert a `Number` to an `Int`, by taking the closest integer equal to or
less than the argument. Values outside the `Int` range are clamped.

#### `flip`

``` purescript
flip :: forall a b c. (a -> b -> c) -> b -> a -> c
```

Flips the order of the arguments to a function of two arguments.

```purescript
flip const 1 2 = const 2 1 = 2
```

#### `e`

``` purescript
e :: Number
```

The base of natural logarithms, *e*, around 2.71828.

#### `degrees`

``` purescript
degrees :: Float -> Float
```

Convert degrees to standard Elm angles (radians).

#### `curry`

``` purescript
curry :: forall a b c. (Tuple a b -> c) -> a -> b -> c
```

Turn a function that expects a tuple into a function of two arguments.

#### `cos`

``` purescript
cos :: Radians -> Number
```

Returns the cosine of the argument.

#### `composeFlipped`

``` purescript
composeFlipped :: forall a b c. (a -> b) -> (b -> c) -> (a -> c)
```

Function composition, passing results along in the suggested direction. For
example, the following code checks if the square root of a number is odd:

    sqrt >> isEven >> not

This direction of function composition seems less pleasant than `(<<)` which
reads nicely in expressions like: `filter (not << isRegistered) students`

Equivalent to Purescript's `>>>`.

#### `compose`

``` purescript
compose :: forall a b c. (b -> c) -> (a -> b) -> (a -> c)
```

Function composition, passing results along in the suggested direction. For
example, the following code checks if the square root of a number is odd:

    not << isEven << sqrt

You can think of this operator as equivalent to the following:

    (g << f)  ==  (\x -> g (f x))

So our example expands out to something like this:

    \n -> not (isEven (sqrt n))

Equivalent to Purescript's `<<<`.

#### `compare`

``` purescript
compare :: forall a. Ord a => a -> a -> Ordering
```

#### `clamp`

``` purescript
clamp :: forall a. Ord a => a -> a -> a -> a
```

Clamp a value between a minimum and a maximum. For example:

``` purescript
let f = clamp 0 10
f (-5) == 0
f 5    == 5
f 15   == 10
```

#### `ceiling`

``` purescript
ceiling :: Float -> Int
```

Ceiling function, rounding up.

Equivalent to Purescript's `ceil`.

#### `atan2`

``` purescript
atan2 :: Number -> Number -> Radians
```

Four-quadrant tangent inverse. Given the arguments `y` and `x`, returns
the inverse tangent of `y / x`, where the signs of both arguments are used
to determine the sign of the result.
If the first argument is negative, the result will be negative.
The result is the angle between the positive x axis and  a point `(x, y)`.

#### `atan`

``` purescript
atan :: Number -> Radians
```

Returns the inverse tangent of the argument.

#### `asin`

``` purescript
asin :: Number -> Radians
```

Returns the inverse sine of the argument.

#### `applyFnFlipped`

``` purescript
applyFnFlipped :: forall a b. a -> (a -> b) -> b
```

Forward function application `x |> f == f x`. This function is useful
for avoiding parentheses and writing code in a more natural way.
Consider the following code to create a pentagon:

    scale 2 (move (10,10) (filled blue (ngon 5 30)))

This can also be written as:

    ngon 5 30
      |> filled blue
      |> move (10,10)
      |> scale 2

Equivalent to Purescript's `#`.

#### `applyFn`

``` purescript
applyFn :: forall a b. (a -> b) -> a -> b
```

Backward function application `f <| x == f x`. This function is useful for
avoiding parentheses. Consider the following code to create a text element:

    leftAligned (monospace (fromString "code"))

This can also be written as:

    leftAligned <| monospace <| fromString "code"

Equivalent to Purescript's `$`.

#### `always`

``` purescript
always :: forall a b. a -> b -> a
```

Create a [constant function](http://en.wikipedia.org/wiki/Constant_function),
a function that *always* returns the same value regardless of what input you give.
It is defined as:

    always a b = a

It totally ignores the second argument, so `always 42` is a function that always
returns 42. When you are dealing with higher-order functions, this comes in
handy more often than you might expect. For example, creating a zeroed out list
of length ten would be:

    map (always 0) [0..9]

The Purescript equivalent is `const`.

#### `acos`

``` purescript
acos :: Number -> Radians
```

Returns the inverse cosine of the argument.

#### `abs`

``` purescript
abs :: forall a. (Ring a, Ord a) => a -> a
```

Take the absolute value of a number.

#### `(||)`

``` purescript
infixr 2 Data.HeytingAlgebra.disj as ||
```

#### `(|>)`

``` purescript
infixl 0 applyFnFlipped as |>
```

#### `(^)`

``` purescript
infixr 8 pow as ^
```

#### `(>>)`

``` purescript
infixl 9 composeFlipped as >>
```

#### `(>=)`

``` purescript
infixl 4 Data.Ord.greaterThanOrEq as >=
```

#### `(>)`

``` purescript
infixl 4 Data.Ord.greaterThan as >
```

#### `(==)`

``` purescript
infix 4 Data.Eq.eq as ==
```

#### `(<|)`

``` purescript
infixr 0 applyFn as <|
```

#### `(<=)`

``` purescript
infixl 4 Data.Ord.lessThanOrEq as <=
```

#### `(<<)`

``` purescript
infixr 9 compose as <<
```

#### `(<)`

``` purescript
infixl 4 Data.Ord.lessThan as <
```

#### `(/=)`

``` purescript
infix 4 Data.Eq.notEq as /=
```

#### `(//)`

``` purescript
infixl 7 intDiv as //
```

#### `(/)`

``` purescript
infixl 7 Data.EuclideanRing.div as /
```

#### `(-)`

``` purescript
infixl 6 Data.Ring.sub as -
```

#### `(++)`

``` purescript
infixl 5 Data.Semigroup.append as ++
```

#### `(+)`

``` purescript
infixl 6 Data.Semiring.add as +
```

#### `(*)`

``` purescript
infixl 7 Data.Semiring.mul as *
```

#### `(&&)`

``` purescript
infixr 3 Data.HeytingAlgebra.conj as &&
```

#### `(%)`

``` purescript
infixl 7 mod as %
```

### Re-exported from Elm.Debug:

#### `log`

``` purescript
log :: forall a. String -> a -> a
```

Log a tagged value on the developer console, and then return the value.

    1 + log "number" 1        -- equals 2, logs "number: 1"
    length (log "start" [])   -- equals 0, logs "start: []"

Notice that `log` is not a pure function! It should *only* be used for
investigating bugs or performance problems.

#### `crash`

``` purescript
crash :: forall a. String -> a
```

Crash the program with an error message.

Equivalent to Purescript's `Partial.Unsafe.unsafeCrashWith`

### Re-exported from Elm.List:

#### `List`

``` purescript
data List a
```

A strict linked list.

A list is either empty (represented by the `Nil` constructor) or non-empty, in
which case it consists of a head element, and another list (represented by the
`Cons` constructor).

##### Instances
``` purescript
(Generic a) => Generic (List a)
(Show a) => Show (List a)
(Eq a) => Eq (List a)
(Ord a) => Ord (List a)
Semigroup (List a)
Monoid (List a)
Functor List
Foldable List
Unfoldable List
Traversable List
Apply List
Applicative List
Bind List
Monad List
Alt List
Plus List
Alternative List
MonadZero List
MonadPlus List
```

#### `(:)`

``` purescript
infixr 5 cons as :
```

### Re-exported from Elm.Result:

#### `Result`

``` purescript
data Result error value
  = Ok value
  | Err error
```

A `Result` is either `Ok` meaning the computation succeeded, or it is an
`Err` meaning that there was some failure.

##### Instances
``` purescript
Functor (Result a)
Bifunctor Result
Apply (Result e)
Applicative (Result e)
Alt (Result e)
Bind (Result e)
Monad (Result e)
Extend (Result e)
(Show a, Show b) => Show (Result a b)
(Eq a, Eq b) => Eq (Result a b)
(Ord a, Ord b) => Ord (Result a b)
(Bounded a, Bounded b) => Bounded (Result a b)
Foldable (Result a)
Bifoldable Result
Traversable (Result a)
Bitraversable Result
(Semiring b) => Semiring (Result a b)
(Semigroup b) => Semigroup (Result a b)
```

### Re-exported from Elm.Signal:

#### `Signal`

``` purescript
newtype Signal a
```

A value that changes over time. So a `(Signal Int)` is an integer that is
varying as time passes, perhaps representing the current window width of the
browser. Every signal is updated at discrete moments in response to events in
the world.


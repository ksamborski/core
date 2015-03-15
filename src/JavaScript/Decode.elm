module JavaScript.Decode where
{-| A way to turn JavaScript values into Elm values.

# Run a Decoder
@docs decodeString, decodeValue

# Primitives
@docs string, int, float, bool, null

# Arrays
@docs list, array,
  tuple1, tuple2, tuple3, tuple4, tuple5, tuple6, tuple7, tuple8

# Objects
@docs (:=), at,
  object1, object2, object3, object4, object5, object6, object7, object8,
  keyValuePairs, dict

# Oddly Shaped Values
@docs maybe, oneOf, map, fail, succeed, andThen

# "Creative" Values
@docs value, customDecoder
-}


import Native.JavaScript
import Array exposing (Array)
import Dict exposing (Dict)
import JavaScript.Encode as JsEncode
import List
import Maybe exposing (Maybe)
import Result exposing (Result)


type Decoder a = Decoder

type alias Value = JsEncode.Value


{-| Transform the value returned by a decoder. Most useful when paired with
the `oneOf` function.

    nullOr : Decoder a -> Decoder (Maybe a)
    nullOr decoder =
        oneOf
          [ null Nothing
          , map Just decoder
          ]

    type UserID = OldID Int | NewID String

    -- 1234 or "1234abc"
    userID : Decoder UserID
    userID =
        oneOf
          [ map OldID int
          , map NewID string
          ]
-}
map : (a -> b) -> Decoder a -> Decoder b
map =
    Native.JavaScript.decodeObject1


decodeString : Decoder a -> String -> Result String a
decodeString =
    Native.JavaScript.runDecoderString


-- OBJECTS

{-| Access a nested field, making it easy to dive into big structures. This is
really a helper function so you do not need to write `(:=)` so many times.

    -- object.target.value = 'hello'

    value : Decoder String
    value =
        at ["target", "value"] string

    at fields decoder =
        List.foldr (:=) decoder fields
-}
at : List String -> Decoder a -> Decoder a
at fields decoder =
    List.foldr (:=) decoder fields


{-| Decode an object if it has a certain field.

    nameAndAge : Decoder (String,Int)
    nameAndAge =
        object2 (,)
          ("name" := string)
          ("age" := int)

    optionalProfession : Decoder (Maybe String)
    optionalProfession =
        maybe ("profession" := string)
-}
(:=) : String -> Decoder a -> Decoder a
(:=) =
    Native.JavaScript.decodeField


object1 : (a -> value) -> Decoder a -> Decoder value
object1 =
    Native.JavaScript.decodeObject1


{-| Use two different decoders on a JS value. This is nice for extracting
multiple fields from an object.

    point : Decoder (Float,Float)
    point =
        object2 (,)
          ("x" := float)
          ("y" := float)
-}
object2 : (a -> b -> value) -> Decoder a -> Decoder b -> Decoder value
object2 =
    Native.JavaScript.decodeObject2


{-| Use two different decoders on a JS value. This is nice for extracting
multiple fields from an object.

    type alias Task = { task : String, id : Int, completed : Bool }

    point : Decoder Task
    point =
        object3 Task
          ("task" := string)
          ("id" := int)
          ("completed" := bool)
-}
object3 : (a -> b -> c -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder value
object3 =
    Native.JavaScript.decodeObject3


object4 : (a -> b -> c -> d -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder d -> Decoder value
object4 =
    Native.JavaScript.decodeObject4


object5 : (a -> b -> c -> d -> e -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder d -> Decoder e -> Decoder value
object5 =
    Native.JavaScript.decodeObject5


object6 : (a -> b -> c -> d -> e -> f -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder d -> Decoder e -> Decoder f -> Decoder value
object6 =
    Native.JavaScript.decodeObject6


object7 : (a -> b -> c -> d -> e -> f -> g -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder d -> Decoder e -> Decoder f -> Decoder g -> Decoder value
object7 =
    Native.JavaScript.decodeObject7


object8 : (a -> b -> c -> d -> e -> f -> g -> h -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder d -> Decoder e -> Decoder f -> Decoder g -> Decoder h -> Decoder value
object8 =
    Native.JavaScript.decodeObject8


{-| Turn any object into a list of key-value pairs.

    -- { tom: 89, sue: 92, bill: 97, ... }
    grades : Decoder (List (String, Int))
    grades =
        keyValuePairs int
-}
keyValuePairs : Decoder a -> Decoder (List (String, a))
keyValuePairs =
    Native.JavaScript.decodeKeyValuePairs


{-| Turn any object into a dictionary of key-value pairs.

    -- { mercury: 0.33, venus: 4.87, earth: 5.97, ... }
    planetMasses : Decoder (Dict String Int)
    planetMasses =
        dict float
-}
dict : Decoder a -> Decoder (Dict String a)
dict decoder =
    map Dict.fromList (keyValuePairs decoder)



{-| Try out a couple different decoders. This is helpful when you are dealing
with something with a very strange shape and when `andThen` does not help
narrow things down so you can be more targeted.

    -- [ [3,4], { x:0, y:0 }, [5,12] ]

    points : Decoder (List (Float,Float))
    points =
        list point

    point : (Float,Float)
    point =
        oneOf
        [ tuple2 (,) float float
        , object2 (,) ("x" := float) ("y" := float)
        ]
-}
oneOf : List (Decoder a) -> Decoder a
oneOf =
    Native.JavaScript.oneOf


{-| Extract a string.

    -- ["John","Doe"]

    name : Decoder (String, String)
    name =
        tuple2 (,) string string
-}
string : Decoder String
string =
    Native.JavaScript.decodeString


{-| Extract a float.

    -- [ 6.022, 3.1415, 1.618 ]

    numbers : Decoder (List Float)
    numbers =
        list float
-}
float : Decoder Float
float =
    Native.JavaScript.decodeFloat


{-| Extract an integer.

    -- { ... age: 42 ... }

    age : Decoder Int
    age =
        "age" := int
-}
int : Decoder Int
int =
    Native.JavaScript.decodeInt


{-| Extract a boolean.

    -- { ... checked: true ... }

    checked : Decoder Bool
    checked =
        "checked" := true
-}
bool : Decoder Bool
bool =
    Native.JavaScript.decodeBool


{-| Extract a list from a JS array.

    -- [1,2,3,4]

    numbers : Decoder [Int]
    numbers =
        list int
-}
list : Decoder a -> Decoder (List a)
list =
    Native.JavaScript.decodeList


{-| Extract an Array from a JS array.

    -- [1,2,3,4]

    numbers : Decoder (Array Int)
    numbers =
        array int
-}
array : Decoder a -> Decoder (Array a)
array =
    Native.JavaScript.decodeArray


{-| Extract a null value. Primarily useful for creating *other* decoders.

    nullOr : Decoder a -> Decoder (Maybe a)
    nullOr decoder =
        oneOf
        [ null Nothing
        , map Just decoder
        ]


    numbers : Decoder [Int]
    numbers =
        list (oneOf [ int, null 0 ])
-}
null : a -> Decoder a
null =
    Native.JavaScript.decodeNull


{-| Great for handling optional fields. The following code decodes JSON
objects that may not have a profession field.

    -- { name: "Tom", age: 31, profession: "plumber" }
    -- { name: "Sue", age: 42 }

    type alias Person =
        { name : String
        , age : Int
        , profession : Maybe String
        }

    person : Decoder Person
    person =
        object3 Person
          ("name" := string)
          ("age" := int)
          (maybe ("profession" := string))
-}
maybe : Decoder a -> Decoder (Maybe a)
maybe =
    Native.JavaScript.decodeMaybe


{-| Bring in an arbitrary JSON value. Useful if you need to work with crazily
formatted data. For example, this lets you create a parser for "variadic" lists
where the first few types are different, followed by 0 or more of the same
type.

    variadic2 : (a -> b -> List c -> value) -> Decoder a -> Decoder b -> Decoder (List c) -> Decoder value
    variadic2 f a b cs =
        customDecoder (list value) \jsonList ->
            case jsonList of
              one :: two :: rest ->
                  Result.map3 f
                    (decodeValue a one)
                    (decodeValue b two)
                    (decodeValue cs rest)

              _ -> Result.Err "expecting at least two elements in the array"
-}
value : Decoder Value
value =
    Native.JavaScript.decodeValue


decodeValue : Decoder a -> Value -> Result String a
decodeValue =
    Native.JavaScript.runDecoderValue


customDecoder : Decoder a -> (a -> Result String b) -> Decoder b
customDecoder =
    Native.JavaScript.customDecoder


{-| Helpful when one field will determine the shape of a bunch of other fields.

    type Shape
        = Rectangle Float Float
        | Circle Float

    shape : Decoder Shape
    shape =
      ("tag" := string) `andThen` shapeInfo

    shapeInfo : String -> Decoder Shape
    shapeInfo tag =
      case tag of
        "rectangle" ->
            object2 Rectangle
              ("width" := float)
              ("height" := float)

        "circle" ->
            object1 Circle
              ("radius" := float)

        _ ->
            fail (tag ++ " is not a recognized tag for shapes")
-}
andThen : Decoder a -> (a -> Decoder b) -> Decoder b
andThen =
    Native.JavaScript.andThen


{-| A decoder that always fails. Useful when paired with `andThen` or `oneOf`
to improve error messages when things go wrong. For example, the following
decoder is able to provide a much more specific error message when `fail` is
the last option.

    point : (Float,Float)
    point =
        oneOf
        [ tuple2 (,) float float
        , object2 (,) ("x" := float) ("y" := float)
        , fail "expecting some kind of point"
        ]
-}
fail : String -> Decoder a
fail =
    Native.JavaScript.fail


{-| A decoder that always succeeds. Useful when paired with `andThen` or
`oneOf` but everything is supposed to work out at the end. For example,
maybe you have an optional field that can have a default value when it is
missing.

    -- { x:3, y:4 } or { x:3, y:4, z:5 }

    point3D : Decoder (Float,Float,Float)
    point3D =
        object (,,)
          ("x" := float)
          ("y" := float)
          (oneOf [ "z" := float, succeed 0 ])
-}
succeed : a -> Decoder a
succeed =
    Native.JavaScript.succeed


-- TUPLES

tuple1 : (a -> value) -> Decoder a -> Decoder value
tuple1 =
    Native.JavaScript.decodeTuple1


{-| Handle an array with exactly two values. Useful for points and simple
pairs.

    -- [3,4] or [0,0]
    point : Decoder (Float,Float)
    point =
        tuple2 (,) float float

    -- ["John","Doe"] or ["Hermann","Hesse"]
    name : Decoder Name
    name =
        tuple2 Name string string

    type alias Name = { first : String, last : String }
-}
tuple2 : (a -> b -> value) -> Decoder a -> Decoder b -> Decoder value
tuple2 =
    Native.JavaScript.decodeTuple2


{-| Handle an array with exactly three values.

    -- [3,4,5] or [0,0,0]
    point3D : Decoder (Float,Float,Float)
    point3D =
        tuple3 (,,) float float float

-}
tuple3 : (a -> b -> c -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder value
tuple3 =
    Native.JavaScript.decodeTuple3


tuple4 : (a -> b -> c -> d -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder d -> Decoder value
tuple4 =
    Native.JavaScript.decodeTuple4


tuple5 : (a -> b -> c -> d -> e -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder d -> Decoder e -> Decoder value
tuple5 =
    Native.JavaScript.decodeTuple5


tuple6 : (a -> b -> c -> d -> e -> f -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder d -> Decoder e -> Decoder f -> Decoder value
tuple6 =
    Native.JavaScript.decodeTuple6


tuple7 : (a -> b -> c -> d -> e -> f -> g -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder d -> Decoder e -> Decoder f -> Decoder g -> Decoder value
tuple7 =
    Native.JavaScript.decodeTuple7


tuple8 : (a -> b -> c -> d -> e -> f -> g -> h -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder d -> Decoder e -> Decoder f -> Decoder g -> Decoder h -> Decoder value
tuple8 =
    Native.JavaScript.decodeTuple8
module Cache.Model exposing (..)

import Json.Decode exposing (..)


cacheDecoder : Decoder Cache
cacheDecoder =
    map5 Cache
        (field "id" int)
        (field "active" bool)
        (field "total" int)
        (field "processed" int)
        (field "status" <| oneOf [ null Nothing, map Just statusDecoder ])


logDecoder : Decoder Log
logDecoder =
    map Log
        (field "message" string)


statusDecoder : Decoder Status
statusDecoder =
    map2 Status
        (field "state" string)
        (field "text" string)


type alias Cache =
    { id : Int
    , active : Bool
    , total : Int
    , processed : Int
    , status : Maybe Status
    }


type alias Log =
    { message : String
    }


type alias Status =
    { state : String
    , text : String
    }

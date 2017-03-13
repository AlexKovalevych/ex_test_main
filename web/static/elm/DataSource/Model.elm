module DataSource.Model exposing (..)

import Json.Decode exposing (..)


dataSourceDecoder : Decoder DataSource
dataSourceDecoder =
    map5 DataSource
        (field "id" int)
        (field "active" bool)
        (field "total" int)
        (field "processed" int)
        (field "status" <| oneOf [ null Nothing, map Just statusDecoder ])


statusDecoder : Decoder Status
statusDecoder =
    map2 Status
        (field "state" string)
        (field "text" string)


logDecoder : Decoder Log
logDecoder =
    map Log
        (field "message" string)


type alias DataSource =
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

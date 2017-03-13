module PaymentCheck.Model exposing (..)

import Json.Decode exposing (..)


paymentCheckDecoder : Decoder PaymentCheck
paymentCheckDecoder =
    map5 PaymentCheck
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


type alias PaymentCheck =
    { id : Int
    , active : Bool
    , total : Int
    , processed : Int
    , status : Maybe Status
    }


type alias Status =
    { state : String
    , text : String
    }

module Permissions.Decoders exposing (..)

import Html exposing (Attribute)
import Permissions.Models exposing (..)
import Html.Events exposing (on)
import Json.Decode as JD


onClickInput : (LabelClickEvent -> msg) -> Attribute msg
onClickInput message =
    on "click"
        (JD.map message <|
            JD.map LabelClickEvent
                (JD.field "target" targetDecoder)
        )


targetDecoder : JD.Decoder EventTarget
targetDecoder =
    JD.map EventTarget
        (JD.field "tagName" JD.string)

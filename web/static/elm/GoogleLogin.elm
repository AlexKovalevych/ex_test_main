port module GoogleLogin exposing (..)

import Date
import Date.Extra.Format exposing (format, isoTimeFormat)
import Html exposing (Html, span, text)
import Time exposing (every, second)
import Date.Extra.Config.Config_en_au exposing (config)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    { timestamp = 0 } ! []


type Msg
    = Tick Float
    | SetTime Int


type alias Model =
    { timestamp : Int }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetTime time ->
            { model | timestamp = time } ! []

        Tick _ ->
            { model | timestamp = model.timestamp + 1000 } ! []


view : Model -> Html Msg
view model =
    span
        []
        [ text <| formattedTime model.timestamp ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ every second Tick
         , serverTime SetTime
         ]
        )


formattedTime : Int -> String
formattedTime time =
    format config isoTimeFormat (Date.fromTime <| toFloat time)


port serverTime : (Int -> msg) -> Sub msg

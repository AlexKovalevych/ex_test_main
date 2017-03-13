port module PaymentCheckEdit exposing (..)

import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import PaymentCheck.Model exposing (PaymentCheck, paymentCheckDecoder)
import Json.Encode as JE
import Json.Decode as JD
import Native.Location
import Native.Token
import Html.Attributes exposing (class, href, classList, name, type_, style, value, max)
import Html exposing (..)
import Round exposing (..)


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Flags =
    { paymentCheck : PaymentCheck
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        location =
            Native.Location.getLocation ()

        paymentCheckChannel =
            "payment_check:" ++ toString (flags.paymentCheck.id)

        socket =
            Phoenix.Socket.init ("ws://" ++ location.host ++ "/socket/websocket")
                |> Phoenix.Socket.on "payment_check:update" paymentCheckChannel DecodePaymentCheck

        token =
            Native.Token.getToken ()

        payload =
            JE.object [ ( "guardian_token", JE.string token ) ]

        channel =
            Phoenix.Channel.init paymentCheckChannel |> Phoenix.Channel.withPayload payload

        ( joinSocket, joinCmd ) =
            Phoenix.Socket.join channel socket

        push_ =
            Phoenix.Push.init "payment_check:update" paymentCheckChannel
                |> Phoenix.Push.onOk DecodePaymentCheck

        ( phxSocket, phxCmd ) =
            Phoenix.Socket.push push_ joinSocket

        _ =
            Debug.log "joined channel: " phxCmd
    in
        { paymentCheck = flags.paymentCheck
        , phxSocket = phxSocket
        }
            ! [ Cmd.batch ([ Cmd.map PhoenixMsg phxCmd, Cmd.map PhoenixMsg joinCmd ]) ]


type alias Model =
    { paymentCheck : PaymentCheck
    , phxSocket : Phoenix.Socket.Socket Msg
    }


type Msg
    = DecodePaymentCheck JD.Value
    | PhoenixMsg (Phoenix.Socket.Msg Msg)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DecodePaymentCheck raw ->
            case JD.decodeValue paymentCheckDecoder raw of
                Ok paymentCheck ->
                    let
                        cmd =
                            if model.paymentCheck.active /= paymentCheck.active then
                                [ reload True ]
                            else
                                []
                    in
                        { model | paymentCheck = paymentCheck } ! cmd

                Err error ->
                    model ! []

        PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )


view : Model -> Html Msg
view model =
    let
        progress =
            if model.paymentCheck.total >= 0 then
                renderProgress model
            else
                div [] []

        status =
            case model.paymentCheck.status of
                Nothing ->
                    div [] []

                Just status ->
                    if not model.paymentCheck.active then
                        p
                            [ class <| "text-" ++ status.state
                            , style [ ( "font-size", "12px" ) ]
                            , Html.Attributes.property "innerHTML" <| JE.string status.text
                            ]
                            []
                    else
                        div [] []
    in
        div [ class "col-sm-12 col-md-12 col-lg-8" ]
            [ div [ class "form-group row" ]
                [ div [ class "offset-sm-4 col-sm-8 offset-md-3 col-md-9 offset-lg-3 col-lg-9" ]
                    [ progress
                    , status
                    ]
                ]
            ]


renderProgress : Model -> Html Msg
renderProgress model =
    let
        percent =
            if model.paymentCheck.processed > 0 then
                Round.round 2 <| (toFloat (model.paymentCheck.processed) / toFloat (model.paymentCheck.total) * 100)
            else
                "0"
    in
        div []
            [ div [] [ text <| percent ++ "%" ]
            , progress
                [ class "progress"
                , value percent
                , Html.Attributes.max "100"
                ]
                [ text <| (percent ++ "%") ]
            ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.Socket.listen model.phxSocket PhoenixMsg


port reload : Bool -> Cmd msg

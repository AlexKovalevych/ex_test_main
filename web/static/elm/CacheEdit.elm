port module CacheEdit exposing (..)

import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Cache.Model exposing (Cache, cacheDecoder)
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
    { cache : Cache
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        location =
            Native.Location.getLocation ()

        cacheChannel =
            "cache:" ++ toString (flags.cache.id)

        socket =
            Phoenix.Socket.init ("ws://" ++ location.host ++ "/socket/websocket")
                |> Phoenix.Socket.on "cache:update" cacheChannel DecodeCache

        token =
            Native.Token.getToken ()

        payload =
            JE.object [ ( "guardian_token", JE.string token ) ]

        channel =
            Phoenix.Channel.init cacheChannel |> Phoenix.Channel.withPayload payload

        ( joinSocket, joinCmd ) =
            Phoenix.Socket.join channel socket

        push_ =
            Phoenix.Push.init "cache:update" cacheChannel
                |> Phoenix.Push.onOk DecodeCache

        ( phxSocket, phxCmd ) =
            Phoenix.Socket.push push_ joinSocket

        _ =
            Debug.log "joined channel: " phxCmd
    in
        { cache = flags.cache
        , phxSocket = phxSocket
        }
            ! [ Cmd.batch ([ Cmd.map PhoenixMsg phxCmd, Cmd.map PhoenixMsg joinCmd ]) ]


type alias Model =
    { cache : Cache
    , phxSocket : Phoenix.Socket.Socket Msg
    }


type Msg
    = DecodeCache JD.Value
    | PhoenixMsg (Phoenix.Socket.Msg Msg)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DecodeCache raw ->
            case JD.decodeValue cacheDecoder raw of
                Ok cache ->
                    let
                        cmd =
                            if model.cache.active /= cache.active then
                                [ reload True ]
                            else
                                []
                    in
                        { model | cache = cache } ! cmd

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
            if model.cache.total > 0 then
                renderProgress model
            else
                div [] []

        status =
            case model.cache.status of
                Nothing ->
                    div [] []

                Just status ->
                    if not model.cache.active then
                        p
                            [ class <| "text-" ++ status.state
                            , style [ ( "font-size", "12px" ) ]
                            , Html.Attributes.property "innerHTML" <| JE.string status.text
                            ]
                            []
                    else
                        div [] []
    in
        div [ class "col-sm-12 col-md-12 col-lg-6" ]
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
            if model.cache.processed > 0 then
                Round.round 2 <| (toFloat (model.cache.processed) / toFloat (model.cache.total) * 100)
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

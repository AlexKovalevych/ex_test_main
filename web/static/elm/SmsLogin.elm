port module SmsLogin exposing (..)

import Html exposing (Html, button, div, text, i, p)
import Html.Attributes exposing (class, type_)
import Html.Events exposing (onClick)
import Http exposing (..)
import Json.Decode as JD


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
    { isSending = False
    , success = False
    , error = False
    , csrf = ""
    , translations =
        { loginLabel = ""
        , smsLabel = ""
        , successResponse = ""
        , errorResponse = ""
        }
    }
        ! []


type Msg
    = SendSms
    | SetTranslations Translations
    | SetCsrf String
    | ResendSms (Result Http.Error String)


type alias Model =
    { isSending : Bool
    , success : Bool
    , error : Bool
    , translations : Translations
    , csrf : String
    }


type alias Translations =
    { smsLabel : String
    , loginLabel : String
    , successResponse : String
    , errorResponse : String
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SendSms ->
            { model | isSending = True, success = False, error = False } ! [ sendSms model.csrf ]

        SetTranslations translations ->
            { model | translations = translations } ! []

        SetCsrf csrf ->
            let
                _ =
                    Debug.log "HERE" csrf
            in
                { model | csrf = csrf } ! []

        ResendSms (Ok _) ->
            { model | isSending = False, success = True, error = False } ! []

        ResendSms (Err _) ->
            { model | isSending = False, success = False, error = True } ! []


view : Model -> Html Msg
view model =
    div [ class "form-group row text-xs-center" ]
        [ resultMessage model
        , button
            [ class "btn btn-primary mr-1", type_ "submit" ]
            [ text <| model.translations.loginLabel ]
        , button
            [ onClick SendSms, class "btn btn-secondary", type_ "button" ]
            [ text <| model.translations.smsLabel ]
        ]


resultMessage : Model -> Html Msg
resultMessage model =
    if model.isSending then
        p []
            [ i [ class "fa fa-spinner fa-spin" ] []
            ]
    else if model.success then
        div
            [ class "col s12 green-text text-darken-2 center-align mb-1" ]
            [ text <| model.translations.successResponse ]
    else if model.error then
        div
            [ class "col s12 red-text text-darken-2 center-align mb-1" ]
            [ text <| model.translations.errorResponse ]
    else
        div [] []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ translations SetTranslations
         , csrf SetCsrf
         ]
        )


sendSms : String -> Cmd Msg
sendSms csrf =
    Http.send ResendSms <|
        request
            { method = "POST"
            , headers = [ header "x-csrf-token" csrf ]
            , url = "/auth/sms/resend"
            , body = emptyBody
            , expect = expectJson JD.string
            , timeout = Nothing
            , withCredentials = False
            }


port translations : (Translations -> msg) -> Sub msg


port csrf : (String -> msg) -> Sub msg

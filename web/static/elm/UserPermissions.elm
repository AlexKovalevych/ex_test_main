port module UserPermissions exposing (..)

import Html exposing (Html, div, text, table, thead, tbody, tr, td, th)
import Permissions.Models exposing (..)
import Permissions.Messages exposing (..)
import Permissions.LeftBlock as Left exposing (..)
import Permissions.RightBlock as Right exposing (..)
import Permissions.Encoders exposing (userEncoder)
import Json.Encode exposing (encode)


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
    { users = []
    , projects = []
    , roles = []
    , activeType = UserType
    , value = ""
    , selectedRows = []
    , singleSelectRow = ""
    , translations = { projects = "", roles = "", users = "", selectAll = "" }
    }
        ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetUsers availableUsers ->
            { model | users = availableUsers } ! []

        SetProjects availableProjects ->
            { model | projects = availableProjects, selectedRows = List.map .id availableProjects } ! []

        SetRoles availableRoles ->
            { model | roles = availableRoles } ! []

        SetTranslations translations ->
            { model | translations = translations } ! []

        ClickLeftRow id event ->
            if event.shiftKey then
                { model | selectedRows = shiftSelectRow model id } ! []
            else if event.target.tagName == "TD" then
                { model | singleSelectRow = id, selectedRows = [ id ] } ! []
            else
                model ! []

        CheckLeftRow id event ->
            if event.target.tagName == "INPUT" then
                let
                    newModel =
                        checkLeftRow model id

                    encodedPermissions =
                        case List.head newModel.users of
                            Nothing ->
                                ""

                            Just user ->
                                encode 0 <| userEncoder user
                in
                    newModel ! [ permissions encodedPermissions ]
            else
                model ! []

        CheckRightRow id event ->
            if event.target.tagName == "INPUT" then
                let
                    newModel =
                        checkRightRow model id Nothing

                    encodedPermissions =
                        case List.head newModel.users of
                            Nothing ->
                                ""

                            Just user ->
                                encode 0 <| userEncoder user
                in
                    newModel ! [ permissions encodedPermissions ]
            else
                model ! []

        CheckRightAll ids event ->
            if event.target.tagName == "INPUT" then
                let
                    newModel =
                        checkRightAll model ids

                    encodedPermissions =
                        case List.head newModel.users of
                            Nothing ->
                                ""

                            Just user ->
                                encode 0 <| userEncoder user
                in
                    newModel ! [ permissions encodedPermissions ]
            else
                model ! []

        _ ->
            model ! []


view : Model -> Html Msg
view model =
    div
        []
        [ Left.view model
        , Right.view model
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ availableUsers SetUsers
         , availableProjects SetProjects
         , availableRoles SetRoles
         , translations SetTranslations
         ]
        )


port availableUsers : (List User -> msg) -> Sub msg


port availableProjects : (List Project -> msg) -> Sub msg


port availableRoles : (List Role -> msg) -> Sub msg


port translations : (Translations -> msg) -> Sub msg


port permissions : String -> Cmd msg

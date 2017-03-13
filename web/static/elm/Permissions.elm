port module Permissions exposing (..)

import Html exposing (Html, div, text, table, thead, tbody, tr, td, th)
import Permissions.Models exposing (..)
import Permissions.Messages exposing (..)
import Permissions.LeftBlock as Left exposing (..)
import Permissions.RightBlock as Right exposing (..)
import Permissions.Encoders exposing (userEncoder, encodePermissions)
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
                        encode 0 <| encodePermissions newModel.users
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
                        encode 0 <| encodePermissions newModel.users
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
                        encode 0 <| encodePermissions newModel.users
                in
                    newModel ! [ permissions encodedPermissions ]
            else
                model ! []

        SetValue newValue ->
            { model | value = newValue } ! []

        SetActiveType newType ->
            let
                activeType =
                    case newType of
                        "project" ->
                            ProjectType

                        "role" ->
                            RoleType

                        _ ->
                            UserType

                selectedRows =
                    case activeType of
                        ProjectType ->
                            List.map .id model.users |> List.filterMap identity

                        _ ->
                            List.map .id model.projects
            in
                { model | activeType = activeType, selectedRows = selectedRows } ! []


view : Model -> Html Msg
view model =
    if model.value == "" then
        div [] []
    else
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
         , value SetValue
         , activeType SetActiveType
         ]
        )


port availableUsers : (List User -> msg) -> Sub msg


port availableProjects : (List Project -> msg) -> Sub msg


port availableRoles : (List Role -> msg) -> Sub msg


port translations : (Translations -> msg) -> Sub msg


port permissions : String -> Cmd msg


port value : (String -> msg) -> Sub msg


port activeType : (String -> msg) -> Sub msg

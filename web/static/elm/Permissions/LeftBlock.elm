module Permissions.LeftBlock exposing (..)

import Html exposing (Html, Attribute, div, text, table, thead, tbody, tr, td, th, input, label, span)
import Html.Attributes exposing (class, style, type_, classList)
import Permissions.Decoders exposing (..)
import Permissions.Models exposing (..)
import Permissions.Messages exposing (..)
import Html.Events exposing (onClick, on)
import Json.Decode as JD
import List.Extra exposing (takeWhile, dropWhile)


title : Model -> String
title model =
    case model.activeType of
        UserType ->
            model.translations.projects

        ProjectType ->
            model.translations.users

        RoleType ->
            model.translations.projects


rows : Model -> List BlockRow
rows model =
    case model.activeType of
        UserType ->
            List.map projectRow model.projects

        ProjectType ->
            List.map userRow model.users

        RoleType ->
            List.map projectRow model.projects


view : Model -> Html Msg
view model =
    div
        [ class "col-sm-12 col-md-6 col-lg-6" ]
        [ table
            [ class "table table-bordered table-sm" ]
            [ thead
                []
                [ tr
                    []
                    [ th
                        [ class "p-1" ]
                        [ title model |> text
                        ]
                    ]
                ]
            , tbody
                []
                (List.map (rowView model) (rows model))
            ]
        ]


rowView : Model -> BlockRow -> Html Msg
rowView model data =
    tr
        [ classList [ ( "table-active", List.member data.value model.selectedRows ) ] ]
        [ td
            [ onClickRow <| ClickLeftRow data.value
            ]
          <|
            checkbox model data
        ]


checkbox : Model -> BlockRow -> List (Html Msg)
checkbox model data =
    [ label
        [ class "mb-0"
        , onClickInput <| CheckLeftRow data.value
        ]
        [ input
            [ class "ml-1 mr-1"
            , type_ "checkbox"
            , checkboxAttribute <| isCheckedLeftRow model data.value
            ]
            []
        , text data.label
        ]
    ]


onClickRow : (RowClickEvent -> msg) -> Attribute msg
onClickRow message =
    on "click" (JD.map message clickDecoder)


clickDecoder : JD.Decoder RowClickEvent
clickDecoder =
    JD.map2 RowClickEvent
        (JD.field "shiftKey" JD.bool)
        (JD.field "target" targetDecoder)


shiftSelectRow : Model -> String -> List String
shiftSelectRow model rowId =
    let
        addLastProject projectId projectIds =
            case projectById model projectId of
                Nothing ->
                    projectIds

                Just project ->
                    List.append projectIds [ project.id ]

        addLastUser userId userIds =
            case userById model userId of
                Nothing ->
                    userIds

                Just user ->
                    case user.id of
                        Nothing ->
                            userIds

                        Just lastUserId ->
                            List.append userIds [ lastUserId ]

        getListIndex result =
            case result of
                Nothing ->
                    0

                Just index ->
                    index

        getProjectIds =
            List.map .id model.projects
                |> (\projectIds ->
                        let
                            rowIdIndex =
                                getListIndex <| List.Extra.elemIndex rowId projectIds

                            singleRowIndex =
                                getListIndex <| List.Extra.elemIndex model.singleSelectRow projectIds
                        in
                            if rowIdIndex > singleRowIndex then
                                List.Extra.dropWhile ((/=) model.singleSelectRow) projectIds
                                    |> List.Extra.takeWhile ((/=) rowId)
                                    |> addLastProject rowId
                            else
                                List.Extra.dropWhile ((/=) rowId) projectIds
                                    |> List.Extra.takeWhile ((/=) model.singleSelectRow)
                                    |> addLastProject model.singleSelectRow
                   )
    in
        case model.activeType of
            ProjectType ->
                List.filterMap .id model.users
                    |> (\userIds ->
                            let
                                rowIdIndex =
                                    getListIndex <| List.Extra.elemIndex rowId userIds

                                singleRowIndex =
                                    getListIndex <| List.Extra.elemIndex model.singleSelectRow userIds
                            in
                                if rowIdIndex > singleRowIndex then
                                    List.Extra.dropWhile ((/=) model.singleSelectRow) userIds
                                        |> List.Extra.takeWhile ((/=) rowId)
                                        |> addLastUser rowId
                                else
                                    List.Extra.dropWhile ((/=) rowId) userIds
                                        |> List.Extra.takeWhile ((/=) model.singleSelectRow)
                                        |> addLastUser model.singleSelectRow
                       )

            _ ->
                getProjectIds

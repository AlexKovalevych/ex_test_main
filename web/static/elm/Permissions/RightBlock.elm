module Permissions.RightBlock exposing (..)

import Html exposing (Html, div, text, table, thead, tbody, tr, td, th, input, label, span)
import Html.Attributes exposing (class, style, type_)
import Permissions.Decoders exposing (..)
import Permissions.Models exposing (..)
import Permissions.Messages exposing (..)


title : Model -> String
title model =
    case model.activeType of
        UserType ->
            model.translations.roles

        ProjectType ->
            model.translations.roles

        RoleType ->
            model.translations.users


rows : Model -> List BlockRow
rows model =
    case model.activeType of
        UserType ->
            List.map roleRow model.roles

        ProjectType ->
            List.map roleRow model.roles

        RoleType ->
            List.map userRow model.users


rowIds : Model -> List String
rowIds model =
    case model.activeType of
        UserType ->
            model.roles

        ProjectType ->
            model.roles

        RoleType ->
            model.users |> List.map .id |> List.filterMap identity


view : Model -> Html Msg
view model =
    let
        allRowIds =
            rowIds model
    in
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
                            [ span [ class "float-xs-left" ] [ text <| title model ]
                            , div
                                [ class "float-xs-right" ]
                                [ label
                                    [ class "mb-0", onClickInput <| CheckRightAll allRowIds ]
                                    [ input
                                        [ class "mr-1"
                                        , type_ "checkbox"
                                        , checkboxAttribute <| isCheckedRightAll model allRowIds
                                        ]
                                        []
                                    , text <| model.translations.selectAll
                                    ]
                                ]
                            ]
                        ]
                    ]
                , tbody
                    []
                    (List.map (rowView model) <| rows model)
                ]
            ]


rowView : Model -> BlockRow -> Html Msg
rowView model data =
    tr
        []
        [ td
            []
          <|
            checkbox model data
        ]


checkbox : Model -> BlockRow -> List (Html Msg)
checkbox model data =
    [ label
        [ class "mb-0", onClickInput <| CheckRightRow data.value ]
        [ input
            [ class "ml-1 mr-1"
            , type_ "checkbox"
            , checkboxAttribute <| isCheckedRightRow model data.value
            ]
            []
        , text data.label
        ]
    ]

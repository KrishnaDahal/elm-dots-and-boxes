module App.View exposing (viewHeader, viewBody)

import App.Types exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


viewHeader : Model -> Html Msg
viewHeader model =
    section [ class "hero is-info" ]
        [ div [ class "hero-head" ]
            [ div [ class "container" ]
                [ div [ class "nav" ]
                    [ div [ class "nav-left" ]
                        [ span [ class "nav-item is-brand", onClick Test ] [ text "Elm Dots and Boxes" ] ]
                    ]
                ]
            ]
        ]


viewBody : Model -> Html Msg
viewBody model =
    let
        tableClasses =
            "field-table"
                ++ " field-table__"
                ++ toString model.width
                ++ " field-table__w"
                ++ toString model.width
                ++ " field-table__"
                ++ toString model.height
                ++ " field-table__h"
                ++ toString model.height
    in
        section
            [ class "section" ]
            [ table
                [ class tableClasses ]
                [ viewTableBody model
                ]
            ]


viewTableBody : Model -> Html Msg
viewTableBody model =
    tbody
        []
        (List.indexedMap (viewTableRows model) model.grid)


viewTableRows : Model -> Int -> List Box -> Html Msg
viewTableRows model y boxes =
    tr
        [ class "field-row" ]
        (List.indexedMap (viewTableCell model y) boxes)


viewTableCell : Model -> Int -> Int -> Box -> Html Msg
viewTableCell model y x box =
    let
        lastOnX =
            if x + 1 == model.width then
                [ div
                    [ class "edge edge__v edge__v__last" ]
                    []
                , span
                    [ class "dot dot__r dot__t" ]
                    []
                ]
            else
                []

        lastOnY =
            if y + 1 == model.height then
                [ div
                    [ class "edge edge__h edge__h__last" ]
                    []
                , span
                    [ class "dot dot__l dot__b" ]
                    []
                ]
            else
                []

        last =
            if x + 1 == model.width && y + 1 == model.height then
                [ span
                    [ class "dot dot__r dot__b" ]
                    []
                ]
            else
                []

        default =
            [ div
                [ class "edge edge__h" ]
                []
            , div
                [ class "edge edge__v" ]
                []
            , span
                [ class "dot dot__l dot__t" ]
                []
            ]
    in
        td
            [ class "field-cell" ]
            [ div
                [ class "edges" ]
                (default ++ lastOnX ++ lastOnY ++ last)
            ]



{--
        , table
            [ class "field-table field-table__3 field-table__w3 field-table__h3" ]
            [ tbody
                []
                [ tr
                    [ class "field-row" ]
                    [ td
                        [ class "field-cell" ]
                        [ div
                            [ class "edges" ]
                            [ div
                                [ class "edge edge__h" ]
                                []
                            , div
                                [ class "edge edge__v" ]
                                []
                            , span
                                [ class "dot dot__l dot__t" ]
                                []
                            ]
                        ]
                    , td
                        [ class "field-cell" ]
                        [ div
                            [ class "edges" ]
                            [ div
                                [ class "edge edge__h" ]
                                []
                            , div
                                [ class "edge edge__v" ]
                                []
                            , span
                                [ class "dot dot__l dot__t" ]
                                []
                            ]
                        ]
                    , td
                        [ class "field-cell" ]
                        [ div
                            [ class "edges" ]
                            [ div
                                [ class "edge edge__h" ]
                                []
                            , div
                                [ class "edge edge__v" ]
                                []
                            , div
                                [ class "edge edge__v edge__v__last" ]
                                []
                            , span
                                [ class "dot dot__l dot__t" ]
                                []
                            , span
                                [ class "dot dot__r dot__t" ]
                                []
                            ]
                        ]
                    ]
                , tr
                    [ class "field-row" ]
                    [ td
                        [ class "field-cell" ]
                        [ div
                            [ class "edges" ]
                            [ div
                                [ class "edge edge__h" ]
                                []
                            , div
                                [ class "edge edge__v" ]
                                []
                            , span
                                [ class "dot dot__l dot__t" ]
                                []
                            ]
                        ]
                    , td
                        [ class "field-cell field-cell__done field-cell__done__rival" ]
                        [ div
                            [ class "edges" ]
                            [ div
                                [ class "edge edge__h edge__done edge__done__self" ]
                                []
                            , div
                                [ class "edge edge__v edge__done edge__done__rival" ]
                                []
                            , span
                                [ class "dot dot__l dot__t" ]
                                []
                            ]
                        ]
                    , td
                        [ class "field-cell field-cell__done field-cell__done__rival" ]
                        [ div
                            [ class "edges" ]
                            [ div
                                [ class "edge edge__h edge__done edge__done__self" ]
                                []
                            , div
                                [ class "edge edge__v edge__done edge__done__rival" ]
                                []
                            , div
                                [ class "edge edge__v edge__v__last edge__done edge__done__self" ]
                                []
                            , span
                                [ class "dot dot__l dot__t" ]
                                []
                            , span
                                [ class "dot dot__r dot__t" ]
                                []
                            ]
                        ]
                    ]
                , tr
                    [ class "field-row" ]
                    [ td
                        [ class "field-cell" ]
                        [ div
                            [ class "edges" ]
                            [ div
                                [ class "edge edge__h" ]
                                []
                            , div
                                [ class "edge edge__v" ]
                                []
                            , div
                                [ class "edge edge__h edge__h__last" ]
                                []
                            , span
                                [ class "dot dot__l dot__t" ]
                                []
                            , span
                                [ class "dot dot__l dot__b" ]
                                []
                            ]
                        ]
                    , td
                        [ class "field-cell field-cell__done field-cell__done__rival" ]
                        [ div
                            [ class "edges" ]
                            [ div
                                [ class "edge edge__h edge__done edge__done__rival" ]
                                []
                            , div
                                [ class "edge edge__v edge__done edge__done__rival" ]
                                []
                            , div
                                [ class "edge edge__h edge__h__last edge__done edge__done__self" ]
                                []
                            , span
                                [ class "dot dot__l dot__t" ]
                                []
                            , span
                                [ class "dot dot__l dot__b" ]
                                []
                            ]
                        ]
                    , td
                        [ class "field-cell field-cell__done field-cell__done__self" ]
                        [ div
                            [ class "edges" ]
                            [ div
                                [ class "edge edge__h edge__done edge__done__rival" ]
                                []
                            , div
                                [ class "edge edge__v edge__done edge__done__rival" ]
                                []
                            , div
                                [ class "edge edge__h edge__h__last edge__done edge__done__rival" ]
                                []
                            , div
                                [ class "edge edge__v edge__v__last edge__done edge__done__self edge__done__last" ]
                                []
                            , span
                                [ class "dot dot__l dot__t" ]
                                []
                            , span
                                [ class "dot dot__l dot__b" ]
                                []
                            , span
                                [ class "dot dot__r dot__t" ]
                                []
                            , span
                                [ class "dot dot__r dot__b" ]
                                []
                            ]
                        ]
                    ]
                ]
            ]
        ]
-}

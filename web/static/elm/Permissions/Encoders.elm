module Permissions.Encoders exposing (..)

import Permissions.Models exposing (..)
import Json.Encode exposing (..)


encodePermissions : List User -> Value
encodePermissions users =
    list <| List.map userEncoder users


userEncoder : User -> Value
userEncoder user =
    let
        id =
            case user.id of
                Nothing ->
                    ""

                Just userId ->
                    userId
    in
        object
            [ ( "id", string id )
            , ( "permissions", permissionsEncoder user.permissions )
            ]


permissionsEncoder : Permissions -> Value
permissionsEncoder permissions =
    object
        [ ( "statistics", statisticsEncoder permissions.statistics )
        , ( "players", playersEncoder permissions.players )
        , ( "finance", financeEncoder permissions.finance )
        , ( "dashboard", dashboardEncoder permissions.dashboard )
        , ( "calendar_events", calendarEncoder permissions.calendar_events )
        ]


statisticsEncoder : StatisticsPermissions -> Value
statisticsEncoder permissions =
    object
        [ ( "timeline_report", projectsEncoder permissions.timeline_report )
        , ( "segments_report", projectsEncoder permissions.segments_report )
        , ( "retention", projectsEncoder permissions.retention )
        , ( "ltv_report", projectsEncoder permissions.ltv_report )
        , ( "consolidated_report", projectsEncoder permissions.consolidated_report )
        , ( "cohorts_report", projectsEncoder permissions.cohorts_report )
        , ( "activity_waves", projectsEncoder permissions.activity_waves )
        , ( "universal_report", projectsEncoder permissions.universal_report )
        ]


playersEncoder : PlayersPermissions -> Value
playersEncoder permissions =
    object
        [ ( "signup_channels", projectsEncoder permissions.signup_channels )
        , ( "multiaccounts", projectsEncoder permissions.multiaccounts )
        ]


financeEncoder : FinancePermissions -> Value
financeEncoder permissions =
    object
        [ ( "payments_check", projectsEncoder permissions.payments_check )
        , ( "payment_systems", projectsEncoder permissions.payment_systems )
        , ( "monthly_balance", projectsEncoder permissions.monthly_balance )
        , ( "funds_flow", projectsEncoder permissions.funds_flow )
        ]


dashboardEncoder : DashboardPermissions -> Value
dashboardEncoder permissions =
    object
        [ ( "dashboard_index", projectsEncoder permissions.dashboard_index )
        ]


calendarEncoder : CalendarPermissions -> Value
calendarEncoder permissions =
    object
        [ ( "events_types_list", projectsEncoder permissions.events_types_list )
        , ( "events_list", projectsEncoder permissions.events_list )
        , ( "events_groups_list", projectsEncoder permissions.events_groups_list )
        ]


projectsEncoder : List ProjectId -> Value
projectsEncoder projects =
    list <| List.map string projects

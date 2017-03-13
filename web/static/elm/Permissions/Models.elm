module Permissions.Models exposing (..)

import Html exposing (Attribute)
import Html.Attributes exposing (checked)
import Json.Encode as Json
import Html.Attributes exposing (property)
import Monocle.Lens exposing (Lens, compose)


--cases
--UserId -> Project -> Roles
--ProjectId -> User -> Roles
--RoleId -> Project -> Users


type ActiveType
    = UserType
    | ProjectType
    | RoleType


type alias ProjectId =
    String


type alias StatisticsPermissions =
    { timeline_report : List ProjectId
    , segments_report : List ProjectId
    , retention : List ProjectId
    , ltv_report : List ProjectId
    , consolidated_report : List ProjectId
    , cohorts_report : List ProjectId
    , activity_waves : List ProjectId
    , universal_report : List ProjectId
    }


type alias PlayersPermissions =
    { signup_channels : List ProjectId
    , multiaccounts : List ProjectId
    }


type alias FinancePermissions =
    { payments_check : List ProjectId
    , payment_systems : List ProjectId
    , monthly_balance : List ProjectId
    , funds_flow : List ProjectId
    }


type alias DashboardPermissions =
    { dashboard_index : List ProjectId
    }


type alias CalendarPermissions =
    { events_types_list : List ProjectId
    , events_list : List ProjectId
    , events_groups_list : List ProjectId
    }


type alias Permissions =
    { statistics : StatisticsPermissions
    , players : PlayersPermissions
    , finance : FinancePermissions
    , dashboard : DashboardPermissions
    , calendar_events : CalendarPermissions
    }



--Statistics lens


permissionsStatisticsLens : Lens Permissions StatisticsPermissions
permissionsStatisticsLens =
    let
        get p =
            p.statistics

        set s p =
            { p | statistics = s }
    in
        Lens get set


permissionsTimelineLens : Lens StatisticsPermissions (List ProjectId)
permissionsTimelineLens =
    let
        get s =
            s.timeline_report

        set p s =
            { s | timeline_report = p }
    in
        Lens get set


permissionsSegmentsLens : Lens StatisticsPermissions (List ProjectId)
permissionsSegmentsLens =
    let
        get s =
            s.segments_report

        set p s =
            { s | segments_report = p }
    in
        Lens get set


permissionsRetentionLens : Lens StatisticsPermissions (List ProjectId)
permissionsRetentionLens =
    let
        get s =
            s.retention

        set p s =
            { s | retention = p }
    in
        Lens get set


permissionsLtvLens : Lens StatisticsPermissions (List ProjectId)
permissionsLtvLens =
    let
        get s =
            s.ltv_report

        set p s =
            { s | ltv_report = p }
    in
        Lens get set


permissionsConsolidatedLens : Lens StatisticsPermissions (List ProjectId)
permissionsConsolidatedLens =
    let
        get s =
            s.consolidated_report

        set p s =
            { s | consolidated_report = p }
    in
        Lens get set


permissionsCohortsLens : Lens StatisticsPermissions (List ProjectId)
permissionsCohortsLens =
    let
        get s =
            s.cohorts_report

        set p s =
            { s | cohorts_report = p }
    in
        Lens get set


permissionsActivityWavesLens : Lens StatisticsPermissions (List ProjectId)
permissionsActivityWavesLens =
    let
        get s =
            s.activity_waves

        set p s =
            { s | activity_waves = p }
    in
        Lens get set


permissionsUniversalLens : Lens StatisticsPermissions (List ProjectId)
permissionsUniversalLens =
    let
        get s =
            s.universal_report

        set p s =
            { s | universal_report = p }
    in
        Lens get set



--Finance lens


permissionsFinanceLens : Lens Permissions FinancePermissions
permissionsFinanceLens =
    let
        get p =
            p.finance

        set s p =
            { p | finance = s }
    in
        Lens get set


permissionsPaymentCheckLens : Lens FinancePermissions (List ProjectId)
permissionsPaymentCheckLens =
    let
        get s =
            s.payments_check

        set p s =
            { s | payments_check = p }
    in
        Lens get set


permissionsPaymentSystemLens : Lens FinancePermissions (List ProjectId)
permissionsPaymentSystemLens =
    let
        get s =
            s.payment_systems

        set p s =
            { s | payment_systems = p }
    in
        Lens get set


permissionsMonthlyBalanceLens : Lens FinancePermissions (List ProjectId)
permissionsMonthlyBalanceLens =
    let
        get s =
            s.monthly_balance

        set p s =
            { s | monthly_balance = p }
    in
        Lens get set


permissionsFundsFlowLens : Lens FinancePermissions (List ProjectId)
permissionsFundsFlowLens =
    let
        get s =
            s.funds_flow

        set p s =
            { s | funds_flow = p }
    in
        Lens get set



--Players lens


permissionsPlayersLens : Lens Permissions PlayersPermissions
permissionsPlayersLens =
    let
        get p =
            p.players

        set s p =
            { p | players = s }
    in
        Lens get set


permissionsSignupChannelsLens : Lens PlayersPermissions (List ProjectId)
permissionsSignupChannelsLens =
    let
        get p =
            p.signup_channels

        set s p =
            { p | signup_channels = s }
    in
        Lens get set


permissionsMultiaccountsLens : Lens PlayersPermissions (List ProjectId)
permissionsMultiaccountsLens =
    let
        get p =
            p.multiaccounts

        set s p =
            { p | multiaccounts = s }
    in
        Lens get set



--Dashboard lens


permissionsDashboardLens : Lens Permissions DashboardPermissions
permissionsDashboardLens =
    let
        get p =
            p.dashboard

        set s p =
            { p | dashboard = s }
    in
        Lens get set


permissionsDashboardIndexLens : Lens DashboardPermissions (List ProjectId)
permissionsDashboardIndexLens =
    let
        get p =
            p.dashboard_index

        set s p =
            { p | dashboard_index = s }
    in
        Lens get set



--Calendar events lens


permissionsCalendarLens : Lens Permissions CalendarPermissions
permissionsCalendarLens =
    let
        get p =
            p.calendar_events

        set s p =
            { p | calendar_events = s }
    in
        Lens get set


permissionsEventTypesLens : Lens CalendarPermissions (List ProjectId)
permissionsEventTypesLens =
    let
        get p =
            p.events_types_list

        set s p =
            { p | events_types_list = s }
    in
        Lens get set


permissionsEventsLens : Lens CalendarPermissions (List ProjectId)
permissionsEventsLens =
    let
        get p =
            p.events_list

        set s p =
            { p | events_list = s }
    in
        Lens get set


permissionsEventGroupsLens : Lens CalendarPermissions (List ProjectId)
permissionsEventGroupsLens =
    let
        get p =
            p.events_groups_list

        set s p =
            { p | events_groups_list = s }
    in
        Lens get set


userPermissionsLens : Lens User Permissions
userPermissionsLens =
    let
        get u =
            u.permissions

        set a u =
            { u | permissions = a }
    in
        Lens get set


type alias User =
    { id : Maybe String
    , email : String
    , permissions : Permissions
    }


type alias Project =
    { id : String
    , title : String
    }


type alias Role =
    String


type alias Translations =
    { projects : String
    , roles : String
    , users : String
    , selectAll : String
    }


type alias Model =
    { users : List User
    , projects : List Project
    , roles : List Role
    , activeType : ActiveType
    , value : String
    , selectedRows : List String
    , translations : Translations
    , singleSelectRow : String
    }


type alias BlockRow =
    { label : String
    , value : String
    }


type RowState
    = Checked
    | Unchecked
    | Indeterminate


type alias RowClickEvent =
    { shiftKey : Bool
    , target : EventTarget
    }


type alias LabelClickEvent =
    { target : EventTarget
    }


type alias EventTarget =
    { tagName : String
    }


projectRow : Project -> BlockRow
projectRow project =
    { label = project.title
    , value = project.id
    }


userRow : User -> BlockRow
userRow user =
    let
        value =
            case user.id of
                Just id ->
                    id

                Nothing ->
                    ""
    in
        { label = user.email
        , value = value
        }


roleRow : Role -> BlockRow
roleRow role =
    { label = role
    , value = role
    }


indeterminate : Bool -> Attribute msg
indeterminate value =
    property "indeterminate" (Json.bool value)


getRowState : List Bool -> RowState
getRowState values =
    if List.all ((==) True) values then
        Checked
    else if List.all ((==) False) values then
        Unchecked
    else
        Indeterminate


isCheckedUserProjectRole : Model -> String -> String -> String -> Bool
isCheckedUserProjectRole model userId projectId roleId =
    case userById model userId of
        Nothing ->
            False

        Just user ->
            List.member projectId <| getUserRole user roleId


getUserRole : User -> String -> List ProjectId
getUserRole user role =
    let
        lens =
            getPermissionLens role
    in
        lens.get user


updateProjectRole : User -> String -> List ProjectId -> User
updateProjectRole user role projectIds =
    let
        lens =
            getPermissionLens role
    in
        lens.set projectIds user


getPermissionLens : String -> Lens User (List ProjectId)
getPermissionLens role =
    let
        roleLens =
            case role of
                "events_groups_list" ->
                    compose permissionsCalendarLens permissionsEventGroupsLens

                "events_list" ->
                    compose permissionsCalendarLens permissionsEventsLens

                "events_types_list" ->
                    compose permissionsCalendarLens permissionsEventTypesLens

                "funds_flow" ->
                    compose permissionsFinanceLens permissionsFundsFlowLens

                "monthly_balance" ->
                    compose permissionsFinanceLens permissionsMonthlyBalanceLens

                "payment_systems" ->
                    compose permissionsFinanceLens permissionsPaymentSystemLens

                "payments_check" ->
                    compose permissionsFinanceLens permissionsPaymentCheckLens

                "multiaccounts" ->
                    compose permissionsPlayersLens permissionsMultiaccountsLens

                "signup_channels" ->
                    compose permissionsPlayersLens permissionsSignupChannelsLens

                "activity_waves" ->
                    compose permissionsStatisticsLens permissionsActivityWavesLens

                "cohorts_report" ->
                    compose permissionsStatisticsLens permissionsCohortsLens

                "consolidated_report" ->
                    compose permissionsStatisticsLens permissionsConsolidatedLens

                "ltv_report" ->
                    compose permissionsStatisticsLens permissionsLtvLens

                "retention" ->
                    compose permissionsStatisticsLens permissionsRetentionLens

                "segments_report" ->
                    compose permissionsStatisticsLens permissionsSegmentsLens

                "timeline_report" ->
                    compose permissionsStatisticsLens permissionsTimelineLens

                "universal_report" ->
                    compose permissionsStatisticsLens permissionsUniversalLens

                _ ->
                    compose permissionsDashboardLens permissionsDashboardIndexLens
    in
        compose userPermissionsLens roleLens


checkLeftRow : Model -> String -> Model
checkLeftRow model valueId =
    let
        toggleFunction =
            case isCheckedLeftRow model valueId of
                Checked ->
                    uncheckValue

                _ ->
                    checkValue
    in
        case model.activeType of
            UserType ->
                case userById model model.value of
                    Nothing ->
                        model

                    Just user ->
                        let
                            updatedUser =
                                List.foldl
                                    (\role currentUser ->
                                        getUserRole currentUser role
                                            |> toggleFunction valueId
                                            |> updateProjectRole currentUser role
                                    )
                                    user
                                    model.roles

                            updatedUsers =
                                List.foldl
                                    (\user acc ->
                                        if user.id == updatedUser.id then
                                            acc ++ [ updatedUser ]
                                        else
                                            acc ++ [ user ]
                                    )
                                    []
                                    model.users
                        in
                            { model | users = updatedUsers }

            ProjectType ->
                case userById model valueId of
                    Nothing ->
                        model

                    Just user ->
                        let
                            updatedUser =
                                List.foldl
                                    (\role currentUser ->
                                        getUserRole currentUser role
                                            |> toggleFunction model.value
                                            |> updateProjectRole currentUser role
                                    )
                                    user
                                    model.roles

                            updatedUsers =
                                List.foldl
                                    (\user acc ->
                                        if user.id == updatedUser.id then
                                            acc ++ [ updatedUser ]
                                        else
                                            acc ++ [ user ]
                                    )
                                    []
                                    model.users
                        in
                            { model | users = updatedUsers }

            RoleType ->
                let
                    updatedUser user =
                        getUserRole user model.value
                            |> toggleFunction valueId
                            |> updateProjectRole user model.value

                    updatedUsers =
                        List.foldl
                            (\user acc ->
                                acc ++ [ updatedUser user ]
                            )
                            []
                            model.users
                in
                    { model | users = updatedUsers }


checkRightRow : Model -> String -> Maybe (String -> List ProjectId -> List ProjectId) -> Model
checkRightRow model valueId maybeFunction =
    let
        toggleFunction =
            case maybeFunction of
                Nothing ->
                    case isCheckedRightRow model valueId of
                        Checked ->
                            uncheckValue

                        _ ->
                            checkValue

                Just function ->
                    function
    in
        case model.activeType of
            UserType ->
                case userById model model.value of
                    Nothing ->
                        model

                    Just user ->
                        let
                            updatedUser =
                                List.foldl
                                    (\projectId currentUser ->
                                        getUserRole currentUser valueId
                                            |> toggleFunction projectId
                                            |> updateProjectRole currentUser valueId
                                    )
                                    user
                                    model.selectedRows

                            updatedUsers =
                                List.foldl
                                    (\user acc ->
                                        if user.id == updatedUser.id then
                                            acc ++ [ updatedUser ]
                                        else
                                            acc ++ [ user ]
                                    )
                                    []
                                    model.users
                        in
                            { model | users = updatedUsers }

            ProjectType ->
                let
                    updatedUser user =
                        getUserRole user valueId
                            |> toggleFunction model.value
                            |> updateProjectRole user valueId

                    updatedUsers =
                        List.foldl
                            (\user acc ->
                                case user.id of
                                    Nothing ->
                                        acc

                                    Just userId ->
                                        if List.member userId model.selectedRows then
                                            acc ++ [ updatedUser user ]
                                        else
                                            acc ++ [ user ]
                            )
                            []
                            model.users
                in
                    { model | users = updatedUsers }

            RoleType ->
                let
                    updatedUser user =
                        List.foldl
                            (\projectId acc ->
                                getUserRole acc model.value
                                    |> toggleFunction projectId
                                    |> updateProjectRole acc model.value
                            )
                            user
                            model.selectedRows

                    updatedUsers =
                        List.foldl
                            (\user acc ->
                                case user.id of
                                    Nothing ->
                                        acc

                                    Just userId ->
                                        if userId == valueId then
                                            acc ++ [ updatedUser user ]
                                        else
                                            acc ++ [ user ]
                            )
                            []
                            model.users
                in
                    { model | users = updatedUsers }


checkRightAll : Model -> List String -> Model
checkRightAll model ids =
    let
        toggleFunction =
            case isCheckedRightAll model ids of
                Checked ->
                    uncheckValue

                _ ->
                    checkValue
    in
        List.foldl
            (\id acc ->
                checkRightRow acc id <| Just toggleFunction
            )
            model
            ids


getAllUserPermissions : User -> List (List ProjectId)
getAllUserPermissions user =
    [ user.permissions.statistics.timeline_report
    , user.permissions.statistics.segments_report
    , user.permissions.statistics.retention
    , user.permissions.statistics.ltv_report
    , user.permissions.statistics.consolidated_report
    , user.permissions.statistics.cohorts_report
    , user.permissions.statistics.activity_waves
    , user.permissions.statistics.universal_report
    , user.permissions.finance.payments_check
    , user.permissions.finance.payment_systems
    , user.permissions.finance.funds_flow
    , user.permissions.finance.monthly_balance
    , user.permissions.calendar_events.events_list
    , user.permissions.calendar_events.events_types_list
    , user.permissions.calendar_events.events_groups_list
    , user.permissions.players.multiaccounts
    , user.permissions.players.signup_channels
    , user.permissions.dashboard.dashboard_index
    ]


checkValue : String -> List ProjectId -> List ProjectId
checkValue value projects =
    case List.member value projects of
        True ->
            projects

        False ->
            List.append projects [ value ]


uncheckValue : String -> List ProjectId -> List ProjectId
uncheckValue value projects =
    case List.member value projects of
        True ->
            List.filter ((/=) value) projects

        False ->
            projects


isCheckedLeftRow : Model -> String -> RowState
isCheckedLeftRow model value =
    case model.activeType of
        UserType ->
            case userById model model.value of
                Nothing ->
                    Unchecked

                Just user ->
                    isCheckedProjectByUserId user value

        ProjectType ->
            case projectById model model.value of
                Nothing ->
                    Unchecked

                Just project ->
                    isCheckedUserByProjectId model project value

        RoleType ->
            case roleByValueId model of
                Nothing ->
                    Unchecked

                Just role ->
                    isCheckedProjectByRoleId model role value


isCheckedRightRow : Model -> String -> RowState
isCheckedRightRow model value =
    case model.activeType of
        UserType ->
            case userById model model.value of
                Nothing ->
                    Unchecked

                Just user ->
                    List.foldl
                        (\v acc ->
                            List.append acc [ isCheckedRoleByProjectId model v value ]
                        )
                        []
                        model.selectedRows
                        |> getRowState

        ProjectType ->
            List.foldl
                (\userId acc ->
                    case userById model userId of
                        Nothing ->
                            acc

                        Just user ->
                            List.append acc [ isCheckedRoleByUserId model userId value ]
                )
                []
                model.selectedRows
                |> getRowState

        RoleType ->
            List.foldl
                (\projectId acc ->
                    case userById model value of
                        Nothing ->
                            acc

                        Just user ->
                            List.append acc [ isCheckedUserProjectRole model value projectId model.value ]
                )
                []
                model.selectedRows
                |> getRowState


isCheckedRightAll : Model -> List String -> RowState
isCheckedRightAll model rowIds =
    let
        allStates =
            List.map (isCheckedRightRow model) rowIds
    in
        if List.all ((==) Checked) allStates then
            Checked
        else if List.all ((==) Unchecked) allStates then
            Unchecked
        else
            Indeterminate


isCheckedRoleByProjectId : Model -> String -> String -> Bool
isCheckedRoleByProjectId model projectId roleId =
    case userById model model.value of
        Nothing ->
            False

        Just user ->
            isCheckedUserProjectRole model model.value projectId roleId


isCheckedRoleByUserId : Model -> String -> String -> Bool
isCheckedRoleByUserId model userId roleId =
    case userById model userId of
        Nothing ->
            False

        Just user ->
            isCheckedUserProjectRole model userId model.value roleId


userById : Model -> String -> Maybe User
userById model value =
    let
        filterUser user =
            case user.id of
                Nothing ->
                    Nothing

                Just userId ->
                    if userId == value then
                        Just user
                    else
                        Nothing
    in
        if value == "" then
            List.head model.users
        else
            List.filterMap filterUser model.users |> List.head


projectById : Model -> String -> Maybe Project
projectById model value =
    let
        filterProject project =
            if project.id == value then
                Just project
            else
                Nothing
    in
        List.filterMap filterProject model.projects |> List.head


roleByValueId : Model -> Maybe Role
roleByValueId model =
    let
        filterRole role =
            if role == model.value then
                Just role
            else
                Nothing
    in
        List.filterMap filterRole model.roles |> List.head


isCheckedProjectByUserId : User -> String -> RowState
isCheckedProjectByUserId user projectId =
    userPermissionsByProjectId user projectId


userPermissionsByProjectId : User -> String -> RowState
userPermissionsByProjectId user projectId =
    getRowState <| List.map (List.member projectId) <| getAllUserPermissions user


isCheckedUserByProjectId : Model -> Project -> String -> RowState
isCheckedUserByProjectId model project userId =
    case userById model userId of
        Nothing ->
            Unchecked

        Just user ->
            userPermissionsByProjectId user project.id


isCheckedProjectByRoleId : Model -> Role -> String -> RowState
isCheckedProjectByRoleId model role projectId =
    List.map
        (\user ->
            List.member projectId <| getUserRole user role
        )
        model.users
        |> getRowState


checkboxAttribute : RowState -> Attribute msg
checkboxAttribute rowState =
    case rowState of
        Checked ->
            checked True

        Unchecked ->
            checked False

        Indeterminate ->
            indeterminate True

module Permissions.Messages exposing (..)

import Permissions.Models exposing (..)


type Msg
    = SetUsers (List User)
    | SetProjects (List Project)
    | SetRoles (List Role)
    | SetTranslations Translations
    | ClickLeftRow String RowClickEvent
    | CheckLeftRow String LabelClickEvent
    | CheckRightRow String LabelClickEvent
    | SetValue String
    | SetActiveType String
    | CheckRightAll (List String) LabelClickEvent

module Page.Home exposing (Model, init, toSession, view)

import Debug
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Routes
import Session exposing (Session)



-- MODEL


type alias Model =
    Session


init : Session -> ( Model, Cmd msg )
init session =
    ( session, Cmd.none )



-- VIEW


viewContent : Model -> Html msg
viewContent _ =
    div [ class "page" ]
        [ a [ Routes.href Routes.Cricket ] [ img [ src "%PUBLIC_URL%/images/cricket_white.png", height 200, width 200, style "margin-top" "50px" ] [] ]
        ]


view : Model -> { title : String, content : Html msg }
view model =
    { title = "Cricket"
    , content = viewContent model
    }



-- EXPORT


toSession : Model -> Session
toSession model =
    model

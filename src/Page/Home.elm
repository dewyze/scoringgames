module Page.Home exposing (Model, init, toSession, view)

import Debug
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as Decode exposing (Decoder, Value, decodeValue, int, string)
import Json.Decode.Pipeline as Pipeline exposing (hardcoded, optional, required)
import Result exposing (toMaybe)
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
        [ h1 [] [ text "Home Page" ]
        , h2 [] [ text "Session" ]
        , a [ Routes.href Routes.Cricket ] [ text "Go to cricket" ]
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

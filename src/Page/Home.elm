module Page.Home exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Session exposing (Session)



-- MODEL


type alias Model =
    { message : String
    , clicks : Int
    , session : Session
    }


init : Session -> ( Model, Cmd Msg )
init session =
    ( { message = "Hello World " ++ session.id
      , clicks = 0
      , session = session
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Increment


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment ->
            ( { model | clicks = model.clicks + 1 }, Cmd.none )



-- VIEW


viewContent : Model -> Html Msg
viewContent model =
    div [ class "page" ]
        [ h1 [] [ text "Home Page" ]
        , h2 [] [ text model.message ]
        , h3 [] [ text ("Clicks: " ++ String.fromInt model.clicks) ]
        , button [ onClick Increment ] [ text "Click Me" ]
        ]


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Home"
    , content = viewContent model
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session

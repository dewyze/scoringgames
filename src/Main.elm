module Main exposing (..)

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Navigation
import Html exposing (..)
import Html.Attributes exposing (..)
import Routes exposing (Route)
import Url exposing (Url)



-- MODEL


type Page
    = Home
    | Cricket
    | MiniGolf
    | NotFound


type alias Model =
    { page : Page
    , navigationKey : Navigation.Key
    }


initialModel : Navigation.Key -> Model
initialModel navigationKey =
    { page = Home
    , navigationKey = navigationKey
    }


init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init () url navigationKey =
    changeRoute (Routes.fromUrl url) (initialModel navigationKey)



-- UPDATE


type Msg
    = ChangedRoute (Maybe Route)
    | ClickedLink UrlRequest
    | ChangedUrl Url


changeRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRoute maybeRoute model =
    case maybeRoute of
        Just Routes.Home ->
            ( { model | page = Home }, Cmd.none )

        Just Routes.Cricket ->
            ( { model | page = Cricket }, Cmd.none )

        Just Routes.MiniGolf ->
            ( { model | page = MiniGolf }, Cmd.none )

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangedRoute maybeRoute ->
            changeRoute maybeRoute model

        _ ->
            ( model, Cmd.none )



-- VIEW


viewContent : Page -> ( String, Html Msg )
viewContent page =
    case page of
        Home ->
            ( "Scoring.Games"
            , h1 [] [ text "Home" ]
            )

        Cricket ->
            ( "Scoring.Games | Cricket"
            , h1 [] [ text "Cricket" ]
            )

        MiniGolf ->
            ( "Scoring.Games | Mini Golf"
            , h1 [] [ text "MiniGolf" ]
            )

        NotFound ->
            ( "NOT FOUND"
            , h1 [ class "error" ] [ text "NOT FOUND" ]
            )


view : Model -> Document Msg
view model =
    let
        ( title, content ) =
            viewContent model.page
    in
    { title = title
    , body = [ div [ id "main" ] [ content ] ]
    }


main =
    Browser.application
        { init = init
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        }

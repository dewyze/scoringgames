module Main exposing (..)

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Navigation
import Html exposing (..)
import Html.Attributes
import Routes exposing (Route)
import Url exposing (Url)


type alias Model =
    { val : Int
    }



-- MODEL


initialModel : Navigation.Key -> Model
initialModel navigationKey =
    { val = 1 }


init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init () url navigationKey =
    ( { val = 1 }, Cmd.none )


type Msg
    = NoOp
    | ChangeRoute (Maybe Route)
    | ClickedLink UrlRequest
    | ChangedUrl Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


view : Model -> Document Msg
view model =
    { title = "Huzzah"
    , body =
        [ div
            [ Html.Attributes.id "main"
            ]
            [ h1 [] [ text "Works" ]
            ]
        ]
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

module Page.Home exposing (Model, Msg, decoder, init, subscriptions, toSession, update, view)

import Debug
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as Decode exposing (Decoder, Value, decodeValue, int, string)
import Json.Decode.Pipeline as Pipeline exposing (hardcoded, optional, required)
import Result exposing (toMaybe)
import Session exposing (Session)



-- MODEL


type alias Model =
    { message : String
    , clicks : Int
    , session : Session
    }


decoder : Session -> Decoder Model
decoder session =
    Decode.succeed Model
        |> required "message" string
        |> required "clicks" int
        |> hardcoded session


defaultModel : Session -> Model
defaultModel session =
    { message = "Hello World"
    , clicks = 0
    , session = session
    }


init : Decode.Value -> Session -> ( Model, Cmd Msg )
init value session =
    let
        result =
            decodeValue Decode.string value
                |> Result.andThen (Decode.decodeString (decoder session))

        model =
            Result.withDefault (defaultModel session) result
    in
    ( model, Cmd.none )



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

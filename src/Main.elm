port module Main exposing (..)

-- import Page.NotFound as NotFound

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Debug
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode exposing (Decoder, Value, int, string)
import Json.Decode.Pipeline as Pipeline exposing (hardcoded, optional, required)
import Json.Encode as Encode
import Page exposing (Page)
import Page.Home as Home
import Routes exposing (Route)
import Session exposing (Session, init)
import Url exposing (Url)



-- MODEL


type Model
    = Initialized Session
    | WaitingForConfig Session Route
    | NotFound Session
    | Home Home.Model


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init () url navKey =
    requestRoute (Routes.fromUrl url) (Initialized (Session.init navKey))



-- UPDATE


type Msg
    = RequestRoute (Maybe Route)
    | RequestConfig
    | ReceivedConfig Decode.Value
    | ChangedUrl Url
    | ClickedLink UrlRequest
    | GotHomeMsg Home.Msg
    | GotSession Session


requestRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
requestRoute maybeRoute model =
    let
        session =
            toSession model
    in
    case maybeRoute of
        Nothing ->
            ( NotFound session, Cmd.none )

        Just route ->
            let
                routeString =
                    Routes.routeToConfig route

                value =
                    Encode.object
                        [ ( "app", Encode.string routeString )
                        , ( "method", Encode.string "get" )
                        ]
            in
            ( WaitingForConfig session route, storage value )



-- Home.init session
--     |> updateWith Home GotHomeMsg model


toSession : Model -> Session
toSession model =
    case model of
        Initialized session ->
            session

        WaitingForConfig session _ ->
            session

        NotFound session ->
            session

        Home home ->
            Home.toSession home


port storage : Encode.Value -> Cmd msg


port configs : (Decode.Value -> msg) -> Sub msg


changeRoute : Encode.Value -> Route -> Model -> ( Model, Cmd Msg )
changeRoute value route model =
    let
        session =
            toSession model
    in
    case route of
        Routes.Home ->
            Home.init value session
                |> updateWith Home GotHomeMsg model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( RequestRoute maybeRoute, _ ) ->
            requestRoute maybeRoute model

        ( ReceivedConfig config, WaitingForConfig session route ) ->
            changeRoute config route model

        ( GotHomeMsg subMsg, Home home ) ->
            Home.update subMsg home
                |> updateWith Home GotHomeMsg model

        _ ->
            ( model, Cmd.none )


updateWith : (subModel -> Model) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg model ( subModel, subCmd ) =
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )



-- VIEW


view : Model -> Document Msg
view model =
    let
        viewPage page toMsg pageModel =
            let
                { title, body } =
                    Page.view page pageModel
            in
            { title = title
            , body = List.map (Html.map toMsg) body
            }
    in
    case model of
        Initialized _ ->
            Page.view Page.Other { title = "Initialized", content = h1 [] [ text "BLANK" ] }

        WaitingForConfig _ _ ->
            Page.view Page.Other { title = "Initialized", content = h1 [] [ text "BLANK" ] }

        NotFound _ ->
            Page.view Page.Other { title = "NotFound", content = h1 [] [ text "NOT FOUND" ] }

        Home home ->
            viewPage Page.Home GotHomeMsg (Home.view home)



-- SUBSCRIPTIONS
-- TODO: Check the URL here?


subscriptions : Model -> Sub Msg
subscriptions _ =
    configs (\value -> ReceivedConfig <| value)


main =
    Browser.application
        { init = init
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        , subscriptions = subscriptions
        , update = update
        , view = view
        }

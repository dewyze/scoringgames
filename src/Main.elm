port module Main exposing (..)

-- import Page.NotFound as NotFound

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Debug
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Page exposing (Page)
import Page.Cricket as Cricket
import Page.Home as Home
import Ports exposing (configs, storage)
import Routes exposing (Route)
import Session exposing (Session, init)
import Url exposing (Url)



-- MODEL


type Model
    = Home Home.Model
    | WaitingForConfig Session Route
    | NotFound Session
    | Cricket Cricket.Model


init : { windowHeight : Int } -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    requestRoute (Routes.fromUrl url) (Home (Session.init navKey flags.windowHeight))



-- UPDATE


type Msg
    = RequestRoute (Maybe Route)
    | RequestConfig
    | ReceivedConfig Decode.Value
    | ChangedUrl Url
    | ClickedLink UrlRequest
    | GotCricketMsg Cricket.Msg
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

        Just Routes.Home ->
            ( Home session, Cmd.none )

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


toSession : Model -> Session
toSession model =
    case model of
        Home session ->
            session

        WaitingForConfig session _ ->
            session

        NotFound session ->
            session

        Cricket cricket ->
            Cricket.toSession cricket


changeRoute : Encode.Value -> Route -> Model -> ( Model, Cmd Msg )
changeRoute value route model =
    let
        session =
            toSession model
    in
    case route of
        Routes.Home ->
            ( Home session, Routes.replaceUrl session.navKey Routes.Home )

        Routes.Cricket ->
            Cricket.init value session
                |> updateWith Cricket GotCricketMsg model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        session =
            toSession model
    in
    case ( msg, model ) of
        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl session.navKey (Url.toString url) )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        ( ChangedUrl url, _ ) ->
            requestRoute (Routes.fromUrl url) model

        ( RequestRoute maybeRoute, _ ) ->
            requestRoute maybeRoute model

        ( ReceivedConfig config, WaitingForConfig _ route ) ->
            changeRoute config route model

        ( GotCricketMsg subMsg, Cricket cricket ) ->
            Cricket.update subMsg cricket
                |> updateWith Cricket GotCricketMsg model

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
        Home home ->
            Page.view Page.Home (Home.view home)

        WaitingForConfig session _ ->
            Page.view Page.Other (Home.view session)

        NotFound _ ->
            Page.view Page.Other { title = "NotFound", content = h1 [] [ text "NOT FOUND" ] }

        Cricket cricket ->
            viewPage Page.Cricket GotCricketMsg (Cricket.view cricket)



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

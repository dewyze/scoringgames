module Main exposing (..)

-- import Page.NotFound as NotFound

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Page exposing (Page)
import Page.Home as Home
import Routes exposing (Route)
import Session exposing (Session, init)
import Url exposing (Url)



-- MODEL


type Model
    = Loading Session
    | NotFound Session
    | Home Home.Model


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init () url navKey =
    changeRoute (Routes.fromUrl url) (Loading (Session.init navKey))



-- UPDATE


type Msg
    = ChangedRoute (Maybe Route)
    | ChangedUrl Url
    | ClickedLink UrlRequest
    | GotHomeMsg Home.Msg
    | GotSession Session


changeRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRoute maybeRoute model =
    let
        session =
            toSession model
    in
    case maybeRoute of
        Just Routes.Home ->
            Home.init session
                |> updateWith Home GotHomeMsg model

        Nothing ->
            ( NotFound session, Cmd.none )


toSession : Model -> Session
toSession model =
    case model of
        Loading session ->
            session

        NotFound session ->
            session

        Home home ->
            Home.toSession home


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( ChangedRoute maybeRoute, _ ) ->
            changeRoute maybeRoute model

        ( GotHomeMsg subMsg, Home home ) ->
            Home.update subMsg home
                |> updateWith Home GotHomeMsg model

        -- Useful when we have an active session
        -- ( GotSession session, Loading _ ) ->
        --   ( Loading session
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
        Loading _ ->
            Page.view Page.Other { title = "Loading", content = h1 [] [ text "BLANK" ] }

        NotFound _ ->
            Page.view Page.Other { title = "NotFound", content = h1 [] [ text "NOT FOUND" ] }

        Home home ->
            viewPage Page.Home GotHomeMsg (Home.view home)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


main =
    Browser.application
        { init = init
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        , subscriptions = subscriptions
        , update = update
        , view = view
        }

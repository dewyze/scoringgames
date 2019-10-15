module Page.Cricket exposing (Model, Msg, decoder, init, subscriptions, toSession, update, view)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode exposing (Decoder, Value, decodeValue, int, keyValuePairs, list, string)
import Json.Decode.Pipeline as Pipeline exposing (hardcoded, optional, required)
import Result exposing (toMaybe)
import Session exposing (Session)
import String exposing (fromInt, toInt)
import Svg exposing (circle, rect)
import Svg.Attributes as SvgAttr



-- MODEL


type alias Target =
    Int


type alias Targets =
    Dict Int TargetState


type TargetState
    = Open
    | One
    | Two
    | Points Int



-- TODO - Be int for faster processing?


type alias PlayerId =
    Int


type alias Player =
    { id : PlayerId
    , targets : Targets
    , name : String
    }


type alias Model =
    { players : List Player
    , numPlayers : Int
    , subtractingMode : Bool
    , settingsMode : Bool
    , session : Session
    }


targets : List Target
targets =
    [ 20, 19, 18, 17, 16, 15, 25 ]


initTarget : Int -> ( Target, TargetState )
initTarget num =
    ( num, Open )


initTargets : Targets
initTargets =
    Dict.fromList (List.map initTarget targets)


initPlayer : Int -> Player
initPlayer id =
    { id = id
    , targets = initTargets
    , name = ""
    }


defaultModel : Session -> Model
defaultModel session =
    { players = List.map initPlayer [ 1, 2 ]
    , numPlayers = 2
    , subtractingMode = False
    , settingsMode = False
    , session = session
    }


init : Decode.Value -> Session -> ( Model, Cmd Msg )
init _ session =
    ( defaultModel session, Cmd.none )



-- init : Decode.Value -> Session -> ( Model, Cmd Msg )
-- init value session =
--     let
--         result =
--             decodeValue Decode.string value
--                 |> Result.andThen (Decode.decodeString (decoder session))
--
--         model =
--             Result.withDefault (defaultModel session) result
--     in
--     ( model, Cmd.none )
-- -- DECODERS
--
-- playersDecoder : Decoder (List Player)
-- playersDecoder =
--     list playerDecoder
--
--
-- playerDecoder : Decoder Player
-- playerDecoder =
--     Decode.succeed Player
--         |> required "id" string
--         |> required "name" string
--
--
-- targetStateDecoder : Decoder TargetState
-- targetStateDecoder =
--     Decode.string
--         |> Decode.andThen
--             (\str ->
--                 case str of
--                     "open" ->
--                         Decode.succeed Open
--
--                     "one" ->
--                         Decode.succeed One
--
--                     "two" ->
--                         Decode.succeed Two
--
--                     points ->
--                         Decode.succeed (Points (String.toInt points))
--             )
--
--
-- targetRowDecoder : Decoder TargetRow
-- targetRowDecoder =
--     keyValuePairs targetStateDecoder
--
--
-- boardDecoder : Decoder Board
-- boardDecoder =
--     keyValuePairs targetRowDecoder
--
--


decoder : Session -> Decoder Model
decoder session =
    Decode.succeed Model
        |> hardcoded (List.map initPlayer [ 1, 2, 3, 4 ])
        |> hardcoded 2
        |> hardcoded False
        |> hardcoded False
        |> hardcoded session



-- UPDATE


type Msg
    = ClickTarget PlayerId Target TargetState
    | ToggleSubtractingMode
    | ToggleSettingsMode
    | DecrementNumPlayers
    | IncrementNumPlayers
    | PlayerName Int String
    | NewGame


previousState : TargetState -> Target -> TargetState
previousState state target =
    case state of
        Points 0 ->
            Two

        Points p ->
            Points (p - target)

        Two ->
            One

        _ ->
            Open


nextState : TargetState -> Int -> TargetState
nextState state target =
    case state of
        Open ->
            One

        One ->
            Two

        Two ->
            Points 0

        Points p ->
            Points (p + target)


updateTargetState : TargetState -> Target -> Bool -> TargetState
updateTargetState state target subtracting =
    if subtracting then
        previousState state target

    else
        nextState state target


setPlayerName : PlayerId -> Model -> String -> Model
setPlayerName playerId model newName =
    let
        updatePlayer player =
            if player.id == playerId then
                { player | name = newName }

            else
                player
    in
    { model | players = List.map updatePlayer model.players }


removePlayer : List Player -> List Player
removePlayer players =
    let
        numPlayers =
            List.length players
    in
    List.take (numPlayers - 1) players


addPlayer : List Player -> List Player
addPlayer players =
    let
        newId =
            List.length players + 1
    in
    players ++ [ initPlayer newId ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickTarget playerId target state ->
            let
                updatePlayer player =
                    if player.id == playerId then
                        { player | targets = Dict.insert target (updateTargetState state target model.subtractingMode) player.targets }

                    else
                        player
            in
            if not model.subtractingMode && targetClosedForAll model target then
                ( model, Cmd.none )

            else
                ( { model | players = List.map updatePlayer model.players }, Cmd.none )

        ToggleSettingsMode ->
            if model.settingsMode then
                ( { model | settingsMode = False }, Cmd.none )

            else
                ( { model | settingsMode = True }, Cmd.none )

        ToggleSubtractingMode ->
            if model.subtractingMode then
                ( { model | subtractingMode = False }, Cmd.none )

            else
                ( { model | subtractingMode = True }, Cmd.none )

        DecrementNumPlayers ->
            if List.length model.players > 2 then
                ( { model
                    | numPlayers = model.numPlayers - 1
                    , players = removePlayer model.players
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        IncrementNumPlayers ->
            if List.length model.players < 4 then
                ( { model
                    | numPlayers = model.numPlayers + 1
                    , players = addPlayer model.players
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        PlayerName id name ->
            ( setPlayerName id model name, Cmd.none )

        NewGame ->
            let
                resetPlayer player =
                    { player | targets = initTargets }
            in
            ( { model
                | players = List.map resetPlayer model.players
                , settingsMode = False
              }
            , Cmd.none
            )



-- VIEW


indexToId : Int -> Int
indexToId index =
    index + 1


viewSettingsPlayer : Int -> Int -> Player -> List (Html Msg)
viewSettingsPlayer numPlayers index player =
    let
        playerId =
            indexToId index

        playerNumString =
            fromInt playerId

        formName =
            "player" ++ playerNumString ++ "name"
    in
    [ label [ for formName ] [ text ("Player " ++ playerNumString) ]
    , input [ class "player-name-input", type_ "text", name formName, placeholder (playerName player), onInput (PlayerName playerId) ] []
    ]


viewSettings : Model -> Html Msg
viewSettings model =
    div
        [ id "main", class "wrapper settings" ]
        ([ span [ class "player-count-label" ] [ text "# of Players" ]
         , button [ class "player-count-button", onClick DecrementNumPlayers ] [ text "-" ]
         , span [ class "player-count-number" ] [ text (fromInt model.numPlayers) ]
         , button [ class "player-count-button", onClick IncrementNumPlayers ] [ text "+" ]
         ]
            ++ List.concat (List.indexedMap (viewSettingsPlayer model.numPlayers) model.players)
            ++ [ button [ onClick ToggleSettingsMode ] [ text "Done" ]
               , div [ class "new-game" ] [ button [ onClick NewGame ] [ text "New Game" ] ]
               ]
        )



-- SHAPES AND COLOR


svgRect : (TargetState -> String) -> TargetState -> String -> Html Msg
svgRect func state rotate =
    rect [ SvgAttr.x "5", SvgAttr.y "40", SvgAttr.width "90", SvgAttr.height "20", SvgAttr.fill (func state), SvgAttr.transform rotate ] []



-- TODO: Set this on the player
-- TODO: Or conver to maybe


playerName : Player -> String
playerName player =
    if String.isEmpty player.name then
        "Player " ++ fromInt player.id

    else
        player.name


editingSymbol : Model -> String
editingSymbol model =
    if model.subtractingMode then
        "-"

    else
        "+"


forwardSlashColor : Bool -> TargetState -> String
forwardSlashColor closed state =
    if closed then
        "#990000"

    else
        case state of
            Open ->
                "#333"

            _ ->
                "#DDD"


backSlashColor : Bool -> TargetState -> String
backSlashColor closed state =
    if closed then
        "#990000"

    else
        case state of
            Open ->
                "#333"

            One ->
                "#333"

            _ ->
                "#DDD"


circleColor : Bool -> TargetState -> String
circleColor closed state =
    if closed then
        "#990000"

    else
        case state of
            Points p ->
                "#DDD"

            _ ->
                "#333"


viewPlayerHeader : Int -> Player -> Html Msg
viewPlayerHeader numPlayers player =
    div [ class ("player-name player-column players-" ++ fromInt numPlayers) ]
        [ text (playerName player) ]


viewHeader : Model -> List (Html Msg)
viewHeader model =
    [ div
        [ class "row info-row header-row" ]
        ([ div [ class "number-column negative-toggle", onClick ToggleSubtractingMode ]
            [ text (editingSymbol model) ]
         ]
            ++ List.map (\player -> viewPlayerHeader model.numPlayers player) model.players
        )
    ]


targetStateForPlayerNumber : Int -> Player -> TargetState
targetStateForPlayerNumber target player =
    Maybe.withDefault (Points 0) (Dict.get target player.targets)


pointsForState : TargetState -> Int
pointsForState state =
    case state of
        Points p ->
            p

        _ ->
            0


targetClosed : Target -> Model -> Player -> Bool
targetClosed target model player =
    case targetStateForPlayerNumber target player of
        Points x ->
            True

        _ ->
            False


targetClosedForAll : Model -> Target -> Bool
targetClosedForAll model target =
    List.all (targetClosed target model) model.players


viewPlayerTarget : Target -> Model -> Player -> Html Msg
viewPlayerTarget target model player =
    let
        state =
            targetStateForPlayerNumber target player

        points =
            pointsForState state

        closed =
            targetClosedForAll model target

        cssClass =
            "player-column players-" ++ fromInt model.numPlayers ++ " marker"
    in
    if model.subtractingMode && points > 0 then
        div [ class cssClass, onClick (ClickTarget player.id target state) ]
            [ text (fromInt points) ]

    else
        div [ class cssClass ]
            [ Svg.svg [ SvgAttr.viewBox "0 0 100 100", SvgAttr.height "100%", SvgAttr.style "background-color:#111", onClick (ClickTarget player.id target state) ]
                [ svgRect (backSlashColor closed) state "rotate(135 50 50)"
                , svgRect (forwardSlashColor closed) state "rotate(45 50 50)"
                , circle [ SvgAttr.cx "50", SvgAttr.cy "50", SvgAttr.r "45", SvgAttr.stroke (circleColor closed state), SvgAttr.strokeWidth "10", SvgAttr.fill "none" ] []
                ]
            ]


viewTargetRow : Model -> Target -> Html Msg
viewTargetRow model target =
    div
        [ class "row marker-row" ]
        ([ div [ class "number-column number" ] [ text (viewTarget target) ] ]
            ++ List.map (\player -> viewPlayerTarget target model player) model.players
        )


viewTarget : Target -> String
viewTarget target =
    if target == 25 then
        "B"

    else
        fromInt target



-- TODO : Simplify


scoreForPlayer : Player -> Int
scoreForPlayer player =
    let
        states =
            List.map (\n -> Maybe.withDefault (Points 0) (Dict.get n player.targets)) targets
    in
    List.foldl (+) 0 (List.map pointsForState states)


viewPlayerTotal : Int -> Player -> Html Msg
viewPlayerTotal numPlayers player =
    let
        cssClass =
            "player-total player-column players-" ++ fromInt numPlayers
    in
    div [ class cssClass ] [ text (fromInt (scoreForPlayer player)) ]


viewTotal : Model -> List (Html Msg)
viewTotal model =
    [ div [ class "row info-row total-row" ]
        ([ div [ class "number-column", onClick ToggleSettingsMode ]
            [ img [ src "%PUBLIC_URL%/settings.png", SvgAttr.height "90%" ] [] ]
         ]
            ++ List.map (\player -> viewPlayerTotal model.numPlayers player) model.players
        )
    ]


viewBoard : Model -> Html Msg
viewBoard model =
    div
        [ id "main", class "wrapper" ]
        (viewHeader model
            ++ List.map (viewTargetRow model) targets
            ++ viewTotal model
        )


viewContent : Model -> Html Msg
viewContent model =
    if model.settingsMode then
        viewSettings model

    else
        viewBoard model


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Cricket"
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
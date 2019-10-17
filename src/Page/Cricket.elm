module Page.Cricket exposing (Model, Msg, decoder, init, subscriptions, toSession, update, view)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode exposing (Decoder, Value, decodeValue, int, keyValuePairs, list, string)
import Json.Decode.Pipeline as Pipeline exposing (hardcoded, optional, required)
import Json.Encode as Encode
import Ports exposing (storage)
import Result exposing (toMaybe)
import Session exposing (Session)
import String exposing (fromInt, toInt)
import Svg exposing (circle, rect)
import Svg.Attributes as SvgAttr


-- MODEL


type alias Target =
    Int


type alias Targets =
    Dict Target TargetState


type TargetState
    = Open
    | One
    | Two
    | Points Int


type alias PlayerId =
    Int


type alias Player =
    { id : PlayerId
    , name : String
    , targets : Targets
    }


type alias Model =
    { players : List Player
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
    , name = "Player " ++ fromInt id
    , targets = initTargets
    }


defaultModel : Session -> Model
defaultModel session =
    { players = List.map initPlayer [ 1, 2 ]
    , subtractingMode = False
    , settingsMode = False
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



-- DECODERS


targetStateDecoder : Decoder TargetState
targetStateDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "open" ->
                        Decode.succeed Open

                    "one" ->
                        Decode.succeed One

                    "two" ->
                        Decode.succeed Two

                    points ->
                        Decode.succeed (Points (Maybe.withDefault 0 (String.toInt points)))
            )


listToDictDecoder : List ( String, TargetState ) -> Decoder Targets
listToDictDecoder list =
    let
        tupleConvert : ( String, TargetState ) -> ( Int, TargetState )
        tupleConvert ( key, value ) =
            let
                intKey =
                    String.toInt key
            in
                case intKey of
                    Just int ->
                        ( int, value )

                    Nothing ->
                        ( 0, value )

        newList =
            List.map (\tuple -> tupleConvert tuple) list
    in
        Decode.succeed (Dict.fromList newList)


targetsDecoder : Decoder Targets
targetsDecoder =
    keyValuePairs targetStateDecoder |> Decode.andThen listToDictDecoder


playerDecoder : Decoder Player
playerDecoder =
    Decode.succeed Player
        |> required "id" int
        |> required "name" string
        |> required "targets" targetsDecoder


playersDecoder : Decoder (List Player)
playersDecoder =
    list playerDecoder


decoder : Session -> Decoder Model
decoder session =
    Decode.succeed Model
        |> required "players" playersDecoder
        |> hardcoded False
        |> hardcoded False
        |> hardcoded session



-- ENCODERS


targetStateEncoder : TargetState -> Encode.Value
targetStateEncoder targetState =
    case targetState of
        Open ->
            Encode.string "open"

        One ->
            Encode.string "one"

        Two ->
            Encode.string "two"

        Points p ->
            Encode.string (fromInt p)


targetsEncoder : Targets -> Encode.Value
targetsEncoder targets_ =
    Encode.dict fromInt targetStateEncoder targets_


playerEncoder : Player -> Encode.Value
playerEncoder player =
    Encode.object
        [ ( "id", Encode.int player.id )
        , ( "name", Encode.string player.name )
        , ( "targets", targetsEncoder player.targets )
        ]


configEncoder : List Player -> Encode.Value
configEncoder players =
    Encode.object
        [ ( "players", Encode.list playerEncoder players ) ]


encode : Model -> Encode.Value
encode model =
    Encode.object
        [ ( "method", Encode.string "set" )
        , ( "app", Encode.string "cricket" )
        , ( "config", configEncoder model.players )
        ]


writeConfig : Model -> ( Model, Cmd msg )
writeConfig model =
    ( model, storage (encode model) )



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
                    writeConfig model
                else
                    writeConfig ({ model | players = List.map updatePlayer model.players })

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
                let
                    newModel =
                        { model
                            | players = removePlayer model.players
                        }
                in
                    ( newModel
                    , Cmd.none
                    )
            else
                ( model, Cmd.none )

        IncrementNumPlayers ->
            if List.length model.players < 4 then
                writeConfig ({ model | players = addPlayer model.players })
            else
                writeConfig (model)

        PlayerName id name ->
            writeConfig (setPlayerName id model name)

        NewGame ->
            let
                resetPlayer player =
                    { player | targets = initTargets }
            in
                writeConfig { model | players = List.map resetPlayer model.players, settingsMode = False }



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
        , input [ class "player-name-input", type_ "text", name formName, placeholder (player.name), onInput (PlayerName playerId) ] []
        ]


viewSettings : Model -> Html Msg
viewSettings model =
    let
        numPlayers =
            List.length model.players
    in
        div
            [ id "main", class "wrapper settings" ]
            ([ span [ class "player-count-label" ] [ text "# of Players" ]
             , button [ class "player-count-button", onClick DecrementNumPlayers ] [ text "-" ]
             , span [ class "player-count-number" ] [ text (fromInt numPlayers) ]
             , button [ class "player-count-button", onClick IncrementNumPlayers ] [ text "+" ]
             ]
                ++ List.concat (List.indexedMap (viewSettingsPlayer numPlayers) model.players)
                ++ [ button [ onClick ToggleSettingsMode ] [ text "Done" ]
                   , div [ class "new-game" ] [ button [ onClick NewGame ] [ text "New Game" ] ]
                   ]
            )



-- SHAPES AND COLOR


svgRect : (TargetState -> String) -> TargetState -> String -> Html Msg
svgRect func state rotate =
    rect [ SvgAttr.x "5", SvgAttr.y "40", SvgAttr.width "90", SvgAttr.height "20", SvgAttr.fill (func state), SvgAttr.transform rotate ] []


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
        [ text (player.name) ]


viewHeader : Model -> List (Html Msg)
viewHeader model =
    let
        numPlayers =
            List.length model.players
    in
        [ div
            [ class "row info-row header-row" ]
            ([ div [ class "number-column negative-toggle", onClick ToggleSubtractingMode ]
                [ text (editingSymbol model) ]
             ]
                ++ List.map (\player -> viewPlayerHeader numPlayers player) model.players
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

        playersCount =
            fromInt (List.length model.players)

        cssClass =
            "player-column players-" ++ playersCount ++ " marker"
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


viewPlayerTotal : Model -> Player -> Html Msg
viewPlayerTotal model player =
    let
        numPlayers =
            fromInt (List.length model.players)

        cssClass =
            "player-total player-column players-" ++ numPlayers
    in
        div [ class cssClass ] [ text (fromInt (scoreForPlayer player)) ]


viewTotal : Model -> List (Html Msg)
viewTotal model =
    [ div [ class "row info-row total-row" ]
        ([ div [ class "number-column", onClick ToggleSettingsMode ]
            [ img [ src "%PUBLIC_URL%/images/settings.png", SvgAttr.height "90%" ] [] ]
         ]
            ++ List.map (\player -> viewPlayerTotal model player) model.players
        )
    ]


viewBoard : Model -> Html Msg
viewBoard model =
    div
        [ class "wrapper" ]
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

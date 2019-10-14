module Routes exposing (Route(..), fromUrl, replaceUrl, routeToConfig)

import Browser.Navigation as Nav
import Url exposing (Url)
import Url.Parser as Parser exposing (Parser)


type Route
    = Cricket


routes : Parser (Route -> a) a
routes =
    Parser.oneOf
        [ Parser.map Cricket Parser.top
        ]



-- EXTERNAL


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse routes url


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl navKey route =
    Nav.replaceUrl navKey (routeToString route)



-- INTERNAL


routeToConfig : Route -> String
routeToConfig route =
    case route of
        Cricket ->
            "cricket"


routeToString : Route -> String
routeToString route =
    let
        pieces =
            case route of
                Cricket ->
                    []
    in
        "#/" ++ String.join "/" pieces

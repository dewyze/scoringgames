module Routes exposing (Route(..), fromUrl, replaceUrl, routeToConfig, href)

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Url exposing (Url)
import Url.Parser as Parser exposing (Parser)


type Route
    = Cricket
    | Home


routes : Parser (Route -> a) a
routes =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map Cricket (Parser.s "cricket")
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

        Home ->
            ""


routeToString : Route -> String
routeToString route =
    let
        pieces =
            case route of
                Cricket ->
                    [ "cricket" ]

                Home ->
                    []
    in
        String.join "/" pieces



-- VIEW


href : Route -> Attribute msg
href targetRoute =
    Attr.href (routeToString targetRoute)

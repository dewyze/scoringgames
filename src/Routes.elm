module Routes exposing (Route(..), fromUrl)

import Browser.Navigation as Nav
import Url exposing (Url)
import Url.Parser as Parser exposing (Parser)


type Route
    = Home


routes : Parser (Route -> a) a
routes =
    Parser.oneOf
        [ Parser.map Home Parser.top
        ]



-- EXTERNAL


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse routes url


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl navKey route =
    Nav.replaceUrl navKey (routeToString route)



-- INTERNAL


routeToString : Route -> String
routeToString route =
    let
        pieces =
            case route of
                Home ->
                    []
    in
    "#/" ++ String.join "/" pieces

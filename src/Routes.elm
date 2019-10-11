module Routes exposing (Route(..))

import Url exposing (Url)
import Url.Parser as Parser exposing (Parser)


type Route
    = Home
    | Cricket
    | MiniGolf


routes : Parser (Route -> a) a
routes =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map Cricket (Parser.s "cricket")
        , Parser.map MiniGolf (Parser.s "minigolf")
        ]


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse routes url

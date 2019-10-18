module Session exposing (..)

import Browser.Navigation as Nav


type alias Session =
    { navKey : Nav.Key
    , windowHeight : Int
    }


init : Nav.Key -> Int -> Session
init key height =
    { navKey = key
    , windowHeight = height
    }

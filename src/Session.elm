module Session exposing (..)

import Browser.Navigation as Nav


type alias Session =
    { navKey : Nav.Key
    , id : String
    }


init : Nav.Key -> Session
init key =
    { navKey = key
    , id = "123"
    }

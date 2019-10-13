module Session exposing (..)

import Browser.Navigation as Nav


type alias Session =
    { navKey : Nav.Key
    }


init : Nav.Key -> Session
init key =
    { navKey = key
    }

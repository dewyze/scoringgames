port module Ports exposing (configs, storage)

import Json.Decode as Decode
import Json.Encode as Encode


port storage : Encode.Value -> Cmd msg


port configs : (Decode.Value -> msg) -> Sub msg

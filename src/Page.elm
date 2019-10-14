module Page exposing (Page(..), view)

import Browser exposing (Document)
import Html exposing (..)
import Html.Attributes exposing (..)


type Page
    = Cricket
    | Home
    | Other


view : Page -> { title : String, content : Html msg } -> Document msg
view page { title, content } =
    { title = title
    , body = [ div [ id "main" ] [ content ] ]
    }

module Main exposing (main)

import Browser exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)


type alias Model =
    {}


type Msg
    = Nothing


type alias Flags =
    ()


main : Program Flags Model Msg
main =
    document
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( {}, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update _ _ =
    ( {}, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Document Msg
view _ =
    { title = "Darrin Eden"
    , body =
        [ div []
            [ h1 [] [ text "Hi There, Nice to meet you." ]
            , p [] [ text "Want to know more about me? Here are some places to connect:" ]
            , ul []
                [ li [] [ a [ href "https://twitter.com/DarrinEden" ] [ text "Twitter" ] ]
                , li [] [ a [ href "https://www.linkedin.com/in/darrin-eden-99b65719b/" ] [ text "LinkedIn" ] ]
                , li [] [ a [ href "https://storage.googleapis.com/darrineden/Darrin-Eden-Resume.pdf" ] [ text "Résumé" ] ]
                , li [] [ a [ href "https://www.instagram.com/darrin.eden/" ] [ text "Instagram" ] ]
                , li [] [ a [ href "mailto:darrin.eden@gmail.com" ] [ text "darrin.eden@gmail.com" ] ]
                , li [] [ a [ href "https://github.com/dje" ] [ text "GitHub" ] ]
                ]
            , p [] [ text "Thanks for visiting!" ]
            , p []
                [ text "Sincerely,"
                , br [] []
                , text "Darrin"
                ]
            , p [] [ text "Last update: 2020/01/23" ]
            ]
        ]
    }

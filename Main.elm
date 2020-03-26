module Main exposing (main)

import Browser exposing (Document, document)
import Html exposing (..)
import Html.Attributes exposing (..)
import Url.Builder exposing (absolute, crossOrigin)


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
                [ li []
                    [ a
                        [ href
                            (crossOrigin "https://twitter.com" [ "DarrinEden" ] [])
                        ]
                        [ text "Twitter" ]
                    ]
                , li []
                    [ a
                        [ href
                            (crossOrigin "https://www.linkedin.com" [ "in", "darrin-eden" ] [])
                        ]
                        [ text "LinkedIn" ]
                    ]
                , li []
                    [ a [ href (absolute [ "resume" ] []) ]
                        [ text "Résumé (word)" ]
                    , text " "
                    , a
                        [ href
                            (crossOrigin "https://storage.googleapis.com"
                                [ "darrineden", "Darrin_Eden_Resume.pdf" ]
                                []
                            )
                        ]
                        [ text "(pdf)" ]
                    ]
                , li []
                    [ a
                        [ href
                            (crossOrigin "https://www.instagram.com" [ "darrin.eden" ] [])
                        ]
                        [ text "Instagram" ]
                    ]
                , li []
                    [ a
                        [ href
                            (crossOrigin "https://github.com" [ "dje" ] [])
                        ]
                        [ text "GitHub" ]
                    ]
                ]
            , p [] [ text "Thanks for visiting!" ]
            , p []
                [ text "Sincerely,"
                , br [] []
                , text "Darrin"
                ]
            , p [] [ text "Last update: March 16, 2020" ]
            ]
        ]
    }

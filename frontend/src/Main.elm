module Main exposing (main)

import Browser
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Encode as JE


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


type alias Model =
    { email : String
    , password : String
    }


init : () -> ( Model, Cmd msg )
init _ =
    let
        model =
            { email = "user@example.com"
            , password = "letmein"
            }

        cmd =
            Cmd.none
    in
    ( model, cmd )


type Msg
    = GotEmail String
    | GotPassword String
    | FormSubmitted
    | GotLoginResponse (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotEmail s ->
            ( { model | email = s }, Cmd.none )

        GotPassword s ->
            ( { model | password = s }, Cmd.none )

        FormSubmitted ->
            ( model, login model.email model.password )

        GotLoginResponse res ->
            let
                _ =
                    Debug.log "response" res
            in
            ( model, Cmd.none )


apiOrigin : String
apiOrigin =
    "http://localhost:3000"


login : String -> String -> Cmd Msg
login email password =
    let
        body =
            JE.object
                [ ( "email", JE.string email )
                , ( "password", JE.string password )
                ]
    in
    Http.request
        { method = "POST"
        , headers = []
        , url = apiOrigin ++ "/login"
        , body = Http.jsonBody body
        , expect = Http.expectString GotLoginResponse
        , timeout = Nothing
        , tracker = Nothing
        }


view : Model -> Html Msg
view model =
    H.div []
        [ H.h1 [] [ H.text "Yak" ]
        , H.form [ HE.onSubmit FormSubmitted ]
            [ H.div []
                [ H.label [] [ H.text "Email" ]
                , H.input
                    [ HA.type_ "email", HA.value model.email ]
                    []
                ]
            , H.div []
                [ H.label [] [ H.text "Password" ]
                , H.input
                    [ HA.type_ "password", HA.value model.password ]
                    []
                ]
            , H.div []
                [ H.button
                    []
                    [ H.text "login" ]
                ]
            ]
        ]

port module State exposing (init, update, subscriptions)

import Rest exposing (..)
import Types exposing (..)
import Board.Types exposing (..)
import Game.Types exposing (..)
import Player.Types as Player exposing (Player)
import Date
import Dict exposing (Dict)
import Json.Decode as JD
import Json.Encode as JE
import Task


initialModel : Model
initialModel =
    { game = Nothing
    , boardSize = BoardSize 3 3
    , localPlayer = Nothing
    , playerForm = Player.defaultForm
    , openGames = Dict.empty
    , runningGames = Dict.empty
    }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RegisterLocalPlayer ->
            let
                form =
                    model.playerForm

                playerForm =
                    { form | errors = Player.validateForm form }

                newModel =
                    { model | playerForm = playerForm }
            in
                case Player.extractFromForm playerForm of
                    Just player ->
                        ( newModel, registerLocalPlayer player )

                    Nothing ->
                        ( newModel, Cmd.none )

        LocalPlayerRegistered localPlayer ->
            ( { model | localPlayer = Just localPlayer }, Cmd.none )

        InputPlayerName name ->
            let
                form =
                    model.playerForm

                newForm =
                    { form | name = name }

                withErrors =
                    { newForm | errors = Player.validateForm newForm }
            in
                ( { model | playerForm = withErrors }, Cmd.none )

        InputWidth width ->
            ( { model | boardSize = updateWidth width model.boardSize }, Cmd.none )

        InputHeight height ->
            ( { model | boardSize = updateHeight height model.boardSize }, Cmd.none )

        CreateGame ->
            case model.localPlayer of
                Just localPlayer ->
                    ( model
                    , Date.now
                        |> Task.perform (OpenGame localPlayer)
                    )

                _ ->
                    ( model, Cmd.none )

        OpenGame localPlayer openedAt ->
            let
                game =
                    buildGame localPlayer model.boardSize openedAt
            in
                ( { model | game = Just game }
                , game
                    |> gameEncoder
                    |> openGame
                )

        StartGame ->
            case ( model.game, model.localPlayer ) of
                ( Just game, Just localPlayer ) ->
                    let
                        _ =
                            Debug.log "union" (Dict.union game.joinRequests game.spectators)
                    in
                        if game.owner == localPlayer then
                            ( model
                            , { game
                                | status = Running
                                , spectators = Dict.union game.joinRequests game.spectators
                                , joinRequests = Dict.empty
                              }
                                |> gameEncoder
                                |> changeGame
                            )
                        else
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Select line ->
            case ( model.localPlayer, model.game ) of
                ( Just localPlayer, Just game ) ->
                    if lineCanNotBeSelected line localPlayer game then
                        ( model, Cmd.none )
                    else
                        ( model
                        , game
                            |> selectLine line
                            |> gameEncoder
                            |> changeGame
                        )

                _ ->
                    ( model, Cmd.none )

        GameChanged value ->
            case JD.decodeValue gameDecoder value of
                Ok game ->
                    case model.game of
                        Nothing ->
                            ( model, Cmd.none )

                        Just ownGame ->
                            if ownGame.id == game.id then
                                ( { model | game = Just game }, Cmd.none )
                            else
                                ( model, Cmd.none )

                Err err ->
                    let
                        _ =
                            Debug.crash err
                    in
                        ( model, Cmd.none )

        GameOpened gameId ->
            case model.game of
                Nothing ->
                    ( model, Cmd.none )

                Just game ->
                    let
                        newGame =
                            { game | id = gameId }
                    in
                        ( { model | game = Just newGame }, Cmd.none )

        OpenGameAdded value ->
            case JD.decodeValue gameDecoder value of
                Ok game ->
                    ( { model | openGames = Dict.insert game.id game model.openGames }
                    , Cmd.none
                    )

                Err err ->
                    let
                        _ =
                            Debug.log "OpenGameAdded Error: " err
                    in
                        ( model, Cmd.none )

        OpenGameRemoved gameId ->
            ( { model | openGames = Dict.remove gameId model.openGames }
            , Cmd.none
            )

        RunningGameAdded value ->
            case JD.decodeValue gameDecoder value of
                Ok game ->
                    ( { model | runningGames = Dict.insert game.id game model.runningGames }
                    , Cmd.none
                    )

                Err err ->
                    let
                        _ =
                            Debug.log "OpenGameAdded Error: " err
                    in
                        ( model, Cmd.none )

        RunningGameRemoved gameId ->
            ( { model | runningGames = Dict.remove gameId model.runningGames }
            , Cmd.none
            )

        RequestToJoinGame game ->
            case model.localPlayer of
                Nothing ->
                    ( model, Cmd.none )

                Just player ->
                    ( { model | game = Just game }
                    , JoinGameRequest game.id player
                        |> requestToJoinGame
                    )

        WatchGame game ->
            case model.localPlayer of
                Nothing ->
                    ( model, Cmd.none )

                Just player ->
                    ( { model | game = Just game }
                    , JoinGameRequest game.id player
                        |> watchGame
                    )

        AcceptPlayer joinGameRequestEntry ->
            case ( model.game, model.localPlayer ) of
                ( Just game, Just localPlayer ) ->
                    if game.owner == localPlayer then
                        ( model
                        , addNewPlayerToGame joinGameRequestEntry game
                            |> gameEncoder
                            |> changeGame
                        )
                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        BackToLobby ->
            ( { model | game = Nothing }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ gameOpened GameOpened
        , gameChanged GameChanged
        , localPlayerRegistered LocalPlayerRegistered
        , openGameAdded OpenGameAdded
        , openGameRemoved OpenGameRemoved
        , localPlayerRegistered LocalPlayerRegistered
        , openGameAdded OpenGameAdded
        , openGameRemoved OpenGameRemoved
        , runningGameAdded RunningGameAdded
        , runningGameRemoved RunningGameRemoved
        ]


port requestToJoinGame : JoinGameRequest -> Cmd msg


port watchGame : JoinGameRequest -> Cmd msg


port openGame : JE.Value -> Cmd msg


port changeGame : JE.Value -> Cmd msg


port gameOpened : (String -> msg) -> Sub msg


port gameChanged : (JD.Value -> msg) -> Sub msg


port registerLocalPlayer : Player -> Cmd msg


port localPlayerRegistered : (Player -> msg) -> Sub msg


port openGameAdded : (JD.Value -> msg) -> Sub msg


port openGameRemoved : (GameId -> msg) -> Sub msg


port runningGameAdded : (JD.Value -> msg) -> Sub msg


port runningGameRemoved : (GameId -> msg) -> Sub msg

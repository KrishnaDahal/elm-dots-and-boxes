port module App.State exposing (init, update, subscriptions)

import App.Types exposing (..)
import Dict exposing (Dict)
import Json.Decode as JD
import Json.Encode as JE
import Form.Validation exposing (..)
import App.Rest exposing (..)


initialModel : Model
initialModel =
    { game = Nothing
    , playerName = ""
    , gameForm = defaultGameForm
    }



-- , playerInCurrentGame = Nothing


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputWidth width ->
            let
                form =
                    model.gameForm

                newGameForm =
                    { form
                        | width = width
                        , errors = validateGameForm form
                    }
            in
                ( { model | gameForm = newGameForm }, Cmd.none )

        InputHeight height ->
            let
                form =
                    model.gameForm

                newGameForm =
                    { form
                        | height = height
                        , errors = validateGameForm form
                    }
            in
                ( { model | gameForm = newGameForm }, Cmd.none )

        OpenGame ->
            let
                form =
                    model.gameForm

                gameForm =
                    { form | errors = validateGameForm form }
            in
                case extractBoardSizeFromForm gameForm of
                    Just boardSize ->
                        let
                            game =
                                buildGame boardSize
                        in
                            ( { model | game = Just game, gameForm = gameForm }
                            , openGame <| gameEncoder game
                            )

                    Nothing ->
                        ( { model | gameForm = gameForm }, Cmd.none )

        StartGame ->
            case model.game of
                Nothing ->
                    ( model, Cmd.none )

                Just game ->
                    ( model, changeGame <| gameEncoder { game | status = Running } )

        Select line ->
            case model.game of
                Nothing ->
                    ( model, Cmd.none )

                Just game ->
                    let
                        lineCanNotBeSelected =
                            (game.status /= Running) || (Dict.member line game.selectedLines)
                    in
                        if lineCanNotBeSelected then
                            ( model, Cmd.none )
                        else
                            let
                                selectedLines =
                                    Dict.insert line game.currentPlayer game.selectedLines

                                newBoxes =
                                    updateBoxes game.currentPlayer selectedLines game.boxes

                                newGame =
                                    proceedGame
                                        { game
                                            | boxes = newBoxes
                                            , selectedLines = selectedLines
                                        }
                            in
                                ( model, changeGame <| gameEncoder newGame )

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

        JoinGame gameId ->
            ( model, Cmd.none )


buildGame : BoardSize -> Game
buildGame boardSize =
    { id = ""
    , playerNames = [ "Roman", "Lena" ]
    , boardSize = boardSize
    , boxes = buildBoxes boardSize
    , selectedLines = Dict.empty
    , status = Open
    , currentPlayer = Player1
    , playerPoints = ( 0, 0 )
    }


buildBoxes : BoardSize -> Boxes
buildBoxes { width, height } =
    rows (List.range 0 (height - 1)) (List.range 0 (width - 1))


rows : List Int -> List Int -> List Box
rows ys xs =
    List.foldr (\y boxes -> row y xs ++ boxes) [] ys


row : Int -> List Int -> List Box
row y xs =
    List.foldr (\x boxes -> (buildBox x y) :: boxes) [] xs


buildBox : Int -> Int -> Box
buildBox x y =
    Box
        ( ( x, y )
        , ( x + 1, y )
        )
        ( ( x, y + 1 )
        , ( x + 1, y + 1 )
        )
        ( ( x, y )
        , ( x, y + 1 )
        )
        ( ( x + 1, y )
        , ( x + 1, y + 1 )
        )
        Nothing


updateBoxes : Player -> SelectedLines -> Boxes -> Boxes
updateBoxes player paths boxes =
    List.map (updateBox player paths) boxes


updateBox : Player -> SelectedLines -> Box -> Box
updateBox player selectedLines box =
    case box.doneBy of
        Just _ ->
            box

        Nothing ->
            let
                doneBy =
                    if boxIsDone box selectedLines then
                        Just player
                    else
                        Nothing
            in
                { box | doneBy = doneBy }


proceedGame : Game -> Game
proceedGame game =
    case game.status of
        Open ->
            game

        Winner player ->
            game

        Draw ->
            game

        Running ->
            let
                newPlayerPoints =
                    calculatePlayerPoints game.boxes
            in
                if gameHasFinished game.boxes then
                    { game
                        | status = getWinner newPlayerPoints
                        , playerPoints = newPlayerPoints
                    }
                else if playerHasFinishedBox newPlayerPoints game.playerPoints then
                    { game
                        | playerPoints = newPlayerPoints
                    }
                else
                    { game
                        | currentPlayer = switchPlayers game.currentPlayer
                        , playerPoints = newPlayerPoints
                    }


calculatePlayerPoints : Boxes -> PlayerPoints
calculatePlayerPoints boxes =
    List.foldl
        (\box ( player1Points, player2Points ) ->
            case box.doneBy of
                Nothing ->
                    ( player1Points, player2Points )

                Just player ->
                    if player == Player1 then
                        ( player1Points + 1, player2Points )
                    else
                        ( player1Points, player2Points + 1 )
        )
        ( 0, 0 )
        boxes


gameHasFinished : Boxes -> Bool
gameHasFinished boxes =
    List.isEmpty <| List.filter (\box -> box.doneBy == Nothing) boxes


playerHasFinishedBox : PlayerPoints -> PlayerPoints -> Bool
playerHasFinishedBox newPoints oldPoints =
    newPoints /= oldPoints


getWinner : PlayerPoints -> GameStatus
getWinner playerPoints =
    if Tuple.first playerPoints > Tuple.second playerPoints then
        Winner Player1
    else if Tuple.second playerPoints > Tuple.first playerPoints then
        Winner Player2
    else
        Draw


switchPlayers : Player -> Player
switchPlayers currentPlayer =
    if currentPlayer == Player1 then
        Player2
    else
        Player1


boxIsDone : Box -> SelectedLines -> Bool
boxIsDone box selectedLines =
    Dict.member box.up selectedLines
        && Dict.member box.down selectedLines
        && Dict.member box.left selectedLines
        && Dict.member box.right selectedLines


validateGameForm : GameForm -> List Error
validateGameForm form =
    begin form
        |> validate (validateInt "width" << .width)
        |> validate (validateInt "height" << .width)
        |> extractErrors


extractBoardSizeFromForm : GameForm -> Maybe BoardSize
extractBoardSizeFromForm form =
    Result.map2 BoardSize
        (String.toInt form.width)
        (String.toInt form.height)
        |> Result.toMaybe



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ gameOpened GameOpened
        , gameChanged GameChanged
        ]


port openGame : JE.Value -> Cmd msg


port changeGame : JE.Value -> Cmd msg


port gameOpened : (String -> msg) -> Sub msg


port gameChanged : (JD.Value -> msg) -> Sub msg

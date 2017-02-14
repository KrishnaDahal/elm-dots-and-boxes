module App.Types exposing (..)

import Date
import Dict exposing (Dict)
import Form.Validation exposing (..)
import Json.Decode as JD


type alias Model =
    { game : Maybe Game
    , boardSize : BoardSize
    , localPlayer : Maybe Player
    , playerForm : PlayerForm
    , openGames : Dict GameId Game
    , runningGames : Dict GameId Game
    }


type alias Boxes =
    List Box


type alias Coordinate =
    Int


{-| Can not be a union type because I need it as a key in a Dict
-}
type alias Point =
    ( Coordinate, Coordinate )


{-| Can not be a union type because I need it as a key in a Dict
-}
type alias Line =
    ( Point, Point )


type alias Box =
    { up : Line
    , down : Line
    , left : Line
    , right : Line
    , doneBy : Maybe PlayerStatus
    }


type alias BoardSize =
    { width : Int
    , height : Int
    }


updateWidth : Int -> BoardSize -> BoardSize
updateWidth newWidth { width, height } =
    BoardSize newWidth height


updateHeight : Int -> BoardSize -> BoardSize
updateHeight newHeight { width, height } =
    BoardSize width newHeight



{-

    Ich muss unterscheiden zwischen: Spiel wurde erstellt und gestartet.
    Bei einem erstellten Spiel können sich noch andere Leute verbinden.


    Man eröffnet ein Spiel, damit hört man nur noch auf Änderungen an diesem Spiel

    Wenn man teilnimmt ebenso

    Wie handele ich Join Requests?
    Ich kann nicht einfach das Game ändern, da dies zu Race Conditions führen kann

    vllt könnte ich einfach eine neue Liste mit Join Requests bauen?
    und der Owner kann dann mit dieser arbeiten

    könnte man vllt nicht das ganze Game ändern (also auch serialisieren?), sondern
    nur an join requests pushen? ich sollte ja trotzdem das change event überall bekommen?!?

    Wenn ich ein game join, muss dieses game direkt das game werden

    sollte man die JoinRequest auch als Dict machen?

    Wenn dies geht könnte man doch wieder "eine" Player Liste machen
    in dieser Liste steht dann mein status

    Wie komme ich an den nächsten Spieler?

    irgendwie muss ich wissen, welches der nächste Spieler nach einem Zug ist
    Idealerweise bekomme ich eine PlayerId, welche ich dann nehmen kann, um auf
    das Players Dict zugreifen zu können

    Players =
     { previous : List PlayerInGame
     , current: PlayerInGame
     , next: List PlayerInGame
   }

   wenn next leer ist fange wieder vorne an

-}


type alias PlayerId =
    String


type alias Player =
    { id : PlayerId
    , name : String
    }


type alias PlayerForm =
    { name : String
    , errors : List Error
    }


defaultPlayerForm : PlayerForm
defaultPlayerForm =
    PlayerForm "" []


type alias SelectedLines =
    Dict Line PlayerStatus


type alias Game =
    { id : GameId
    , owner : Player
    , createdAt : Date.Date
    , boardSize : BoardSize
    , boxes : Boxes
    , selectedLines : SelectedLines
    , status : GameStatus
    , result : GameResult
    , players : PlayersInGame
    , availablePlayerStatus : List PlayerStatus
    , joinRequests : Dict JoinGameRequestId Player
    , spectators : Dict JoinGameRequestId Player
    }


type alias GameId =
    String


type GameStatus
    = Open
    | Running
    | Finished


type GameResult
    = None
    | Winner PlayerInGame
    | Draw (List PlayerInGame)


type PlayerStatus
    = Player1
    | Player2


type alias PlayerPoints =
    Int


type alias Players =
    Dict PlayerId PlayerInGame


type PlayerInGame
    = PlayerInGame
        { player : Player
        , status : PlayerStatus
        , points : PlayerPoints
        }


createPlayerInGame : Player -> PlayerStatus -> PlayerPoints -> PlayerInGame
createPlayerInGame player status points =
    PlayerInGame { player = player, status = status, points = points }


type PlayersInGame
    = PlayersInGame
        { previous : List PlayerInGame
        , current : PlayerInGame
        , next : List PlayerInGame
        }


createPlayersInGame : List PlayerInGame -> PlayerInGame -> List PlayerInGame -> PlayersInGame
createPlayersInGame previous current next =
    PlayersInGame { previous = previous, current = current, next = next }


getCurrentPlayer : PlayersInGame -> PlayerInGame
getCurrentPlayer (PlayersInGame { current }) =
    current


updateCurrentPlayer : PlayersInGame -> PlayerInGame -> PlayersInGame
updateCurrentPlayer (PlayersInGame { previous, next }) newCurrent =
    createPlayersInGame previous newCurrent next


addPlayer : PlayersInGame -> PlayerInGame -> PlayersInGame
addPlayer (PlayersInGame { previous, current, next }) player =
    let
        newNext =
            next
                |> List.reverse
                |> (::) player
                |> List.reverse
    in
        createPlayersInGame previous current newNext


playerIsPlayerInGame : Player -> PlayersInGame -> Bool
playerIsPlayerInGame player (PlayersInGame { previous, current, next }) =
    previous
        |> (::) current
        |> (++) next
        |> List.map (\(PlayerInGame playerInGame) -> playerInGame.player)
        |> List.member player


numberPlayers : PlayersInGame -> Int
numberPlayers (PlayersInGame { previous, current, next }) =
    previous
        |> (::) current
        |> (++) next
        |> List.length


playerListSortedByPlayerPoints : PlayersInGame -> List PlayerInGame
playerListSortedByPlayerPoints (PlayersInGame { previous, current, next }) =
    previous
        |> (::) current
        |> (++) next
        |> List.sortWith comparePlayerPoints
        |> List.reverse


getWinner : PlayersInGame -> List PlayerInGame
getWinner (PlayersInGame { previous, current, next }) =
    let
        getPlayersWithHighestPoints : PlayerInGame -> List PlayerInGame -> List PlayerInGame
        getPlayersWithHighestPoints player list =
            case list of
                topPlayer :: tail ->
                    case comparePlayerPoints player topPlayer of
                        EQ ->
                            player :: list

                        LT ->
                            list

                        GT ->
                            [ player ]

                [] ->
                    [ player ]
    in
        previous
            |> (++) next
            |> getPlayersWithHighestPoints current


comparePlayerPoints : PlayerInGame -> PlayerInGame -> Order
comparePlayerPoints (PlayerInGame playerA) (PlayerInGame playerB) =
    compare playerA.points playerB.points


type alias JoinGameRequestId =
    String


type alias JoinGameRequestEntry =
    ( JoinGameRequestId, Player )


type alias JoinGameRequest =
    { gameId : GameId
    , player : Player
    }


type Msg
    = RegisterLocalPlayer
    | InputPlayerName String
    | LocalPlayerRegistered Player
    | CreateGame
    | OpenGame Player Date.Date
    | StartGame
    | RequestToJoinGame Game
    | WatchGame Game
    | AcceptPlayer JoinGameRequestEntry
    | GameOpened String
    | GameChanged JD.Value
    | Select Line
    | InputWidth Int
    | InputHeight Int
    | OpenGameAdded JD.Value
    | OpenGameRemoved GameId
    | RunningGameAdded JD.Value
    | RunningGameRemoved GameId
    | BackToLobby

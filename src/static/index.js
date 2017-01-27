import "babel-polyfill";
import "./styles/app.css";
import "./styles/bulma.css";
import "font-awesome-webpack";

import {
    games
} from "./firebase";

const Elm = require('../elm/Main');
const app = Elm.Main.embed(document.getElementById('main'));

let gameId;

app.ports.startGame.subscribe(game => {
    console.log(game)
    games.start(game)
        .then(function(val) {
            console.log(val.key)
        })
        .catch(err => {
            console.error("startGame error:", err);
        });
});


games.ref.on("child_added", data => {
    const game = Object.assign({}, data.val(), {
        id: data.key
    });
    gameId = data.key;
    console.log(game);
    app.ports.gameStarted.send(game);
});
// members.ref.on("child_changed", data => {
//     const member = Object.assign({}, data.val(), {
//         id: data.key
//     });
//     app.ports.memberUpdated.send(member);
// });

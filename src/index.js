import "./main.css";
import { Elm } from "./Main.elm";
import * as serviceWorker from "./serviceWorker";

// var config = localStorage.getItem("config");
// config = { message: "Success!", click: 0 };
var app = Elm.Main.init({
  // flags: config,
  node: document.getElementById("root")
});
app.ports.storage.subscribe(function(data) {
  if (data.method == "get") {
    var appConfig = localStorage.getItem(data.app) || {};
    app.ports.configs.send(appConfig);
    document.getElementById("main").style.height = window.innerHeight + "px";
  } else if (data.method == "set") {
    localStorage.setItem(data.app, JSON.stringify(data.config));
  } else if (data.method == "clear") {
    localStorage.removeItem(data.app);
  }
});

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();

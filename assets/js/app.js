// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"

import React from 'react';
import ReactDOM from 'react-dom';
import { Provider } from 'react-redux';
import { Route, Switch, Router } from 'react-router-dom';
import MagicApp from './MagicApp.jsx';
import MagicSocialCallback from './components/auth/MagicSocialCallback';
import Terms from './components/auth/Terms';
import { history, store } from './store/configureStore'
import AppCss from "../css/app.css";

ReactDOM.render(
  <Router history={history}>
    <Switch>
      <Route exact path="/terms"><Terms/></Route>
      <Route path="/callback" component={MagicSocialCallback} />
      <Provider store={store}>
        {
          history.location.pathname !== "/callback" && <MagicApp />
        }
      </Provider>
    </Switch>
  </Router>,
  document.getElementById("react-root")
)

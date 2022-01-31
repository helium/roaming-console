import React, { Component } from "react";
import { withRouter, NavLink } from "react-router-dom";
import { Typography } from "antd";
import Caret from "../../../img/menu-caret.svg";
const { Text } = Typography;

class NavDrawer extends Component {
  render() {
    const { history } = this.props;
    return (
      <div
        style={{
          backgroundColor: "#F5F7F9",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          alignItems: "flex-end",
          paddingRight: 40,
        }}
      >
        <div style={{ position: "relative" }}>
          <NavLink
            draggable="false"
            to={"/dashboard"}
            activeClassName="is-active"
            className="menu-link"
          >
            Dashboard
          </NavLink>
          {history.location.pathname === "/dashboard" && (
            <img
              draggable="false"
              src={Caret}
              style={{ right: -16, position: "absolute", top: 8, height: 12 }}
            />
          )}
        </div>
        <div style={{ position: "relative" }}>
          <NavLink
            draggable="false"
            to={"/configuration"}
            activeClassName="is-active"
            className="menu-link"
          >
            Configuration
          </NavLink>
          {history.location.pathname === "/configuration" && (
            <img
              draggable="false"
              src={Caret}
              style={{ right: -16, position: "absolute", top: 8, height: 12 }}
            />
          )}
        </div>
        <div style={{ position: "relative" }}>
          <NavLink
            draggable="false"
            to={"/datacredits"}
            activeClassName="is-active"
            className="menu-link"
          >
            Data Credits
          </NavLink>
          {history.location.pathname === "/datacredits" && (
            <img
              draggable="false"
              src={Caret}
              style={{ right: -16, position: "absolute", top: 8, height: 12 }}
            />
          )}
        </div>
        <div style={{ position: "relative" }}>
          <NavLink
            draggable="false"
            to={"/organizations"}
            activeClassName="is-active"
            className="menu-link"
          >
            Organizations
          </NavLink>
          {history.location.pathname === "/organizations" && (
            <img
              draggable="false"
              src={Caret}
              style={{ right: -16, position: "absolute", top: 8, height: 12 }}
            />
          )}
        </div>
        <div style={{ position: "relative" }}>
          <NavLink
            draggable="false"
            to={"/users"}
            activeClassName="is-active"
            className="menu-link"
          >
            Users
          </NavLink>
          {history.location.pathname === "/users" && (
            <img
              draggable="false"
              src={Caret}
              style={{ right: -16, position: "absolute", top: 8, height: 12 }}
            />
          )}
        </div>
        <div style={{ position: "relative" }}>
          <NavLink
            draggable="false"
            to={"/alerts"}
            activeClassName="is-active"
            className="menu-link"
          >
            Alerts
          </NavLink>
          {history.location.pathname === "/alerts" && (
            <img
              draggable="false"
              src={Caret}
              style={{ right: -16, position: "absolute", top: 8, height: 12 }}
            />
          )}
        </div>
      </div>
    );
  }
}

export default withRouter(NavDrawer);

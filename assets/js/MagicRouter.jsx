import React, { useEffect } from "react";
import { bindActionCreators } from "redux";
import { Spin } from "antd";
import { ApolloProvider } from "@apollo/client";
import { history } from "./store/configureStore";
import { fetchOrganization } from "./actions/organization";
import { setupApolloClient } from "./actions/apollo";
import { getMagicSessionToken } from "./actions/magic";

// Routes
import { connect } from "react-redux";
import { ConnectedRouter } from "connected-react-router";
import { Redirect } from "react-router";
import { Route, Switch } from "react-router-dom";
import JoinOrganizationPrompt from "./components/auth/JoinOrganizationPrompt.jsx";
import Profile from "./components/profile/Profile.jsx";
import UserIndex from "./components/organizations/UserIndex";
import OrganizationIndex from "./components/organizations/OrganizationIndex";
import DataCreditsIndex from "./components/billing/DataCreditsIndex";
import NoOrganization from "./components/organizations/NoOrganization";
import DashboardIndex from "./components/dashboard/DashboardIndex";
import AlertsIndex from "./components/alerts/AlertsIndex";
import ConfigurationIndex from "./components/configuration/ConfigurationIndex";

const MagicRouter = (props) => {
  const {
    currentOrganizationId,
    loadedOrganization,
    loadingOrganization,
    fetchOrganization,
    setupApolloClient,
    apolloClient,
    user,
  } = props;

  useEffect(() => {
    if (!currentOrganizationId && !loadingOrganization && !loadedOrganization) {
      fetchOrganization();
      return;
    } else if (!apolloClient && currentOrganizationId) {
      setupApolloClient(getMagicSessionToken, currentOrganizationId);
      return;
    }
  }, [currentOrganizationId, loadingOrganization, loadedOrganization, user]);

  const redirectPath = "dashboard";

  if (
    loadingOrganization ||
    (loadedOrganization && currentOrganizationId && !apolloClient)
  )
    return (
      <div
        style={{
          height: "100vh",
          width: "100vw",
          display: "flex",
          flexDirection: "row",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <Spin size="large" />
      </div>
    );

  return (
    <ConnectedRouter history={history}>
      <Switch>
        <Redirect exact from="/" to={redirectPath} />
        <Route
          path="/join_organization"
          loaded={loadedOrganization}
          component={(props) => (
            <JoinOrganizationPrompt user={user} {...props} />
          )}
        />
        <Route>
          {loadedOrganization && !currentOrganizationId && (
            <NoOrganization user={user} />
          )}
          {currentOrganizationId && apolloClient && (
            <ApolloProvider client={apolloClient}>
              <Switch>
                <Route
                  exact
                  path="/dashboard"
                  component={(props) => (
                    <DashboardIndex user={user} {...props} />
                  )}
                />
                <Route
                  exact
                  path="/configuration"
                  component={(props) => (
                    <ConfigurationIndex user={user} {...props} />
                  )}
                />
                <Route
                  exact
                  path="/users"
                  component={(props) => <UserIndex user={user} {...props} />}
                />
                <Route
                  exact
                  path="/datacredits"
                  component={(props) => (
                    <DataCreditsIndex user={user} {...props} />
                  )}
                />
                <Route
                  exact
                  path="/organizations"
                  component={(props) => (
                    <OrganizationIndex user={user} {...props} />
                  )}
                />
                <Route
                  exact
                  path="/alerts"
                  component={(props) => <AlertsIndex user={user} {...props} />}
                />
                <Route
                  path="/profile"
                  component={(props) => <Profile user={user} {...props} />}
                />
              </Switch>
            </ApolloProvider>
          )}
        </Route>
      </Switch>
    </ConnectedRouter>
  );
};

function mapStateToProps(state, ownProps) {
  return {
    currentOrganizationId: state.organization.currentOrganizationId,
    loadedOrganization: state.organization.loadedOrganization,
    loadingOrganization: state.organization.loadingOrganization,
    apolloClient: state.apollo.apolloClient,
  };
}

function mapDispatchToProps(dispatch) {
  return bindActionCreators(
    {
      fetchOrganization,
      setupApolloClient,
    },
    dispatch
  );
}

export default connect(mapStateToProps, mapDispatchToProps)(MagicRouter);

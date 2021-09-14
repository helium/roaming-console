import React, { useEffect } from "react";
import { bindActionCreators } from "redux";
import { PersistGate } from "redux-persist/lib/integration/react";
import { Spin } from "antd";
import { ApolloProvider } from "@apollo/client";
import { persistor, history } from "./store/configureStore";
import { fetchOrganization } from "./actions/organization";
import { setupApolloClient } from "./actions/apollo";
import { useAuth0 } from "./components/auth/Auth0Provider";

// Routes
import { connect } from "react-redux";
import { ConnectedRouter } from "connected-react-router";
import { Redirect } from "react-router";
import { Route, Switch } from "react-router-dom";
import PublicRoute from "./components/routes/PublicRoute.jsx";
import JoinOrganizationPrompt from "./components/auth/JoinOrganizationPrompt.jsx";
import Profile from "./components/profile/Profile.jsx";
import UserIndex from "./components/organizations/UserIndex";
import OrganizationIndex from "./components/organizations/OrganizationIndex";
import DataCreditsIndex from "./components/billing/DataCreditsIndex";
import AlertsIndex from "./components/alerts/AlertsIndex";
import NoOrganization from "./components/organizations/NoOrganization";
import ConfirmEmailPrompt from "./components/auth/ConfirmEmailPrompt";

const Router = (props) => {
  const {
    loading,
    isAuthenticated,
    loginWithRedirect,
    getIdTokenClaims,
    user,
  } = useAuth0();
  const {
    currentOrganizationId,
    loadedOrganization,
    loadingOrganization,
    fetchOrganization,
    setupApolloClient,
    apolloClient,
  } = props;
  useEffect(() => {
    if (isAuthenticated && user && user.email_verified) {
      if (
        !currentOrganizationId &&
        !loadingOrganization &&
        !loadedOrganization
      ) {
        // Only fetch organizations if we haven't loaded them and there isn't one
        fetchOrganization();
        return;
      } else if (!apolloClient && currentOrganizationId) {
        // Only set up the apollo client if there is an organization
        // and the client hasn't been setup yet
        setupApolloClient(getIdTokenClaims, currentOrganizationId);
        return;
      }
    }
    const fn = async () => {
      localStorage.removeItem("organization");
      await loginWithRedirect({
        appState: {
          targetUrl: window.location.pathname,
          params: window.location.search,
        },
      });
    };
    if (!loading && !isAuthenticated) {
      fn();
    }
  }, [
    loading,
    isAuthenticated,
    currentOrganizationId,
    loadingOrganization,
    loadedOrganization,
    user,
  ]);
  if (loading) {
    return (
      <div
        style={{
          position: "absolute",
          top: "calc(50% - 20px)",
          left: "calc(50% - 20px)",
        }}
      >
        <Spin size="large" />
      </div>
    );
  }
  const redirectPath = "datacredits"

  return (
    <PersistGate loading={null} persistor={persistor}>
      {/* ConnectedRouter will use the store from Provider automatically */}
      <ConnectedRouter history={history}>
        {
          /* If the user is not verified yet, wait for them to confirm their email before continuing */
          (user && !user.email_verified && (
            <ConfirmEmailPrompt user={user} />
          )) ||
            // Verify we are authenticated before displaying other Components
            (isAuthenticated && (
              <Switch>
                <Redirect exact from="/" to={redirectPath} />
                <PublicRoute
                  path="/join_organization"
                  loaded={loadedOrganization}
                  component={JoinOrganizationPrompt}
                />
                <Route>
                  {
                    /* If user has no organizations then render the no org page */
                    (loadedOrganization && !currentOrganizationId && (
                      <NoOrganization />
                    )) ||
                      /* Otherwise if the apollo client has been instantiated, render data routes */
                      (apolloClient && (
                        <ApolloProvider client={apolloClient}>
                          <Switch>
                            <Route
                              exact
                              path="/users"
                              component={(props) => (
                                <UserIndex user={user} {...props} />
                              )}
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
                              path="/alerts"
                              component={(props) => (
                                <AlertsIndex user={user} {...props} />
                              )}
                            />
                            <Route
                              exact
                              path="/alerts/new"
                              component={(props) => (
                                <AlertsIndex user={user} {...props} />
                              )}
                            />
                            <Route
                              exact
                              path="/alerts/:id"
                              component={(props) => (
                                <AlertsIndex user={user} {...props} />
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
                              path="/profile"
                              component={(props) => (
                                <Profile user={user} {...props} />
                              )}
                            />
                          </Switch>
                        </ApolloProvider>
                      ))
                  }
                </Route>
              </Switch>
            ))
        }
      </ConnectedRouter>
    </PersistGate>
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

export default connect(mapStateToProps, mapDispatchToProps)(Router);

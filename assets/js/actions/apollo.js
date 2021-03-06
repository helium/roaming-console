// GraphQL
import { ApolloClient, InMemoryCache, HttpLink } from '@apollo/client';
import { onError } from "@apollo/client/link/error";
import { setContext } from "@apollo/client/link/context";
import { store } from '../store/configureStore';
import { replace } from 'connected-react-router';
import { logOut } from '../actions/auth'
import createSocket from '../socket'

export const CREATED_APOLLO_CLIENT='CREATED_APOLLO_CLIENT';

export const setupApolloClient = (getAuthToken, organizationId) => {
  return async (dispatch) => {
    let currentOrganizationId = organizationId
    let tokenClaims = await getAuthToken();
    let token = tokenClaims.__raw

    const httpLink = new HttpLink({
      uri: "/graphql"
    })

    const authLink = setContext((_, { headers }) => {
      return {
        headers: {
          ...headers,
          authorization: token ? `Bearer ${token}` : "",
          organization: currentOrganizationId
        }
      }
    })

    const authErrorLink = onError(({ networkError, operation: { operationName }}) => {
      if (networkError && networkError.statusCode == 404) {
        switch(operationName) {
          default:
            break
        }
      }
    })

    const link = authErrorLink.concat(authLink.concat(httpLink))
    const apolloClient = createApolloClient(link)

    let socket = createSocket(token, currentOrganizationId)
    socket.connect()

    store.subscribe(async () => {
      if (Math.ceil(Date.now() / 1000) > store.getState().apollo.tokenClaims.exp) {
        dispatch(logOut())
      }

      if (store.getState().apollo.tokenClaims.exp - Math.ceil(Date.now() / 1000) < 3600) {
        const newTokenClaims = await getAuthToken()
        const newAuthLink = setContext((_, { headers }) => {
          return {
            headers: {
              ...headers,
              authorization:`Bearer ${newTokenClaims.__raw}`,
              organization: currentOrganizationId
            }
          }
        })
        const newLink = authErrorLink.concat(newAuthLink.concat(httpLink))
        const newApolloClient = createApolloClient(newLink)
        socket.disconnect()
        socket = createSocket(newTokenClaims.__raw, currentOrganizationId)
        socket.connect()
        dispatch(createdApolloClient(newApolloClient, socket, newTokenClaims))
      }
    })

    return dispatch(createdApolloClient(apolloClient, socket, tokenClaims));
  }
}

const createApolloClient = (link) => (
  new ApolloClient({
    link,
    cache: new InMemoryCache({
      typePolicies: {
        Query: {
          fields: {
            allOrganizations: {
              merge: false
            },
            apiKeys: {
              merge: false
            },
          },
        },
      },
    }),
  })
)

export const createdApolloClient = (apolloClient, socket, tokenClaims) => {
  return {
    type: CREATED_APOLLO_CLIENT,
    apolloClient,
    socket,
    tokenClaims
  };
}

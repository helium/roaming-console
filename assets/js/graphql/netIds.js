import { gql } from "@apollo/client";

export const ALL_NET_IDS = gql`
  query AllNetIds {
    allNetIds {
      id
      value
      config
      http_auth_header
    }
  }
`;

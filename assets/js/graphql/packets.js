import { gql } from "@apollo/client";

export const GET_ORGANIZATION_PACKETS = gql`
  query PacketsQuery {
    packets {
      packets_per_hour
    }
  }
`;

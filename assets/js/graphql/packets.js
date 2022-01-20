import { gql } from "@apollo/client";

export const GET_ORGANIZATION_PACKETS = gql`
  query PacketsQuery {
    packets {
      net_id
      reported_at_epoch
    }
  }
`;

import { gql } from "@apollo/client";

export const ORGANIZATION_FRAGMENT = gql`
  fragment OrganizationFragment on Organization {
    id
    name
    inserted_at
    dc_balance
  }
`;

export const ORGANIZATION_SHOW = gql`
  query OrganizationShowSettingsQuery($id: ID!) {
    organization(id: $id) {
      id
      dc_balance
      total_dc
      total_packets
      packets_last_30d
      dc_last_30d
      net_ids {
        id
        value
        config
        active
        http_headers {
          auth
        }
      }
    }
  }
`;

export const ORGANIZATION_SHOW_DC = gql`
  query OrganizationShowQuery($id: ID!) {
    organization(id: $id) {
      id
      name
      dc_balance
      stripe_customer_id
      default_payment_id
      automatic_charge_amount
      automatic_payment_method
      dc_balance_nonce
      received_free_dc
      net_ids {
        id
        value
        config
        http_headers {
          auth
        }
      }
    }
  }
`;

export const PAGINATED_ORGANIZATIONS = gql`
  query PaginatedOrganizationsQuery($page: Int, $pageSize: Int) {
    organizations(page: $page, pageSize: $pageSize) {
      entries {
        ...OrganizationFragment
        active
      }
      totalEntries
      totalPages
      pageSize
      pageNumber
    }
  }
  ${ORGANIZATION_FRAGMENT}
`;

export const ALL_ORGANIZATIONS = gql`
  query AllOrganizationsQuery {
    allOrganizations {
      id
      name
      dc_balance
    }
  }
`;

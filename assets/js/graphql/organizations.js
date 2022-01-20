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
      address
      port
      join_credentials
      multi_buy
      total_packets_sent
      total_dc_used
      dc_balance
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

import { gql } from "@apollo/client";

export const ALERTS_SETTING = gql`
  query AlertsSettingQuery {
    alertsSetting {
      config
    }
  }
`;

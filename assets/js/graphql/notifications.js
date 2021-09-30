import { gql } from '@apollo/client';

export const NOTIFICATIONS_SETTING = gql`
  query NotificationsSettingQuery {
    notificationsSetting {
      config
    }
  }
`

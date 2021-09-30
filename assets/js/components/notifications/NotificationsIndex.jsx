import React, { useState } from "react";
import { useQuery } from "@apollo/client";
import DashboardLayout from "../common/DashboardLayout";
import { NOTIFICATIONS_SETTING } from "../../graphql/notifications";
import analyticsLogger from "../../util/analyticsLogger";
import { setNotifications } from '../../actions/notifications'
import NotificationSetting from "./NotificationSetting"
import { Link } from "react-router-dom";
import { Typography, Row, Col, Button } from "antd";
const { Text } = Typography;

const NOTIFICATION_TYPES = [
  {
    key: "dc_low",
    description: "Data Credit balance is low"
  },
  {
    key: "dc_purchased",
    description: "Data Credits have been purchased"
  },
  {
    key: "users_updated",
    description: "Users are added, removed or updated"
  },
  {
    key: "payments_updated",
    description: "Payment Methods are added, removed or updated"
  }
]

export default (props) => {
  const defaultSettings = {
    dc_low: { email: { recipient: "admin", active: false } },
    dc_purchased: { email: { recipient: "admin", active: false } },
    users_updated: { email: { recipient: "admin", active: false } },
    payments_updated: { email: { recipient: "admin", active: false } },
  }
  const [notificationsSetting, updateNotificationsSetting] = useState(defaultSettings)

  const {
    loading: queryLoading,
    error: queryError,
    data: queryData,
    refetch: queryRefetch,
  } = useQuery(NOTIFICATIONS_SETTING, {
    fetchPolicy: "cache-first",
  });

  return (
    <DashboardLayout title="Notifications" user={props.user}>
      <div
        style={{
          padding: "30px 30px 10px 30px",
          height: "100%",
          width: "100%",
          backgroundColor: "#ffffff",
          borderRadius: 6,
          overflow: "hidden",
          boxShadow: "0px 20px 20px -7px rgba(17, 24, 31, 0.19)",
        }}
      >
        <Row gutter={16}>
          <Col span={10}>
            <div style={{marginBottom: 20}}>
              <Text style={{ fontSize: 22, fontWeight: 600 }}>Your Notifications</Text>
            </div>
            <div>
              <p style={{ fontSize: "16px" }}>
                Notifications can be created for different roaming conditions.
              </p>
              <p>
                <a
                  className="help-link"
                  href="https://docs.helium.com/use-the-network/console"
                  target="_blank"
                >
                  Learn more about notifications
                </a>
              </p>
            </div>
          </Col>
          <Col span={14}>
            <div style={{ padding: 20 }}>
              {
                NOTIFICATION_TYPES.map(notification => (
                  <NotificationSetting
                    key={notification.key}
                    notificationType={notification}
                    updateNotificationsSetting={updateNotificationsSetting}
                    notificationsSetting={notificationsSetting}
                  />
                ))
              }
              <Button type="primary" onClick={() => setNotifications(notificationsSetting)} style={{ marginTop: 20 }}>
                Save Notifications
              </Button>
            </div>
          </Col>
        </Row>
      </div>
    </DashboardLayout>
  )
}

import React from "react";
import { useSelector } from "react-redux";
import { Typography, Switch, Button, Menu, Dropdown } from "antd";
const { Text } = Typography;
import { userCan } from "../common/UserCan";

export default ({ notificationType, notificationsSetting, updateNotificationsSetting }) => {
  const currentRole = useSelector((state) => state.organization.currentRole);

  const recipientMenu = () => (
    <Menu
      onClick={(e) => {
        updateNotificationsSetting(
          Object.assign(
            {},
            notificationsSetting,
            { [notificationType.key]: {email: { recipient: e.key, active: notificationsSetting[notificationType.key].email.active }}})
        )
      }}
    >
      <Menu.Item key="admin">Admin</Menu.Item>
      <Menu.Item key="manager">Manager</Menu.Item>
      <Menu.Item key="read">Read-Only</Menu.Item>
      <Menu.Item key="all">All</Menu.Item>
    </Menu>
  );

  return (
    <div
      style={{
        display: "flex",
        justifyContent: "space-between",
        marginBottom: 10,
      }}
    >
      <span>
        <Text style={{ fontSize: "16px" }}>Notify </Text>
        <Dropdown disabled={false} overlay={recipientMenu()}>
          <a
            className="ant-dropdown-link"
            onClick={(e) => e.preventDefault()}
            style={{
              textTransform: "capitalize",
              textDecoration: "underline",
              fontSize: "16px",
            }}
          >
            {notificationsSetting[notificationType.key].email.recipient === 'read' ?
              "read-Only" : notificationsSetting[notificationType.key].email.recipient
            }
          </a>
        </Dropdown>
        <Text style={{ fontSize: "16px" }}> when </Text>
        <Text style={{ fontSize: "16px" }} strong>
          {notificationType.description}
        </Text>
      </span>
      <Switch
        style={{ marginLeft: 10 }}
        disabled={!userCan({ role: currentRole })}
        checked={notificationsSetting[notificationType.key].email.active}
        onChange={(checked) => {
          updateNotificationsSetting(
            Object.assign(
              {},
              notificationsSetting,
              { [notificationType.key]: {email: { recipient: notificationsSetting[notificationType.key].email.recipient, active: checked }}})
          )
        }}
      />
    </div>
  )
}

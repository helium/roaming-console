import React from "react";
import { useSelector } from "react-redux";
import { Typography, Switch, Button, Menu, Dropdown } from "antd";
const { Text } = Typography;
import { userCan } from "../common/UserCan";

export default ({
  alertType,
  alertsSetting,
  updateAlertsSetting,
  setChangesState,
}) => {
  const currentRole = useSelector((state) => state.organization.currentRole);

  const recipientMenu = () => (
    <Menu
      onClick={(e) => {
        updateAlertsSetting(
          Object.assign({}, alertsSetting, {
            [alertType.key]: {
              email: {
                recipient: e.key,
                active: alertsSetting[alertType.key].email.active,
              },
            },
          })
        );
        setChangesState(true);
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
            {alertsSetting[alertType.key].email.recipient === "read"
              ? "read-Only"
              : alertsSetting[alertType.key].email.recipient}
          </a>
        </Dropdown>
        <Text style={{ fontSize: "16px" }}> when </Text>
        <Text style={{ fontSize: "16px" }} strong>
          {alertType.description}
        </Text>
      </span>
      <Switch
        style={{ marginLeft: 10 }}
        disabled={!userCan({ role: currentRole })}
        checked={alertsSetting[alertType.key].email.active}
        onChange={(checked) => {
          updateAlertsSetting(
            Object.assign({}, alertsSetting, {
              [alertType.key]: {
                email: {
                  recipient: alertsSetting[alertType.key].email.recipient,
                  active: checked,
                },
              },
            })
          );
          setChangesState(true);
        }}
      />
    </div>
  );
};

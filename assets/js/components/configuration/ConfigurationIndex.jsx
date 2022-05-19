import React, { useEffect, useState } from "react";
import { useQuery } from "@apollo/client";
import { useSelector } from "react-redux";
import { ORGANIZATION_SHOW } from "../../graphql/organizations";
import { updateNetIdConfig, updateNetIdActive } from "../../actions/netId";
import { Switch, Tabs, Typography, Divider } from "antd";
const { Text } = Typography;
const { TabPane } = Tabs;
import DashboardLayout from "../common/DashboardLayout";
import { decimalToHex } from "../../util/constants";
import ConfigForm from "./ConfigForm";
import sortBy from "lodash/sortBy";
import UserCan from "../common/UserCan";

export default (props) => {
  const socket = useSelector((state) => state.apollo.socket);
  const currentOrganizationId = useSelector(
    (state) => state.organization.currentOrganizationId
  );

  const {
    loading: orgLoading,
    error: orgError,
    data: orgData,
    refetch: orgRefetch,
  } = useQuery(ORGANIZATION_SHOW, {
    fetchPolicy: "cache-first",
    variables: { id: currentOrganizationId },
  });

  const channel = socket.channel("graphql:configuration_index", {});

  useEffect(() => {
    channel.join();
    channel.on(
      `graphql:configuration_index:${currentOrganizationId}:settings_update`,
      (_message) => {
        orgRefetch();
      }
    );

    return () => {
      channel.leave();
    };
  }, []);

  const submit = (id, values) => {
    updateNetIdConfig(id, values);
  };

  const netIds =
    (orgData &&
      orgData.organization &&
      sortBy(orgData.organization.net_ids, ["value"])) ||
    [];

  return (
    <DashboardLayout title="Configuration" user={props.user}>
      <div
        style={{
          padding: "30px 50px",
          height: "100%",
          width: "90%",
          backgroundColor: "#ffffff",
          borderRadius: 6,
          overflow: "hidden",
          boxShadow: "0px 20px 20px -7px rgba(17, 24, 31, 0.19)",
        }}
      >
        <Tabs defaultActiveKey={(netIds[0] && netIds[0].value) || null}>
          {netIds.map((n) => {
            return (
              <TabPane tab={`Net ID ${decimalToHex(n.value)}`} key={n.value}>
                <div style={{ justifyContent: "flex-end", display: "flex" }}>
                  <UserCan noManager>
                    <Text className="config-label">Active:</Text>
                    <Switch
                      checked={n.active}
                      onChange={(active) => updateNetIdActive(n.id, active)}
                      style={{ marginLeft: 10 }}
                    />
                  </UserCan>
                </div>
                <Divider />
                <ConfigForm
                  data={n}
                  key={n.value}
                  submit={submit}
                  otherNetIds={orgData.organization.net_ids.filter(
                    (ni) => ni.id !== n.id
                  )}
                />
              </TabPane>
            );
          })}
          {netIds.length === 0 && (
            <div>No Net ID has been linked to your Organization.</div>
          )}
        </Tabs>
      </div>
    </DashboardLayout>
  );
};

import React, { useEffect } from "react";
import { useQuery } from "@apollo/client";
import { useSelector } from "react-redux";
import { ALL_NET_IDS } from "../../graphql/netIds";
import { updateNetIdConfig, updateNetIdActive } from "../../actions/netId";
import { Switch, Tabs, Typography, Divider } from "antd";
const { Text } = Typography;
const { TabPane } = Tabs;
import DashboardLayout from "../common/DashboardLayout";
import { decimalToHex } from "../../util/constants";
import ConfigForm from "./ConfigForm";
import sortBy from "lodash/sortBy";
import UserCan, { userCan } from "../common/UserCan";

export default (props) => {
  const socket = useSelector((state) => state.apollo.socket);
  const currentOrganizationId = useSelector(
    (state) => state.organization.currentOrganizationId
  );
  const currentRole = useSelector((state) => state.organization.currentRole);

  const { data, refetch } = useQuery(ALL_NET_IDS, {
    fetchPolicy: "cache-first",
  });

  const channel = socket.channel("graphql:configuration_index", {});

  useEffect(() => {
    channel.join();
    channel.on(
      `graphql:configuration_index:${currentOrganizationId}:settings_update`,
      (_message) => {
        refetch();
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
    (data && data.allNetIds && sortBy(data.allNetIds, ["value"])) || [];

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
        {netIds.length > 0 ? (
          <Tabs defaultActiveKey={(netIds[0] && netIds[0].value) || null}>
            {netIds.map((n) => {
              return (
                <TabPane tab={`Net ID ${decimalToHex(n.value)}`} key={n.value}>
                  <div style={{ justifyContent: "flex-end", display: "flex" }}>
                    <Text className="config-label">Active:</Text>
                    <Switch
                      checked={n.active}
                      onChange={(active) => updateNetIdActive(n.id, active)}
                      style={{ marginLeft: 10 }}
                      disabled={!userCan({ role: currentRole })}
                    />
                  </div>
                  <Divider />
                  <ConfigForm
                    data={n}
                    key={n.value}
                    submit={submit}
                    otherNetIds={netIds.filter((ni) => ni.id !== n.id)}
                  />
                </TabPane>
              );
            })}
          </Tabs>
        ) : (
          <div>No Net ID has been linked to your Organization.</div>
        )}
      </div>
    </DashboardLayout>
  );
};

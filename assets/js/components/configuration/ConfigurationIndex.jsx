import React, { useEffect, useState } from "react";
import { useQuery } from "@apollo/client";
import { useSelector } from "react-redux";
import { ALL_NET_IDS } from "../../graphql/netIds";
import {
  updateNetIdConfig,
  updateNetIdConfigActive,
  removeNetIdConfig,
} from "../../actions/netId";
import { Switch, Tabs, Typography, Collapse, Button } from "antd";
const { Text } = Typography;
const { TabPane } = Tabs;
import DashboardLayout from "../common/DashboardLayout";
import { decimalToHex } from "../../util/constants";
import ConfigForm from "./ConfigForm";
import sortBy from "lodash/sortBy";
import { userCan } from "../common/UserCan";
const { Panel } = Collapse;
import { PlusOutlined, DeleteOutlined } from "@ant-design/icons";
import ConfirmDeleteConfigModal from "./ConfirmDeleteConfigModal";

export default (props) => {
  const [newConfigs, setNewConfigs] = useState([]);
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [configToDelete, setConfigToDelete] = useState({});

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

  const submit = (id, values, newConfig) => {
    updateNetIdConfig(id, values).then(() => {
      if (newConfig) setNewConfigs([]);
    });
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
            {netIds.map((netId) => {
              return (
                <TabPane
                  tab={`Net ID ${decimalToHex(netId.value)}`}
                  key={netId.value}
                >
                  <Collapse
                    defaultActiveKey={`panel-${
                      JSON.parse(netId.config)[0]?.config_id
                    }`}
                  >
                    {JSON.parse(netId.config)
                      .concat(newConfigs)
                      .map((config) => {
                        return (
                          <Panel
                            header={
                              <Text style={{ fontWeight: 600 }}>
                                {config.new
                                  ? "NEW CONFIGURATION"
                                  : `Configuration for DevAddrs: ${
                                      config.devaddrs
                                        ? config.devaddrs
                                            .map(function (limits) {
                                              return `${limits.lower} - ${limits.upper}`;
                                            })
                                            .join(", ")
                                        : "(None)"
                                    }`}
                              </Text>
                            }
                            key={`panel-${
                              config.new ? "new" : config.config_id
                            }`}
                            extra={
                              <div
                                style={{
                                  display: "flex",
                                  alignItems: "flex-end",
                                }}
                              >
                                {!config.new && (
                                  <>
                                    <Text className="config-label">
                                      Active:
                                    </Text>
                                    <Switch
                                      checked={config.active}
                                      onChange={(active, event) => {
                                        event.stopPropagation();
                                        updateNetIdConfigActive(
                                          netId.id,
                                          config.config_id,
                                          active
                                        );
                                      }}
                                      style={{ marginLeft: 10 }}
                                      disabled={
                                        !userCan({ role: currentRole }) ||
                                        !config.protocol
                                      }
                                    />
                                  </>
                                )}
                                <Button
                                  style={{ marginLeft: 5 }}
                                  icon={<DeleteOutlined />}
                                  shape="circle"
                                  type="primary"
                                  size="small"
                                  danger
                                  onClick={(event) => {
                                    event.stopPropagation();
                                    if (config.new) {
                                      setNewConfigs([]);
                                    } else {
                                      setConfigToDelete({
                                        netId: netId.id,
                                        netIdValue: decimalToHex(netId.value),
                                        configId: config.config_id,
                                      });
                                      setShowConfirmModal(true);
                                    }
                                  }}
                                />
                              </div>
                            }
                          >
                            <ConfigForm
                              data={{
                                ...config,
                                ...(netId.http_headers &&
                                netId.http_headers.length > 0 &&
                                JSON.parse(netId.http_headers)[config.config_id]
                                  ? {
                                      http_headers: JSON.parse(
                                        netId.http_headers
                                      )[config.config_id],
                                    }
                                  : null),
                              }}
                              key={config.config_id}
                              submit={(id, values) => {
                                submit(id, values, config.new);
                              }}
                              netId={netId.id}
                            />
                          </Panel>
                        );
                      })}
                  </Collapse>

                  {newConfigs.length === 0 && (
                    <div
                      style={{
                        justifyContent: "flex-end",
                        display: "flex",
                        marginTop: 15,
                        alignItems: "center",
                      }}
                    >
                      <Button
                        icon={<PlusOutlined />}
                        onClick={() => {
                          setNewConfigs([{ new: true }]);
                        }}
                      >
                        Add Configuration
                      </Button>
                    </div>
                  )}
                </TabPane>
              );
            })}
          </Tabs>
        ) : (
          <div>No Net ID has been linked to your Organization.</div>
        )}
      </div>
      <ConfirmDeleteConfigModal
        open={showConfirmModal}
        close={() => {
          setShowConfirmModal(false);
          setConfigToDelete({});
        }}
        config={configToDelete}
        handleSubmit={() => {
          removeNetIdConfig(configToDelete.netId, configToDelete.configId).then(
            () => {
              setShowConfirmModal(false);
              setConfigToDelete({});
            }
          );
        }}
      />
    </DashboardLayout>
  );
};

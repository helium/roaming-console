import React, { useState, useEffect } from "react";
import { useQuery } from "@apollo/client";
import { useSelector } from "react-redux";
import { ORGANIZATION_SHOW } from "../../graphql/organizations";
import { updateOrganizationCreds } from "../../actions/organization";
import { Typography, Button, Input, Form, Space, Switch } from "antd";
const { Text } = Typography;
import DashboardLayout from "../common/DashboardLayout";
import {
  MinusCircleOutlined,
  PlusOutlined,
  UploadOutlined,
} from "@ant-design/icons";
import BulkJoinCredentialsModal from "./BulkJoinCredentialsModal";
import { userCan } from "../common/UserCan";

export default (props) => {
  const [form] = Form.useForm();
  const socket = useSelector((state) => state.apollo.socket);
  const currentOrganizationId = useSelector(
    (state) => state.organization.currentOrganizationId
  );
  const currentRole = useSelector((state) => state.organization.currentRole);
  const [showJoinCredsModal, setShowJoinCredsModal] = useState(false);

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

  useEffect(() => {
    form.resetFields();
  }, [orgData]);

  const isValidPositiveInteger = (input) => {
    const num = Number(input);

    if (Number.isInteger(num) && num > 0) {
      return true;
    }

    return false;
  };

  const onFinish = (values) => {
    updateOrganizationCreds(
      currentOrganizationId,
      values.address.replace(/\s/g, ""),
      values.port,
      values.join_credentials ? JSON.stringify(values.join_credentials) : null,
      values.multi_buy,
      values.disable_pull_data
    );
  };

  return (
    <DashboardLayout title="Configuration" user={props.user}>
      <div
        style={{
          padding: "30px 30px 30px 30px",
          height: "100%",
          width: "100%",
          backgroundColor: "#ffffff",
          borderRadius: 6,
          overflow: "hidden",
          boxShadow: "0px 20px 20px -7px rgba(17, 24, 31, 0.19)",
        }}
      >
        <div style={{ width: 460 }}>
          <Form
            form={form}
            layout="vertical"
            initialValues={
              orgData &&
              orgData.organization && {
                address: orgData.organization.address,
                port: orgData.organization.port,
                multi_buy: orgData.organization.multi_buy,
                join_credentials: JSON.parse(
                  orgData.organization.join_credentials
                ),
                disable_pull_data: orgData.organization.disable_pull_data,
              }
            }
            onFinish={onFinish}
            autoComplete="off"
          >
            <Form.Item
              name="address"
              label={<Text className="config-label">Address</Text>}
              rules={[
                { required: true, message: "Address is required." },
                {
                  validator: (_, value) => {
                    const res = value.match(
                      /^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?|^((http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/g
                    );
                    return res !== null
                      ? Promise.resolve()
                      : Promise.reject(
                          "Address must be a valid URL or IP address."
                        );
                  },
                },
              ]}
              hasFeedback
            >
              <Input required disabled={!userCan({ role: currentRole })} />
            </Form.Item>
            <Form.Item
              name="port"
              label={<Text className="config-label">Port</Text>}
              rules={[
                { required: true, message: "Port is required." },
                {
                  validator: (_, value) =>
                    parseInt(value) <= 65535
                      ? Promise.resolve()
                      : Promise.reject("Port numbers range from 0 to 65535."),
                },
                {
                  validator: (_, value) =>
                    isValidPositiveInteger(value)
                      ? Promise.resolve()
                      : Promise.reject("Port must be a positive integer."),
                },
              ]}
              hasFeedback
            >
              <Input
                type="number"
                required
                disabled={!userCan({ role: currentRole })}
              />
            </Form.Item>
            <Form.Item
              label={<Text className="config-label">Disable Pull Data</Text>}
            >
              <div>
                By default “PULL_DATA” packets are repeatedly sent to poll data
                from the endpoint and confirm the health of the connection.
              </div>
              <Form.Item
                noStyle
                valuePropName="checked"
                name="disable_pull_data"
              >
                <Switch disabled={!userCan({ role: currentRole })} />
              </Form.Item>
            </Form.Item>
            <Form.Item
              label={
                <Text className="config-label">Multi Packet Purchase</Text>
              }
            >
              <div>
                Enter the number of desired packets (if available). Additional
                packets are purchased only if multiple Hotspots "hear" and send
                the same packet.
              </div>
              <Form.Item
                noStyle
                name="multi_buy"
                hasFeedback
                rules={[
                  {
                    validator: (_, value) =>
                      !value || isValidPositiveInteger(value)
                        ? Promise.resolve()
                        : Promise.reject(
                            "Multi Packet Purchase must be a positive integer."
                          ),
                  },
                ]}
              >
                <Input
                  type="number"
                  disabled={!userCan({ role: currentRole })}
                />
              </Form.Item>
            </Form.Item>
            <Form.List name="join_credentials">
              {(fields, { add, remove }) => (
                <>
                  <div style={{ padding: "0 0 8px" }}>
                    <Text
                      className="config-label"
                      style={{ color: "rgba(0,0,0,.85)" }}
                    >
                      Join Credentials
                    </Text>
                    <div style={{ margin: "10px 0px 5px 0px" }}>
                      Use an asterisk “*” wildcard in the DevEUI field to map
                      multiple DevEUI's to a single AppEUI. Each AppEUI requires
                      a new entry.
                    </div>
                  </div>
                  {fields.map(({ key, name, ...restField }) => (
                    <Space
                      key={key}
                      style={{ display: "flex", marginBottom: 8 }}
                      align="baseline"
                      id="join-creds-pair"
                    >
                      <Form.Item
                        {...restField}
                        name={[name, "dev_eui"]}
                        rules={[
                          { required: true, message: "Missing DevEUI" },
                          {
                            validator: (_, value) => {
                              const res = value.match(/^[0-9a-fA-F]{16}$/g);
                              if (
                                value.indexOf("*") !== -1 &&
                                value.length > 1
                              ) {
                                return Promise.reject(
                                  "DevEUI may be the wildcard character (*) but it may not contain it."
                                );
                              } else if (value !== "*" && res === null) {
                                return Promise.reject(
                                  "DevEUI must either be the wildcard character (*), or be exactly 8 bytes long and only contain characters 0-9 A-F."
                                );
                              } else {
                                return Promise.resolve();
                              }
                            },
                          },
                        ]}
                        hasFeedback
                      >
                        <Input
                          placeholder="DevEUI"
                          disabled={!userCan({ role: currentRole })}
                        />
                      </Form.Item>
                      <Form.Item
                        {...restField}
                        name={[name, "app_eui"]}
                        rules={[
                          { required: true, message: "Missing AppEUI" },
                          {
                            validator: (_, value) => {
                              const res = value.match(/^[0-9a-fA-F]{16}$/g);
                              if (value.indexOf("*") !== -1) {
                                return Promise.reject(
                                  "AppEUI may not be or contain the wildcard character (*)."
                                );
                              } else if (res === null) {
                                return Promise.reject(
                                  "AppEUI must be exactly 8 bytes long, and only contain characters 0-9 A-F."
                                );
                              } else {
                                return Promise.resolve();
                              }
                            },
                          },
                        ]}
                        hasFeedback
                      >
                        <Input
                          placeholder="AppEUI"
                          disabled={!userCan({ role: currentRole })}
                        />
                      </Form.Item>
                      {userCan({ role: currentRole }) && (
                        <MinusCircleOutlined onClick={() => remove(name)} />
                      )}
                    </Space>
                  ))}
                  <Form.Item>
                    <div style={{ display: "flex" }}>
                      <Button
                        type="dashed"
                        onClick={() => add()}
                        icon={<PlusOutlined />}
                        style={{ flexGrow: 1 }}
                        disabled={!userCan({ role: currentRole })}
                      >
                        Add Join Credential
                      </Button>
                      <Button
                        icon={<UploadOutlined />}
                        onClick={() => {
                          setShowJoinCredsModal(true);
                        }}
                        style={{ flexGrow: 1, marginLeft: 15 }}
                        disabled={!userCan({ role: currentRole })}
                      >
                        Use CSV File
                      </Button>
                    </div>
                  </Form.Item>
                </>
              )}
            </Form.List>
            <Form.Item>
              <div style={{ display: "flex" }}>
                <Button
                  onClick={() => {
                    form.resetFields();
                  }}
                  style={{ flexGrow: 1 }}
                  disabled={!userCan({ role: currentRole })}
                >
                  Clear
                </Button>
                <Button
                  type="primary"
                  htmlType="submit"
                  style={{ flexGrow: 2, marginLeft: 15 }}
                  disabled={!userCan({ role: currentRole })}
                >
                  Save
                </Button>
              </div>
            </Form.Item>
          </Form>
        </div>
      </div>
      <BulkJoinCredentialsModal
        open={showJoinCredsModal}
        close={() => {
          setShowJoinCredsModal(false);
        }}
        updateCredentials={(creds) => {
          form.setFieldsValue({ join_credentials: creds });
        }}
      />
    </DashboardLayout>
  );
};

import React, { useState, useEffect } from "react";
import { useQuery } from "@apollo/client";
import { useSelector } from "react-redux";
import { ORGANIZATION_SHOW } from "../../graphql/organizations";
import { updateOrganizationCreds } from "../../actions/organization";
import { Typography, Button, Input, Form, Space } from "antd";
const { Text } = Typography;
import DashboardLayout from "../common/DashboardLayout";
import {
  MinusCircleOutlined,
  PlusOutlined,
  UploadOutlined,
} from "@ant-design/icons";
import BulkJoinCredentialsModal from "./BulkJoinCredentialsModal";

export default (props) => {
  const [form] = Form.useForm();
  const socket = useSelector((state) => state.apollo.socket);
  const currentOrganizationId = useSelector(
    (state) => state.organization.currentOrganizationId
  );
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
      JSON.stringify(values.join_credentials),
      values.multi_buy
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
              }
            }
            onFinish={onFinish}
            autoComplete="off"
          >
            <Form.Item
              name="address"
              label="Address"
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
              <Input required />
            </Form.Item>
            <Form.Item
              name="port"
              label="Port"
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
              <Input type="number" required />
            </Form.Item>
            <Form.Item
              name="multi_buy"
              label="Multi Packet Purchase"
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
              hasFeedback
            >
              <Input type="number" />
            </Form.Item>
            <Form.List name="join_credentials">
              {(fields, { add, remove }) => (
                <>
                  <Text style={{ color: "rgba(0,0,0,.85)" }}>
                    Join Credentials
                  </Text>
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
                          { required: true, message: "Missing Dev EUI" },
                          {
                            validator: (_, value) => {
                              if (
                                value.indexOf("*") !== -1 &&
                                value.length > 1
                              ) {
                                return Promise.reject(
                                  "Dev EUI may be the wildcard character (*) but it may not contain it."
                                );
                              } else {
                                return Promise.resolve();
                              }
                            },
                          },
                        ]}
                        hasFeedback
                      >
                        <Input placeholder="Dev EUI" />
                      </Form.Item>
                      <Form.Item
                        {...restField}
                        name={[name, "app_eui"]}
                        rules={[
                          { required: true, message: "Missing App EUI" },
                          {
                            validator: (_, value) => {
                              if (value.indexOf("*") !== -1) {
                                return Promise.reject(
                                  "App EUI may not be or contain the wildcard character (*)."
                                );
                              } else {
                                return Promise.resolve();
                              }
                            },
                          },
                        ]}
                        hasFeedback
                      >
                        <Input placeholder="App EUI" />
                      </Form.Item>
                      <MinusCircleOutlined onClick={() => remove(name)} />
                    </Space>
                  ))}
                  <Form.Item>
                    <div style={{ display: "flex" }}>
                      <Button
                        type="dashed"
                        onClick={() => add()}
                        icon={<PlusOutlined />}
                        style={{ flexGrow: 1 }}
                      >
                        Add Join Credential
                      </Button>
                      <Button
                        icon={<UploadOutlined />}
                        onClick={() => {
                          setShowJoinCredsModal(true);
                        }}
                        style={{ flexGrow: 1, marginLeft: 15 }}
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
                >
                  Clear
                </Button>
                <Button
                  type="primary"
                  htmlType="submit"
                  style={{ flexGrow: 2, marginLeft: 15 }}
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

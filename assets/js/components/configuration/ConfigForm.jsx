import React, { useEffect, useState } from "react";
import {
  Typography,
  Button,
  Input,
  InputNumber,
  Form,
  Space,
  Switch,
  Row,
  Col,
  Radio,
} from "antd";
const { Text } = Typography;
import { userCan } from "../common/UserCan";
import { useSelector } from "react-redux";
import BulkJoinCredentialsModal from "./BulkJoinCredentialsModal";
import {
  MinusCircleOutlined,
  PlusOutlined,
  UploadOutlined,
  SaveOutlined,
  ClearOutlined,
  CopyOutlined,
} from "@ant-design/icons";
import { decimalToHex } from "../../util/constants";

export default ({ data, submit, otherNetIds }) => {
  const [form] = Form.useForm();
  const [showJoinCredsModal, setShowJoinCredsModal] = useState(false);
  const currentRole = useSelector((state) => state.organization.currentRole);

  const config = JSON.parse(data.config);
  const [protocol, setProtocol] = useState(config.protocol || "udp");

  const isValidPositiveInteger = (input) => {
    const num = Number(input);

    if (Number.isInteger(num) && num > 0) {
      return true;
    }

    return false;
  };

  useEffect(() => {
    form.resetFields();
  }, [data]);

  const handleFormValuesChange = (changedValues) => {
    const fieldName = Object.keys(changedValues)[0];

    if (fieldName === "protocol") {
      const value = changedValues[fieldName];
      setProtocol(value);

      if (value === "http" && config.protocol === "udp") {
        form.setFieldsValue({ http_dedupe_timeout: 200 });
      }
    }
  };

  const onFinish = (values) => {
    submit(data.id, values);
  };

  const otherNetIdsWithConfig = otherNetIds.filter((ni) => ni.config !== "{}");

  return (
    <>
      <Form
        form={form}
        layout="vertical"
        initialValues={
          Object.keys(config).length === 0
            ? { protocol: "udp" }
            : {
                protocol: config.protocol,
                address: config.address,
                port: config.port,
                multi_buy: config.multi_buy,
                join_credentials: config.join_credentials,
                disable_pull_data: config.disable_pull_data,
                http_endpoint: config.http_endpoint,
                http_flow_type: config.http_flow_type,
                http_dedupe_timeout: config.http_dedupe_timeout,
                http_auth_header: data.http_auth_header,
              }
        }
        onFinish={onFinish}
        onValuesChange={handleFormValuesChange}
        autoComplete="off"
      >
        <Row gutter={50}>
          <Col span={12}>
            {otherNetIdsWithConfig.length > 0 && (
              <div style={{ display: "flex", justifyContent: "flex-end" }}>
                <Button
                  icon={<CopyOutlined />}
                  type="primary"
                  onClick={() => {
                    const otherConfig = JSON.parse(
                      otherNetIdsWithConfig[0].config
                    );
                    // explicitly setting them here to avoid stale fields when they're not in otherConfig
                    form.setFieldsValue({
                      protocol: otherConfig.protocol,
                      address: otherConfig.address,
                      port: otherConfig.port,
                      multi_buy: otherConfig.multi_buy,
                      join_credentials: otherConfig.join_credentials,
                      disable_pull_data: otherConfig.disable_pull_data,
                      http_endpoint: otherConfig.http_endpoint,
                      http_flow_type: otherConfig.http_flow_type,
                      http_dedupe_timeout: otherConfig.http_dedupe_timeout,
                    });
                    setProtocol(otherConfig.protocol);
                  }}
                >
                  Pull from Net ID{" "}
                  {decimalToHex(otherNetIdsWithConfig[0].value)}
                </Button>
              </div>
            )}
            <Form.Item
              name="protocol"
              label={<Text className="config-label">Protocol</Text>}
              rules={[
                {
                  required: true,
                  message: "Protocol is required.",
                },
              ]}
            >
              <Radio.Group buttonStyle="solid">
                <Radio.Button value="udp">UDP</Radio.Button>
                <Radio.Button value="http">HTTP</Radio.Button>
              </Radio.Group>
            </Form.Item>

            {protocol === "udp" && (
              <>
                <Form.Item
                  name="address"
                  label={<Text className="config-label">Address</Text>}
                  rules={[
                    {
                      required: true,
                      message: "Address is required.",
                    },
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
                    {
                      required: true,
                      message: "Port is required.",
                    },
                    {
                      validator: (_, value) =>
                        parseInt(value) <= 65535
                          ? Promise.resolve()
                          : Promise.reject(
                              "Port numbers range from 0 to 65535."
                            ),
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
                  <InputNumber
                    style={{ width: "100%" }}
                    required
                    disabled={!userCan({ role: currentRole })}
                  />
                </Form.Item>
                <Form.Item
                  label={
                    <Text className="config-label">Disable Pull Data</Text>
                  }
                >
                  <div
                    style={{ display: "flex", justifyContent: "space-between" }}
                  >
                    <span
                      style={{
                        fontWeight: 400,
                        color: "#8C8C8C",
                        paddingRight: 20,
                      }}
                    >
                      By default “PULL_DATA” packets are repeatedly sent to poll
                      data from the endpoint and confirm the health of the
                      connection.
                    </span>

                    <Form.Item
                      noStyle
                      valuePropName="checked"
                      name="disable_pull_data"
                    >
                      <Switch disabled={!userCan({ role: currentRole })} />
                    </Form.Item>
                  </div>
                </Form.Item>
              </>
            )}
            {protocol === "http" && (
              <>
                <Form.Item
                  name="http_endpoint"
                  label={<Text className="config-label">Endpoint</Text>}
                  rules={[
                    {
                      required: true,
                      message: "Endpoint is required.",
                    },
                    {
                      validator: (_, value) => {
                        const res = value.match(
                          /^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?|^((http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/g
                        );
                        return res !== null
                          ? Promise.resolve()
                          : Promise.reject(
                              "Endpoint must be a valid URL or IP address."
                            );
                      },
                    },
                  ]}
                  hasFeedback
                >
                  <Input required disabled={!userCan({ role: currentRole })} />
                </Form.Item>
                <Form.Item
                  name="http_auth_header"
                  label={
                    <Text className="config-label">Authorization Header</Text>
                  }
                >
                  <Input disabled={!userCan({ role: currentRole })} />
                </Form.Item>
                <Form.Item
                  name="http_flow_type"
                  label={<Text className="config-label">Flow Type</Text>}
                  rules={[
                    {
                      required: true,
                      message: "Flow Type is required.",
                    },
                  ]}
                >
                  <Radio.Group buttonStyle="solid">
                    <Radio.Button value="async">Async</Radio.Button>
                    <Radio.Button value="sync">Sync</Radio.Button>
                  </Radio.Group>
                </Form.Item>
                <Form.Item
                  name="http_dedupe_timeout"
                  label={
                    <Text className="config-label">
                      Dedupe Timeout (in milliseconds)
                    </Text>
                  }
                >
                  <InputNumber
                    style={{ width: "100%" }}
                    disabled={!userCan({ role: currentRole })}
                  />
                </Form.Item>
              </>
            )}
          </Col>
          <Col span={12}>
            <Form.Item
              label={
                <Text className="config-label">Multi Packet Purchase</Text>
              }
            >
              <span style={{ fontWeight: 400, color: "#8C8C8C" }}>
                Enter the number of desired packets (if available). Additional
                packets are purchased only if multiple Hotspots "hear" and send
                the same packet.
              </span>
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
                <InputNumber
                  placeholder="e.g. 5"
                  style={{ width: "100%" }}
                  disabled={!userCan({ role: currentRole })}
                />
              </Form.Item>
            </Form.Item>
            <Form.List name="join_credentials">
              {(fields, { add, remove }) => (
                <div
                  style={{
                    padding: "25px 25px 1px 25px",
                    backgroundColor: "#E6F7FF",
                  }}
                >
                  <div style={{ padding: "0 0 8px" }}>
                    <Text
                      className="config-label"
                      style={{ color: "rgba(0,0,0,.85)" }}
                    >
                      Join Credentials
                    </Text>
                    <div
                      style={{
                        margin: "10px 0px 5px 0px",
                        color: "#1890FF",
                        fontWeight: 400,
                      }}
                    >
                      Use an asterisk “*” wildcard in the DevEUI field to map
                      multiple DevEUI's to a single AppEUI. Each AppEUI requires
                      a new entry.
                    </div>
                  </div>
                  <div style={{ maxHeight: "200px", overflow: "scroll" }}>
                    {fields.map(({ key, name, ...restField }) => (
                      <Space
                        key={key}
                        size="large"
                        style={{ display: "flex" }}
                        align="baseline"
                        id="join-creds-pair"
                      >
                        <Form.Item
                          {...restField}
                          name={[name, "dev_eui"]}
                          rules={[
                            {
                              required: true,
                              message: "Missing DevEUI",
                            },
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
                            {
                              required: true,
                              message: "Missing AppEUI",
                            },
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
                  </div>
                  <Form.Item>
                    <div style={{ display: "flex", paddingTop: 15 }}>
                      <Button
                        type="dashed"
                        onClick={() => add()}
                        icon={<PlusOutlined />}
                        style={{
                          flexGrow: 1,
                          color: "#1890FF",
                          borderColor: "#1890FF",
                          background: "none",
                        }}
                        disabled={!userCan({ role: currentRole })}
                      >
                        Add Join Credential
                      </Button>
                      <Button
                        type="primary"
                        icon={<UploadOutlined />}
                        onClick={() => {
                          setShowJoinCredsModal(true);
                        }}
                        style={{ flexGrow: 1, marginLeft: 15 }}
                        disabled={!userCan({ role: currentRole })}
                      >
                        Upload CSV File
                      </Button>
                    </div>
                  </Form.Item>
                </div>
              )}
            </Form.List>
          </Col>
        </Row>
        <Form.Item>
          <div
            style={{
              marginTop: 25,
              display: "flex",
              justifyContent: "flex-end",
            }}
          >
            <Button
              icon={<ClearOutlined />}
              onClick={() => {
                form.resetFields();
                setProtocol(form.getFieldValue("protocol"));
              }}
              disabled={!userCan({ role: currentRole })}
            >
              Clear Configuration
            </Button>
            <Button
              icon={<SaveOutlined />}
              type="primary"
              htmlType="submit"
              style={{ marginLeft: 15 }}
              disabled={!userCan({ role: currentRole })}
            >
              Save Changes
            </Button>
          </div>
        </Form.Item>
      </Form>
      <BulkJoinCredentialsModal
        open={showJoinCredsModal}
        close={() => {
          setShowJoinCredsModal(false);
        }}
        updateCredentials={(creds) => {
          form.setFieldsValue({ join_credentials: creds });
        }}
      />
    </>
  );
};

import React, { useState, useEffect } from "react";
import { useQuery } from "@apollo/client";
import { useSelector } from "react-redux";
import numeral from "numeral";
import find from "lodash/find";
import DashboardLayout from "../common/DashboardLayout";
import { ORGANIZATION_SHOW } from "../../graphql/organizations";
import { updateOrganizationCreds } from "../../actions/organization";
import analyticsLogger from "../../util/analyticsLogger";
import { Link } from "react-router-dom";
import { Typography, Card, Row, Col, Popover, Button, Input } from "antd";
const { Text } = Typography;
import { primaryBlue, tertiaryPurple } from "../../util/colors";

const styles = {
  numberCount: {
    fontSize: 40,
    marginTop: -8,
  },
};

export default (props) => {
  const [address, setAddress] = useState(null);
  const [port, setPort] = useState(null);
  const [join_credentials, setJoinCreds] = useState(null);
  const [multi_buy, setMultiBuy] = useState(null);
  const [hasChanges, setChanges] = useState(false)

  const currentOrganizationId = useSelector((state) => state.organization.currentOrganizationId);
  const socket = useSelector((state) => state.apollo.socket);

  const {
    loading: queryLoading,
    error: queryError,
    data: queryData,
    refetch: queryRefetch,
  } = useQuery(ORGANIZATION_SHOW, {
    fetchPolicy: "cache-first",
    variables: { id: currentOrganizationId },
  });

  const channel = socket.channel("graphql:dashboard_index", {});

  useEffect(() => {
    channel.join();
    channel.on(
      `graphql:dashboard_index:${currentOrganizationId}:settings_update`,
      (_message) => {
        queryRefetch();
      }
    );

    return () => {
      channel.leave();
    };
  }, []);

  useEffect(() => {
    if (queryData && queryData.organization) {
      setAddress(queryData.organization.address)
      setPort(queryData.organization.port)
      setJoinCreds(queryData.organization.join_credentials)
      setMultiBuy(queryData.organization.multi_buy)
    }
  }, [queryData]);

  return (
    <DashboardLayout title="Dashboard" user={props.user}>
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

        <Row gutter={16}>
          <Col span={8}>
            <Card
              title="Total Packets Sent"
              bodyStyle={{ height: 90, padding: 0 }}
            >
              <div style={{ overflowX: 'scroll', padding: 24 }} className="no-scroll-bar">
                <Row type="flex" style={{ alignItems: "center", minWidth: 300 }}>
                  <Text style={{ ...styles.numberCount, color: primaryBlue }}>
                    {numeral(100000).format("0,0")}
                  </Text>
                </Row>
              </div>
            </Card>
          </Col>
          <Col span={8}>
            <Card
              title="Total DC Used"
              bodyStyle={{ height: 90, padding: 0 }}
            >
              <div style={{ overflowX: 'scroll', padding: 24 }} className="no-scroll-bar">
              <Row type="flex" style={{ alignItems: "center", minWidth: 300 }}>
                <Text style={{ ...styles.numberCount, color: tertiaryPurple }}>
                  {numeral(100000).format("0,0")}
                </Text>
              </Row>
              </div>
            </Card>
          </Col>
          <Col span={8}>
            <Card
              title="Remaining DC Balance"
              bodyStyle={{ height: 90, padding: 0 }}
            >
              <div style={{ overflowX: 'scroll', padding: 24 }} className="no-scroll-bar">
              <Row type="flex" style={{ alignItems: "center", minWidth: 300 }}>
                <Text style={{ ...styles.numberCount }}>
                  {numeral(100000).format("0,0")}
                </Text>
              </Row>
              </div>
            </Card>
          </Col>
        </Row>
        <div style={{ width: 300 }}>
          <Text>Address</Text>
          <Input
            placeholder={address || "Set Address"}
            value={address}
            onChange={e => {
              setAddress(e.target.value)
              setChanges(true)
            }}
            style={{ marginBottom: 10 }}
          />
          <Text>Port</Text>
          <Input
            placeholder={port || "Set Port"}
            value={port}
            onChange={e => {
              setPort(e.target.value)
              setChanges(true)
            }}
            type="number"
            style={{ marginBottom: 10 }}
          />
          <Text>Join Credentials</Text>
          <Input
            placeholder={join_credentials || "Set Join Credentials"}
            value={join_credentials}
            onChange={e => {
              setJoinCreds(e.target.value)
              setChanges(true)
            }}
            style={{ marginBottom: 10 }}
          />
          <Text>Multi Packet Purchase</Text>
          <Input
            placeholder={multi_buy || "Set Value"}
            value={multi_buy}
            onChange={e => {
              setMultiBuy(e.target.value)
              setChanges(true)
            }}
            type="number"
            style={{ marginBottom: 10 }}
          />

          {
            hasChanges && (
              <React.Fragment>
                <Button
                  onClick={() => {
                    setAddress(queryData.organization.address)
                    setPort(queryData.organization.port)
                    setJoinCreds(queryData.organization.join_credentials)
                    setMultiBuy(queryData.organization.multi_buy)
                    setChanges(false)
                  }}
                  style={{ marginRight: 10 }}
                >
                  Clear
                </Button>
                <Button
                  onClick={() => {
                    updateOrganizationCreds(currentOrganizationId, address, port, join_credentials, multi_buy)
                    .then(res => {
                      if (res.status == 204) setChanges(false)
                    })
                  }}
                  type="primary"
                >
                  Save
                </Button>
              </React.Fragment>
            )
          }
        </div>
      </div>
    </DashboardLayout>
  )
}

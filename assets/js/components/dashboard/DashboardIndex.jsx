import React, { useState, useEffect } from "react";
import { useQuery } from "@apollo/client";
import { useSelector } from "react-redux";
import numeral from "numeral";
import find from "lodash/find";
import DashboardLayout from "../common/DashboardLayout";
import JoinCredentialsForm from "./JoinCredentialsForm";
import { ORGANIZATION_SHOW } from "../../graphql/organizations";
import { updateOrganizationCreds, getNetIds } from "../../actions/organization";
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
  const [netIds, setNetIds] = useState("")

  const currentOrganizationId = useSelector((state) => state.organization.currentOrganizationId);
  const userEmail = useSelector((state) => state.magicUser.email);
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

    if (userEmail === 'jeffrey@helium.com') {
      getNetIds()
      .then(data => setNetIds(data))
    }

    return () => {
      channel.leave();
    };
  }, []);

  useEffect(() => {
    if (queryData && queryData.organization) {
      setAddress(queryData.organization.address)
      setPort(queryData.organization.port)
      setMultiBuy(queryData.organization.multi_buy)
      setJoinCreds(JSON.parse(queryData.organization.join_credentials))
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
        <div style={{ width: 350 }}>
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
          <Text>Join Credentials</Text>
          <JoinCredentialsForm
            join_credentials={join_credentials}
            setJoinCreds={setJoinCreds}
            setChanges={setChanges}
            hasChanges={hasChanges}
          />
          {
            hasChanges && (
              <div style={{ marginTop: 20, display: 'flex', flexDirection: 'row', justifyContent: 'flex-end'}}>
                <Button
                  onClick={() => {
                    setAddress(queryData.organization.address)
                    setPort(queryData.organization.port)
                    setMultiBuy(queryData.organization.multi_buy)
                    setJoinCreds(JSON.parse(queryData.organization.join_credentials))
                    setChanges(false)
                  }}
                  style={{ marginRight: 10 }}
                >
                  Clear
                </Button>
                <Button
                  onClick={() => {
                    const parsedCreds = join_credentials.filter(c => c.dev_eui || c.app_eui)
                    updateOrganizationCreds(currentOrganizationId, address, port, JSON.stringify(parsedCreds), multi_buy)
                    .then(res => {
                      if (res.status == 204) {
                        setJoinCreds(parsedCreds)
                        setChanges(false)
                      }
                    })
                  }}
                  type="primary"
                >
                  Save
                </Button>
              </div>
            )
          }
        </div>
        {
          userEmail === 'jeffrey@helium.com' && (
            <pre>
              {JSON.stringify(netIds, null, 2)}
            </pre>
          )
        }
      </div>
    </DashboardLayout>
  )
}

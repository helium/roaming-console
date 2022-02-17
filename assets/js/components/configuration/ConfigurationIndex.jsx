import React, { useState, useEffect } from "react";
import { useQuery } from "@apollo/client";
import { useSelector } from "react-redux";
import JoinCredentialsForm from "./JoinCredentialsForm";
import { ORGANIZATION_SHOW } from "../../graphql/organizations";
import { updateOrganizationCreds } from "../../actions/organization";
import { Typography, Button, Input } from "antd";
const { Text } = Typography;
import DashboardLayout from "../common/DashboardLayout";

export default (props) => {
  const socket = useSelector((state) => state.apollo.socket);
  const currentOrganizationId = useSelector(
    (state) => state.organization.currentOrganizationId
  );
  const userEmail = useSelector((state) => state.magicUser.email);

  const [address, setAddress] = useState(null);
  const [port, setPort] = useState(null);
  const [join_credentials, setJoinCreds] = useState(null);
  const [multi_buy, setMultiBuy] = useState(null);
  const [hasChanges, setChanges] = useState(false);

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
    if (orgData && orgData.organization) {
      setAddress(orgData.organization.address);
      setPort(orgData.organization.port);
      setMultiBuy(orgData.organization.multi_buy);
      setJoinCreds(JSON.parse(orgData.organization.join_credentials));
    }
  }, [orgData]);

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
        <div style={{ width: 450 }}>
          <Text>Address</Text>
          <Input
            placeholder={address || "Set Address"}
            value={address}
            onChange={(e) => {
              setAddress(e.target.value);
              setChanges(true);
            }}
            style={{ marginBottom: 10 }}
          />
          <Text>Port</Text>
          <Input
            placeholder={port || "Set Port"}
            value={port}
            onChange={(e) => {
              setPort(e.target.value);
              setChanges(true);
            }}
            type="number"
            style={{ marginBottom: 10 }}
          />
          <Text>Multi Packet Purchase</Text>
          <Input
            placeholder={multi_buy || "Set Value"}
            value={multi_buy}
            onChange={(e) => {
              setMultiBuy(e.target.value);
              setChanges(true);
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
          {hasChanges && (
            <div
              style={{
                marginTop: 20,
                display: "flex",
                flexDirection: "row",
                justifyContent: "flex-end",
              }}
            >
              <Button
                onClick={() => {
                  setAddress(orgData.organization.address);
                  setPort(orgData.organization.port);
                  setMultiBuy(orgData.organization.multi_buy);
                  setJoinCreds(
                    JSON.parse(orgData.organization.join_credentials)
                  );
                  setChanges(false);
                }}
                style={{ marginRight: 10 }}
              >
                Clear
              </Button>
              <Button
                onClick={() => {
                  const parsedCreds =
                    join_credentials &&
                    join_credentials.filter((c) => c.dev_eui || c.app_eui);
                  updateOrganizationCreds(
                    currentOrganizationId,
                    address,
                    port,
                    JSON.stringify(parsedCreds),
                    multi_buy
                  ).then((res) => {
                    if (res.status == 204) {
                      setJoinCreds(parsedCreds);
                      setChanges(false);
                    }
                  });
                }}
                type="primary"
              >
                Save
              </Button>
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
};

import React from "react";
import numeral from "numeral";
import find from "lodash/find";
import DashboardLayout from "../common/DashboardLayout";
import NetIdInput from "./NetIdInput";
import analyticsLogger from "../../util/analyticsLogger";
import { Link } from "react-router-dom";
import { Typography, Card, Row, Col, Popover, Button } from "antd";
const { Text } = Typography;
import { primaryBlue, tertiaryPurple } from "../../util/colors";

const styles = {
  numberCount: {
    fontSize: 40,
    marginTop: -8,
  },
};

export default (props) => {
  return (
    <DashboardLayout title="Dashboard" user={props.user}>
      <div
        style={{
          padding: "30px 30px 10px 30px",
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

        <NetIdInput />
      </div>
    </DashboardLayout>
  )
}

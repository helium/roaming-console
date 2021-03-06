import React, { useState, useEffect } from "react";
import { useQuery } from "@apollo/client";
import { useSelector } from "react-redux";
import numeral from "numeral";
import DashboardLayout from "../common/DashboardLayout";
import { ORGANIZATION_SHOW } from "../../graphql/organizations";
import { GET_ORGANIZATION_PACKETS } from "../../graphql/packets";
import analyticsLogger from "../../util/analyticsLogger";
import { Typography, Card, Row, Col, Button, Tooltip, Spin } from "antd";
const { Text } = Typography;
import { primaryBlue, tertiaryPurple } from "../../util/colors";
import { Bar } from "react-chartjs-2";
import range from "lodash/range";
import RedoOutlined from "@ant-design/icons/RedoOutlined";
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip as ChartTooltip,
  Legend,
} from "chart.js";

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  ChartTooltip,
  Legend
);

const styles = {
  numberCount: {
    fontSize: 35,
    marginTop: -8,
  },
};

const chartOptions = {
  borderRadius: 5,
  borderSkipped: false,
  plugins: {
    legend: {
      display: false,
    },
    title: {
      display: true,
      text: "Packets Transferred (last 24 hrs, updated every 5 minutes)",
    },
    tooltip: {
      titleFont: {
        size: 12,
        weight: 400,
      },
      titleMarginBottom: 0,
      bodyFont: {
        size: 12,
        weight: 300,
      },
      footerMarginTop: 10,
      footerFont: {
        size: 10,
        weight: 400,
      },
      footerColor: "#909090",
      displayColors: false,
      callbacks: {
        title: (tooltip) => {
          if (tooltip[0].raw == 0.5) return "0 Packets";
          else
            return `${numeral(tooltip[0].raw).format("0,0")} Packet${
              tooltip[0].raw > 1 || parseInt(tooltip[0].raw) === 0 ? "s" : ""
            }`;
        },
        label: (tooltip) => {
          return `${tooltip.label} Net ID${
            tooltip.label > 1 || parseInt(tooltip.label) === 0 ? "s" : ""
          }`;
        },
        footer: (tooltip) => {
          return `${24 - tooltip[0].dataIndex} ${
            24 - tooltip[0].dataIndex === 1 ? "Hour" : "Hours"
          } Ago`;
        },
      },
    },
  },
  scales: {
    xAxis: {
      display: true,
      title: {
        display: true,
        text: "Time Ago in Hours",
      },
      ticks: {
        display: true,
        callback: (value, index, values) => {
          const list = [24, 12, 6, 3, 1];
          if (list.includes(24 - index)) return 24 - index;
          return "";
        },
      },
      grid: {
        display: false,
      },
    },
    yAxis: {
      display: true,
      title: {
        display: true,
        text: "# of Packets",
      },
      ticks: {
        display: false,
      },
      grid: {
        display: false,
      },
    },
  },
  maintainAspectRatio: false,
};

export default (props) => {
  const currentOrganizationId = useSelector(
    (state) => state.organization.currentOrganizationId
  );

  const {
    loading: packetsLoading,
    error: packetsError,
    data: packetsData,
    refetch: packetsRefetch,
  } = useQuery(GET_ORGANIZATION_PACKETS, {
    fetchPolicy: "cache-first",
    notifyOnNetworkStatusChange: true,
  });

  const {
    loading: orgLoading,
    error: orgError,
    data: orgData,
    refetch: orgRefetch,
  } = useQuery(ORGANIZATION_SHOW, {
    fetchPolicy: "cache-first",
    variables: { id: currentOrganizationId },
  });

  useEffect(() => {
    const autoRefresh = setInterval(() => {
      orgRefetch();
      packetsRefetch();
    }, 300000); // 5 minutes

    return () => {
      clearInterval(autoRefresh);
    };
  }, []);

  const renderChart = () => {
    if (packetsLoading) {
      const labels = range(24, 0).map((index) => {
        return 0;
      });

      const chartData = {
        labels,
        datasets: [
          {
            data: [],
            backgroundColor: "#ACB9CD",
          },
        ],
      };
      return (
        <Spin wrapperClassName="dashboard-packets-loading" tip="Loading...">
          <Bar data={chartData} options={chartOptions} height={300} />
        </Spin>
      );
    } else if (packetsData) {
      const packetsMap = JSON.parse(packetsData.packets.packets_per_hour);

      const data = range(24, 0).map((index) => {
        if (packetsMap[index]) {
          return Object.values(packetsMap[index]).reduce((a, b) => a + b);
        }
        return 0.5;
      });

      const labels = range(24, 0).map((index) => {
        if (packetsMap[index]) {
          return Object.keys(packetsMap[index]).length;
        }
        return 0;
      });

      const backgroundColor = data.map((val) => {
        if (val == 0.5) return "#ACB9CD";
        else return "#2C79EE";
      });

      const chartData = {
        labels,
        datasets: [
          {
            data,
            backgroundColor,
          },
        ],
      };

      return <Bar data={chartData} options={chartOptions} height={300} />;
    } else if (packetsError) {
      return (
        <div style={{ padding: 40, margin: "auto" }}>
          <Text>Data failed to load, please reload the page and try again</Text>
        </div>
      );
    }
  };

  return (
    <DashboardLayout
      title="Dashboard"
      user={props.user}
      extra={
        <Tooltip
          title="Dashboard will automatically refresh every 5 mins."
          placement="bottom"
        >
          <Button
            type="primary"
            icon={<RedoOutlined />}
            style={{ borderRadius: 4 }}
            onClick={() => {
              orgRefetch();
              packetsRefetch();
            }}
          >
            Refresh
          </Button>
        </Tooltip>
      }
    >
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
          <Col span={9}>
            <Card
              title="Total Packets Sent"
              bodyStyle={{ height: 120, padding: 0 }}
              extra={
                <Text style={{ fontSize: 20, color: primaryBlue }}>
                  {numeral(orgData?.organization?.total_packets).format("0,0")}
                </Text>
              }
            >
              <div
                style={{
                  overflowX: "scroll",
                  padding: 20,
                }}
                className="no-scroll-bar"
              >
                <Row style={{ minWidth: 400 }}>
                  <Col span={12}>
                    <Text style={{ fontSize: 16, fontWeight: "300" }}>
                      Last 30 Days
                    </Text>
                    <br />
                    <Text style={{ ...styles.numberCount, color: primaryBlue }}>
                      {numeral(
                        orgData?.organization?.packets_last_30d +
                          packetsData?.packets?.packets_last_1d
                      ).format("0,0")}
                    </Text>
                  </Col>
                  <Col span={12}>
                    <Text style={{ fontSize: 16, fontWeight: "300" }}>
                      Last 24 Hours
                    </Text>
                    <br />
                    <Text style={{ ...styles.numberCount, color: primaryBlue }}>
                      {numeral(packetsData?.packets?.packets_last_1d).format(
                        "0,0"
                      )}
                    </Text>
                  </Col>
                </Row>
              </div>
            </Card>
          </Col>
          <Col span={9}>
            <Card
              title="Total DC Used"
              bodyStyle={{ height: 120, padding: 0 }}
              extra={
                <Text style={{ fontSize: 20, color: tertiaryPurple }}>
                  {numeral(orgData?.organization?.total_dc).format("0,0")}
                </Text>
              }
            >
              <div
                style={{
                  overflowX: "scroll",
                  padding: 20,
                }}
                className="no-scroll-bar"
              >
                <Row style={{ minWidth: 400 }}>
                  <Col span={12}>
                    <Text style={{ fontSize: 16, fontWeight: "300" }}>
                      Last 30 Days
                    </Text>
                    <br />
                    <Text
                      style={{ ...styles.numberCount, color: tertiaryPurple }}
                    >
                      {numeral(
                        orgData?.organization?.dc_last_30d +
                          packetsData?.packets?.dc_last_1d
                      ).format("0,0")}
                    </Text>
                  </Col>
                  <Col span={12}>
                    <Text style={{ fontSize: 16, fontWeight: "300" }}>
                      Last 24 Hours
                    </Text>
                    <br />
                    <Text
                      style={{ ...styles.numberCount, color: tertiaryPurple }}
                    >
                      {numeral(packetsData?.packets?.dc_last_1d).format("0,0")}
                    </Text>
                  </Col>
                </Row>
              </div>
            </Card>
          </Col>
          <Col span={6}>
            <Card
              title="Remaining DC Balance"
              bodyStyle={{ height: 120, padding: 0 }}
            >
              <div
                style={{ overflowX: "scroll", padding: "40px 24px" }}
                className="no-scroll-bar"
              >
                <Row
                  type="flex"
                  style={{ alignItems: "center", minWidth: 300 }}
                >
                  <Text style={{ ...styles.numberCount }}>
                    {numeral(orgData?.organization?.dc_balance).format("0,0")}
                  </Text>
                </Row>
              </div>
            </Card>
          </Col>
        </Row>
        <Row>{renderChart()}</Row>
      </div>
    </DashboardLayout>
  );
};

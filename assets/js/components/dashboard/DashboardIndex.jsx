import React, { useState, useEffect } from "react";
import { useQuery } from "@apollo/client";
import { useSelector } from "react-redux";
import numeral from "numeral";
import DashboardLayout from "../common/DashboardLayout";
import { ORGANIZATION_SHOW } from "../../graphql/organizations";
import { displayError } from "../../util/messages";
import { getPackets } from "../../actions/packets";
import analyticsLogger from "../../util/analyticsLogger";
import { Typography, Card, Row, Col, Button, Input, Tooltip } from "antd";
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
    fontSize: 40,
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
      text: "Packets Transferred",
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
            return `${tooltip[0].raw} Packet${
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
  const [packets, setPackets] = useState([]);
  const currentOrganizationId = useSelector(
    (state) => state.organization.currentOrganizationId
  );

  const getAllPackets = () => {
    getPackets()
      .then((response) => {
        setPackets(response);
      })
      .catch(() => displayError());
  };

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
    getAllPackets();
  }, []);

  useEffect(() => {
    const autoRefresh = setInterval(() => {
      orgRefetch();
      getAllPackets();
    }, 300000); // 5 minutes

    return () => {
      clearInterval(autoRefresh);
    };
  }, []);

  const renderChart = () => {
    if (packetsData) {
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

      return <Bar data={chartData} options={chartOptions} height={250} />;
    }
    return <div />;
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
              getAllPackets();
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
          <Col span={8}>
            <Card
              title="Total Packets Sent (Last 30 Days)"
              bodyStyle={{ height: 90, padding: 0 }}
            >
              <div
                style={{ overflowX: "scroll", padding: 24 }}
                className="no-scroll-bar"
              >
                <Row
                  type="flex"
                  style={{ alignItems: "center", minWidth: 300 }}
                >
                  <Text style={{ ...styles.numberCount, color: primaryBlue }}>
                    {numeral(
                      orgData && orgData.organization.total_packets_sent
                    ).format("0,0")}
                  </Text>
                </Row>
              </div>
            </Card>
          </Col>
          <Col span={8}>
            <Card
              title="Total DC Used (Last 30 Days)"
              bodyStyle={{ height: 90, padding: 0 }}
            >
              <div
                style={{ overflowX: "scroll", padding: 24 }}
                className="no-scroll-bar"
              >
                <Row
                  type="flex"
                  style={{ alignItems: "center", minWidth: 300 }}
                >
                  <Text
                    style={{ ...styles.numberCount, color: tertiaryPurple }}
                  >
                    {numeral(
                      orgData && orgData.organization.total_dc_used
                    ).format("0,0")}
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
              <div
                style={{ overflowX: "scroll", padding: 24 }}
                className="no-scroll-bar"
              >
                <Row
                  type="flex"
                  style={{ alignItems: "center", minWidth: 300 }}
                >
                  <Text style={{ ...styles.numberCount }}>
                    {numeral(orgData && orgData.organization.dc_balance).format(
                      "0,0"
                    )}
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

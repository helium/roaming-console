import React, { Component } from "react";
import TopBar from "./TopBar";
import NavDrawer from "./NavDrawer";
import ContentLayout from "./ContentLayout";
import { Layout, Popover, Button } from "antd";
import ToolOutlined from "@ant-design/icons/ToolOutlined";
const { Header, Sider, Content } = Layout;

class DashboardLayout extends Component {
  state = {
    showNav: true,
  };

  toggleNav = () => {
    this.setState({ showNav: !this.state.showNav });
  };

  render() {
    const {
      title,
      extra,
      user,
    } = this.props;

    return (
      <Layout style={{ height: "100%", width: "100%" }}>
        <Header>
          <TopBar
            user={user}
            toggleNav={this.toggleNav}
            showNav={this.state.showNav}
          />
        </Header>

        <Layout style={{ height: "calc(100vh - 64px)" }}>
          <Sider
            style={{
              overflow: "hidden",
              display: this.state.showNav ? "block" : "none",
            }}
          >
            <NavDrawer user={user} />
            {process.env.CONSOLE_VERSION && (
              <Popover
                content="Click to see release details"
                placement="right"
              >
                <Button
                  className="version-link"
                  icon={<ToolOutlined />}
                  href={
                    process.env.RELEASE_BLOG_LINK ||
                    "https://engineering.helium.com"
                  }
                  target="_blank"
                >
                  {process.env.CONSOLE_VERSION}
                </Button>
              </Popover>
            )}
          </Sider>
          <Layout>
            <Content>
              <ContentLayout
                title={title}
                extra={extra}
              >
                {this.props.children}
              </ContentLayout>
            </Content>
          </Layout>
        </Layout>
      </Layout>
    );
  }
}

export default DashboardLayout;

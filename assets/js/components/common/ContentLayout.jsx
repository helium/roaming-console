import React, { Component } from "react";
import { withRouter } from "react-router";
import { PageHeader } from "antd";

@withRouter
class ContentLayout extends Component {
  render() {
    const { title, extra } = this.props;

    return (
      <div
        style={{
          padding: 30,
          paddingBottom: 30,
          height: "auto",
          minHeight: "100%",
          backgroundColor: "#F5F7F9",
        }}
      >
        <PageHeader
          backIcon={false}
          title={title}
          subTitle=""
          extra={extra}
          style={{ paddingRight: 3, paddingBottom: 30 }}
        />
        {this.props.children}
      </div>
    );
  }
}

export default ContentLayout;

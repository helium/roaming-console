import React, { Component } from "react";
import { Typography, Button, Input } from "antd";
const { Text } = Typography;
import { Row, Col } from "antd";

class JoinCredentialsForm extends Component {
  state = {
    credentials: [{ dev_eui: "", app_eui: "" }]
  }

  componentDidUpdate(prevProps) {
    if (!prevProps.join_credentials && this.props.join_credentials) {
      this.setState({ credentials: this.props.join_credentials })
    }

    if (prevProps.hasChanges && !this.props.hasChanges) {
      this.setState({ credentials: this.props.join_credentials })
    }
  }

  addHeaderRow = () => {
    const credentials = [...this.state.credentials, { dev_eui: "", app_eui: "" }];
    this.setState({ credentials })
  };

  handleHttpHeaderUpdate = (e) => {
    let index, input;
    [index, input] = e.target.name.split("-");

    const updatedEntry = Object.assign({}, this.state.credentials[index], {
      [input]: e.target.value,
    });
    const updatedCredentials = this.state.credentials;
    updatedCredentials[index] = updatedEntry;

    this.setState({ credentials: updatedCredentials })
    this.props.setJoinCreds(updatedCredentials)
    this.props.setChanges(true)
  };

  render() {
    return (
      <div>
        {this.state.credentials.map((obj, i) => (
          <Row gutter={16} style={{ marginBottom: 8 }} key={`${i}-key`}>
            <Col sm={12}>
              <Input
                placeholder="Dev EUI"
                name={`${i}-dev_eui`}
                value={obj.dev_eui}
                onChange={this.handleHttpHeaderUpdate}
                style={{ width: "100%" }}
              />
            </Col>
            <Col sm={12}>
              <Input
                placeholder="App EUI"
                name={`${i}-app_eui`}
                value={obj.app_eui}
                onChange={this.handleHttpHeaderUpdate}
                style={{ width: "100%" }}
              />
            </Col>
          </Row>
        ))}
        <Row>
          <Button
            onClick={this.addHeaderRow}
          >
            Add Header
          </Button>
        </Row>
      </div>
    );
  }
}

export default JoinCredentialsForm;

import React, { Component } from "react";
import { Typography, Button, Input, Popover } from "antd";
const { Text } = Typography;
import { Row, Col } from "antd";
import Modal from "antd/lib/modal/Modal";
import DragAndDrop from "./DragAndDrop";
import { secondaryBlue } from "../../util/colors";
import Papa from "papaparse";
import { displayError } from "../../util/messages";

class JoinCredentialsForm extends Component {
  state = {
    credentials: [{ dev_eui: "", app_eui: "" }],
    showCSVModal: false,
  };

  componentDidUpdate(prevProps) {
    if (!prevProps.join_credentials && this.props.join_credentials) {
      this.setState({ credentials: this.props.join_credentials });
    }

    if (prevProps.hasChanges && !this.props.hasChanges) {
      this.setState({ credentials: this.props.join_credentials });
    }
  }

  addCredentialRow = () => {
    const credentials = [
      ...this.state.credentials,
      { dev_eui: "", app_eui: "" },
    ];
    this.setState({ credentials });
  };

  handleCredentialUpdate = (e) => {
    let index, input;
    [index, input] = e.target.name.split("-");

    const updatedEntry = Object.assign({}, this.state.credentials[index], {
      [input]: e.target.value,
    });
    const updatedCredentials = this.state.credentials;
    updatedCredentials[index] = updatedEntry;

    this.setState({ credentials: updatedCredentials });
    this.props.setJoinCreds(updatedCredentials);
    this.props.setChanges(true);
  };

  render() {
    return (
      <>
        <div>
          {this.state.credentials &&
            this.state.credentials.map((obj, i) => (
              <Row gutter={16} style={{ marginBottom: 8 }} key={`${i}-key`}>
                <Col sm={12}>
                  <Input
                    placeholder="Dev EUI"
                    name={`${i}-dev_eui`}
                    value={obj.dev_eui}
                    onChange={this.handleCredentialUpdate}
                    style={{ width: "100%" }}
                  />
                </Col>
                <Col sm={12}>
                  <Input
                    placeholder="App EUI"
                    name={`${i}-app_eui`}
                    value={obj.app_eui}
                    onChange={this.handleCredentialUpdate}
                    style={{ width: "100%" }}
                  />
                </Col>
              </Row>
            ))}
          <Row>
            <Button onClick={this.addCredentialRow}>Add Credential</Button>
            <Button
              style={{ marginLeft: 5 }}
              onClick={() => {
                this.setState({ showCSVModal: true });
              }}
            >
              Use CSV File
            </Button>
          </Row>
        </div>
        <Modal
          visible={this.state.showCSVModal}
          centered
          title="Upload Join Credentials through CSV File"
          onCancel={() => {
            this.setState({ showCSVModal: false });
          }}
        >
          <div style={{ textAlign: "center", marginBottom: 10 }}>
            <Text style={{}}>
              You can import your join credentials in bulk via .csv upload.
            </Text>
            <br />
            <Popover
              trigger="click"
              content={
                <Text
                  style={{ display: "table", whiteSpace: "normal", width: 200 }}
                >
                  Your CSV file must have <b>app_eui, dev_eui</b> in the header
                  row, followed by rows of the corresponding values.
                </Text>
              }
            >
              <a className="help-link" style={{ marginBottom: 20 }}>
                How do I format my .csv?
              </a>
            </Popover>
          </div>
          <DragAndDrop
            fileSelected={(file) => {
              Papa.parse(file, {
                header: true,
                complete: (results) => {
                  if (
                    Object.keys(results.data[0]).length === 2 &&
                    Object.keys(results.data[0]).includes("app_eui") &&
                    Object.keys(results.data[0]).includes("dev_eui")
                  ) {
                    this.setState({
                      credentials: results.data,
                      showCSVModal: false,
                    });
                    this.props.setChanges(true);
                    this.props.setJoinCreds(results.data);
                  } else {
                    displayError(
                      "Please make sure your CSV file is formatted properly and try again."
                    );
                  }
                },
              });
            }}
          >
            <Text
              style={{
                textAlign: "center",
                margin: "30px 80px",
                color: secondaryBlue,
              }}
            >
              Drag .csv file here or click to choose file
            </Text>
          </DragAndDrop>
        </Modal>
      </>
    );
  }
}

export default JoinCredentialsForm;

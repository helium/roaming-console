import React from "react";
import { Typography, Popover } from "antd";
const { Text } = Typography;
import Modal from "antd/lib/modal/Modal";
import DragAndDrop from "./DragAndDrop";
import { secondaryBlue } from "../../util/colors";
import Papa from "papaparse";
import { displayError } from "../../util/messages";

export default ({ open, close, updateCredentials }) => (
  <Modal
    visible={open}
    centered
    title="Upload Join Credentials through CSV File"
    onCancel={close}
  >
    <div style={{ textAlign: "center", marginBottom: 10 }}>
      <Text style={{}}>
        You can import your join credentials in bulk via .csv upload.
      </Text>
      <br />
      <Popover
        trigger="click"
        content={
          <Text style={{ display: "table", whiteSpace: "normal", width: 200 }}>
            Your CSV file must have <b>app_eui, dev_eui</b> in the header row,
            followed by rows of the corresponding values.
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
              updateCredentials(results.data);
              close();
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
);

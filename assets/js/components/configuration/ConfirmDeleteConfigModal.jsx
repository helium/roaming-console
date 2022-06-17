import React from "react";
import { Typography, Button } from "antd";
const { Text } = Typography;
import Modal from "antd/lib/modal/Modal";

export default ({ open, close, handleSubmit, config }) => (
  <Modal
    visible={open}
    centered
    title="Remove Configuration"
    onCancel={close}
    footer={[
      <Button key="back" onClick={close}>
        Cancel
      </Button>,
      <Button key="submit" type="primary" onClick={handleSubmit} danger>
        Submit
      </Button>,
    ]}
  >
    <div style={{ textAlign: "center" }}>
      <Text>
        Are you sure you want to remove this Configuration for Net ID{" "}
        {config.netIdValue}? This action cannot be undone.
      </Text>
    </div>
  </Modal>
);

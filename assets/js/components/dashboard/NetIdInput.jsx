import React, { useState } from "react";
import { Typography, Input, Button } from "antd";
import { setNetIds } from '../../actions/netIds'
const { Text } = Typography;

export default (props) => {
  const [input, setInput] = useState("")
  const handleInputUpdate = (e) => setInput(e.target.value)

  return (
    <div>
      <Text>Set Net Ids</Text>
      <Input value={input} onChange={handleInputUpdate} />
      <Button onClick={() => setNetIds(input)}>Submit</Button>
    </div>
  )
}

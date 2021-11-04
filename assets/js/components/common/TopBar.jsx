import React, { Component } from 'react'
import { connect } from 'react-redux'
import withGql from '../../graphql/withGql'
import { bindActionCreators } from 'redux'
import { push } from 'connected-react-router';
import MediaQuery from 'react-responsive'
import numeral from 'numeral'
import DCIMg from '../../../img/datacredits.svg'
import DCIMgDark from '../../../img/datacredits-dark.svg'
import { logOut } from '../../actions/auth'
import analyticsLogger from '../../util/analyticsLogger'
import { ORGANIZATION_SHOW_DC } from '../../graphql/organizations'
import { redForTablesDeleteText } from '../../util/colors'
import { Menu, Dropdown, Typography, Tooltip } from 'antd';
import MenuFoldOutlined from '@ant-design/icons/MenuFoldOutlined';
import MenuUnfoldOutlined from '@ant-design/icons/MenuUnfoldOutlined';
const { Text } = Typography
import Logo from '../../../img/logo-horizontalwhite-symbol.svg'
import ProfileActive from '../../../img/topbar-pf-active.png'
import ProfileInactive from '../../../img/topbar-pf-inactive.svg'

class TopBar extends Component {
  state = {
    userMenuVisible: false,
  }

  handleClick = e => {
    if (e.key === 'logout') {
      this.props.logOut()
    } else {
      this.props.push(e.key)
    }
  }

  refreshDC = visible => {
    if (visible) this.props.orgShowQuery.refetch()
  }

  render() {
    const { currentOrganizationName, user, orgShowQuery, toggleNav } = this.props;
    const organization = orgShowQuery.organization || null

    return (
      <div style={{ display: 'flex', flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <img draggable="false" src={Logo} style={{height:33, position: 'relative', top: '-1px', display: 'inline-block'}}/>
          {
            this.props.showNav ? (
              <MenuFoldOutlined
                style={{ color: '#ffffff', fontSize: 18, marginLeft: 8, position: 'relative', top: 3}}
                onClick={this.props.toggleNav}
              />
            ) : (
              <MenuUnfoldOutlined
                style={{ color: '#ffffff', fontSize: 18, marginLeft: 8, position: 'relative', top: 3}}
                onClick={this.props.toggleNav}
              />
            )
          }
        </div>

        {
          organization && (
            <Tooltip
              title={
                <span
                  style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', cursor: 'pointer' }}
                  onClick={() => this.props.push("/datacredits")}
                  className="noselect"
                >
                  <Text style={{ color: organization.dc_balance > 1000 ? '#ffffff' : '#FF4D4F', fontWeight: 600, fontSize: 16 }}>{organization.dc_balance > 1000 ? "DC Balance" : "Your DC Balance is Low"}</Text>
                  <Text style={{ color: '#ffffff' }}>{organization.dc_balance > 1000 ? "Click here to Manage" : "Click here to Top Up"}</Text>
                </span>
              }
              onVisibleChange={this.refreshDC}
            >
              <div style={{ height: 30, backgroundColor: organization.dc_balance > 1000 ? '#000000' : '#FF4D4F', borderRadius: 30, paddingLeft: 10, paddingRight: 10, marginRight: 15 }}>
                <img draggable="false" style={{ width: 15, position: 'relative', top: -13, marginRight: 4 }} src={organization.dc_balance > 1000 ? DCIMg : DCIMgDark} />
                  <Text
                    className="noselect"
                    style={{ color: organization.dc_balance > 1000 ? 'white' : 'black', position: 'relative', top: -12, cursor: 'default' }}
                  >
                    {numeral(organization.dc_balance).format('0,0')}
                  </Text>
              </div>
            </Tooltip>
          )
        }

        <div style={{ display: 'flex', flexDirection: 'row', alignItems: 'center' }}>
          <MediaQuery minWidth={720}>
            <div style={{ display: 'flex', flexDirection: 'column', height: 55, alignItems: 'flex-end'}}>
              <Text className="noselect" style={{ color: "#FFFFFF", fontWeight: 500, position: 'relative', top: -7 }}>{user && user.email}</Text>
              <div style={{ position: 'relative', top: -45 }}>
                <Text className="noselect" style={{ color: "#FFFFFF", fontWeight: 500 }}>{currentOrganizationName}</Text>
              </div>
            </div>
          </MediaQuery>
          <Dropdown overlay={menu(this.handleClick, currentOrganizationName)} trigger={['click']} onVisibleChange={visible => this.setState({ userMenuVisible: visible })}>
            <img draggable="false" src={this.state.userMenuVisible ? ProfileActive : ProfileInactive} style={{ height:30, marginLeft: 15, cursor: 'pointer' }}/>
          </Dropdown>
        </div>
      </div>
    )
  }
}

const menu = (handleClick, currentOrganizationName) => (
  <Menu onClick={handleClick} style={{ textAlign: 'right' }}>
    {
      currentOrganizationName && (
        <Menu.Item key="/profile">
          <Text className="noselect">My Account</Text>
        </Menu.Item>
      )
    }
    <Menu.Item key="logout">
      <Text className="noselect" style={{ color: redForTablesDeleteText }}>Log Out</Text>
    </Menu.Item>
  </Menu>
)

function mapStateToProps(state, ownProps) {
  return {
    currentOrganizationName: state.organization.currentOrganizationName,
    currentOrganizationId: state.organization.currentOrganizationId,
    socket: state.apollo.socket,
  }
}

function mapDispatchToProps(dispatch) {
  return bindActionCreators({ logOut, push }, dispatch);
}

export default connect(mapStateToProps, mapDispatchToProps)(
  withGql(TopBar, ORGANIZATION_SHOW_DC, props => ({ fetchPolicy: 'cache-first', variables: { id: props.currentOrganizationId }, name: 'orgShowQuery' }))
)

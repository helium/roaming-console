import * as rest from '../util/rest';
import { logoutUser } from './magic'
import analyticsLogger from '../util/analyticsLogger';

export const SET_MAGIC_USER = 'SET_MAGIC_USER';
export const CLEAR_MAGIC_USER = 'CLEAR_MAGIC_USER';

export const logOut = () => {
  analyticsLogger.setUserId(null)

  return async (dispatch) => {
    localStorage.removeItem("organization");

    await logoutUser()
    dispatch(clearMagicUser())
    window.location.replace("/")
  }
}

export const magicLogIn = (user) => {
  return {
    type: SET_MAGIC_USER,
    payload: user
  }
}

export const clearMagicUser = () => {
  return {
    type: CLEAR_MAGIC_USER,
  }
}

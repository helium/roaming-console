export const minWidth = 700;

export const decimalToHex = (value) =>
  parseInt(value, 10).toString(16).padStart(6, 0).toUpperCase();

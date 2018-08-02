import * as MapIcons from "./icons";

export const iconSize = size => {
  let val;
  switch (size) {
    case "tiny":
      val = 8;
      break;
    case "small":
      val = 12;
      break;
    case "large":
      val = 48;
      break;
    default:
      val = 22; // "mid" sized
      break;
  }

  return val;
};

export const iconSvg = marker => {
  const parts = marker.split("-");
  const id = parts.shift();
  const type = parts.join("-");

  let icon;

  switch (type) {
    case "dot":
      icon = MapIcons.iconDot(id);
      break;

    case "dot-filled":
      icon = MapIcons.iconDotFilled(id);
      break;

    case "dot-filled-mid":
      icon = MapIcons.iconDotFilledMid(id);
      break;

    case "dot-mid":
      icon = MapIcons.iconDotMid(id);
      break;

    case "vehicle":
      icon = MapIcons.iconVehicle(id);
      break;

    case "mode":
      icon = MapIcons.iconMode(id);
      break;

    case "pin":
      icon = MapIcons.iconPin();
      break;

    default:
      throw new Error(`unknown icon ${type}`);
  }

  return icon;
};

const labelOrigin = (icon, size) => {
  if (icon === "map-pin") {
    return new window.google.maps.Point(size / 2, size / 2 - 4);
  }

  return null;
};

const iconAnchor = (icon, size) => {
  if (icon === "map-pin") {
    return new window.google.maps.Point(size / 2, size);
  }
  return new window.google.maps.Point(size / 2, size / 2);
}

export const buildIcon = (iconData, size) => {
  const sizeInt = iconSize(size);

  const encoded = window.btoa(iconSvg(iconData));

  return {
    url: `data:image/svg+xml;base64, ${encoded}`,
    scaledSize: new window.google.maps.Size(sizeInt, sizeInt),
    origin: new window.google.maps.Point(0, 0),
    anchor: iconAnchor(iconData, sizeInt),
    labelOrigin: labelOrigin(iconData, sizeInt)
  };
};

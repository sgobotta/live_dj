export function secondsToTime(seconds) {
  const hours   = Math.floor(seconds / 3600);
  let minutes = Math.floor((seconds - (hours * 3600)) / 60);
  const _seconds = seconds - (hours * 3600) - (minutes * 60);
  var time = "";

  if (hours != 0) {
    time = hours+":";
  }
  if (minutes != 0 || time !== "") {
    minutes = (minutes < 10 && time !== "") ? "0"+minutes : String(minutes);
    time += minutes+":";
  } else {
    time += "0:"
  }
  if (time === "") {
    time = _seconds;
  }
  else {
    time += (_seconds < 10) ? "0"+_seconds : String(_seconds);
  }
  return time;
}

import { createClient } from "@boldvideo/bold-js";

import "vidstack/player";
import "vidstack/player/layouts/default";
import "vidstack/player/ui";

import "hls.js";

let base = new URL("/api/bold/", window.location.href);
let baseUrl = new URL("api/v1/", base);

const bold = createClient("NO_API_KEY_HERE", {
  baseURL: baseUrl.href,
  debug: false,
});

document.querySelectorAll("media-player").forEach((player) => {
  const video = {
    id: player.dataset.id,
    title: player.title,
    duration: player.duration,
  };

  const handleEvent = (evt) => {
    bold.trackEvent(video, evt);
  };

  const handleTimeUpdateEvent = (_evt, nativeEvt) => {
    bold.trackEvent(video, nativeEvt);
  };

  player.addEventListener("play", handleEvent);
  player.addEventListener("pause", handleEvent);
  player.addEventListener("loaded-metadata", handleEvent);
  player.addEventListener("time-update", handleTimeUpdateEvent);
});

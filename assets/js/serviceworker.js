"use strict";

const version = "20241231";
const staticCacheName = "static-" + version;
const cacheList = [staticCacheName];

async function updateStaticCache() {
  let response = await fetch("/cache");
  let json = await response.json();
  let staticCache = await caches.open(staticCacheName);
  staticCache.addAll(json.static);
}

async function clearOldCaches() {
  let keys = await caches.keys();
  return Promise.all(
    keys
      .filter((key) => !cacheList.includes(key))
      .map((key) => caches.delete(key)),
  );
}

addEventListener("install", (installEvent) => {
  installEvent.waitUntil(updateStaticCache());
  skipWaiting();
});

addEventListener("activate", (activateEvent) => {
  activateEvent.waitUntil(clearOldCaches());
  clients.claim();
});

addEventListener("fetch", (fetchEvent) => {
  let request = fetchEvent.request;
  let url = new URL(request.url);

  // Only deal with requests to my own server
  if (url.origin !== location.origin) {
    return;
  }

  // Only deal with GET requests
  if (request.method !== "GET") {
    return;
  }

  // For HTML requests, try the preload first, then network, fall back to the cache, finally the offline page
  if (
    request.mode === "navigate" ||
    request.headers.get("Accept").includes("text/html")
  ) {
    return;
  }

  // For non-HTML requests, look in the cache first, fall back to the network
  fetchEvent.respondWith(
    caches.match(request).then((responseFromCache) => {
      return responseFromCache || fetch(request);
    }),
  );
});

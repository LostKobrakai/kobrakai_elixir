export async function cacheMacro() {
  let manifest = await cache_manifest_or_default();

  console.log(manifest);

  let base = [
    "assets/video.js",
    "assets/app.css",
    "assets/app.js",
    "images/signee.png",
    "images/pfeil.png",
    "images/avatar.jpg",
    "font/noway-regular-webfont.woff",
    "font/noway-regular-webfont.woff2",
    "font/Virgil.woff2",
  ];

  let cache = base.map((key) => {
    let digested = manifest.latest[key];
    if (!digested)
      return {
        key: key,
        sha512: null,
        path: "/" + key,
      };
    return {
      key: digested,
      sha512: manifest.digests[key]?.sha512,
      path: "/" + digested + "?vsn=d",
    };
  });

  let hash = cache
    .flatMap((entry) => {
      if (!entry.sha512) return [];
      return [entry.sha512];
    })
    .reduce((hasher, sha) => hasher.update(sha), new Bun.CryptoHasher("sha512"))
    .digest("base64");

  return {
    cache: cache.map((entry) => entry.path),
    hash: hash,
  };
}

async function cache_manifest_or_default() {
  return import("./../../../priv/static/cache_manifest.json").catch((_err) => ({
    latest: [],
    digests: [],
  }));
}

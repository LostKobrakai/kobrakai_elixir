function appendText(el, type, text) {
  let li = document.createElement("li");
  li.innerHTML = `
  ${icon(type)}
  ${text}
  `;
  el.append(li);

  el.scroll({
    top: el.scrollHeight,
    left: 0,
    behavior: 'smooth'
  });
}

function icon(type) {
  switch (type) {
    case "up":
      return `<span class="hero-arrow-up h-4 w-4 mb-2"></span>`;
    case "down":
      return `<span class="hero-arrow-down h-4 w-4 mb-2"></span>`;
    case "right":
      return `<span class="hero-arrow-right h-4 w-4 mb-2"></span>`;
    case "none":
      return "";
  }
}

function start(url, list) {
  let socket = new WebSocket(url);

  socket.onopen = (_event) => {
    appendText(list, "none", `Connected to ${url}`)
  };

  socket.onmessage = (event) => {
    appendText(list, "down", `"${event.data}"`)
  };

  socket.onerror = (event) => {
    appendText(list, "none", `Got an error: ${event.data}`)
  };

  socket.onclose = (event) => {
    appendText(list, "none", `Connection closed: ${event.code}`)
  };

  return socket;
}

function stop(socket) {
  socket.close();
}

export default {
  mounted() {
    this.el.querySelector("[data-tag=init]").remove();
    let list = this.el.querySelector("[data-tag=list]");
    this.el.append(list);

    this.el.addEventListener("request", () => {
      appendText(list, "up", `"request_timer"`)
      this.socket.send("request_timer");
    })

    this.list = list;
    this.socket = start(this.el.dataset.url, list);
  },
  reconnected() {
    stop(this.socket)
    this.socket = start(this.el.dataset.url, list);
  }
}
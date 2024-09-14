function darkExpected() {
  return (
    (!window.matchMedia("print").matches && localStorage.theme === "dark") ||
    (!("theme" in localStorage) &&
      window.matchMedia("(prefers-color-scheme: dark)").matches)
  );
}

function initDarkMode() {
  // On page load or when changing themes, best to add inline in `head` to avoid FOUC
  if (darkExpected()) document.documentElement.classList.add("dark");
  else document.documentElement.classList.remove("dark");
}

export function handleDarkMode() {
  window.addEventListener("toogle-darkmode", (e) => {
    if (darkExpected()) localStorage.theme = "light";
    else localStorage.theme = "dark";
    initDarkMode();
  });

  initDarkMode();
}

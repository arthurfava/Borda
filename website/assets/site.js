document.querySelector("[data-language]")?.addEventListener("change", event => {
  window.location.assign(event.currentTarget.value);
});

const note = document.querySelector("[data-download-note]");
document.querySelectorAll("[data-download]").forEach(link => link.addEventListener("click", () => {
  if (!note) return;
  note.hidden = false;
  requestAnimationFrame(() => note.classList.add("visible"));
}));
note?.querySelector("button")?.addEventListener("click", () => {
  note.classList.remove("visible");
  window.setTimeout(() => { note.hidden = true; }, 220);
});

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

const motionDemo = document.querySelector("[data-motion-demo]");
if (motionDemo) {
  const restartMotion = () => {
    motionDemo.classList.remove("is-playing");
    void motionDemo.offsetWidth;
    motionDemo.classList.add("is-playing");
  };
  const observer = new IntersectionObserver(entries => {
    for (const entry of entries) {
      if (entry.isIntersecting) restartMotion();
      else motionDemo.classList.remove("is-playing");
    }
  }, { threshold: 0.35 });
  observer.observe(motionDemo);
  motionDemo.querySelector("[data-motion-replay]")?.addEventListener("click", restartMotion);
}

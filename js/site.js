(() => {
  const root = document.documentElement;

  // ---- theme: follows the OS until the reader picks one
  try {
    const saved = localStorage.getItem("theme");
    if (saved) root.dataset.theme = saved;
  } catch (_) {}
  document.getElementById("theme-toggle").addEventListener("click", () => {
    const dark = root.dataset.theme
      ? root.dataset.theme === "dark"
      : matchMedia("(prefers-color-scheme: dark)").matches;
    root.dataset.theme = dark ? "light" : "dark";
    try { localStorage.setItem("theme", root.dataset.theme); } catch (_) {}
  });

  // ---- looping clips only play while on screen
  const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches;
  const io = new IntersectionObserver((entries) => {
    for (const e of entries) {
      const v = e.target;
      if (e.isIntersecting && !reduced) v.play().catch(() => {});
      else v.pause();
    }
  }, { threshold: 0.35 });
  const watch = (v) => { if (v.hasAttribute("data-autoplay")) io.observe(v); };
  document.querySelectorAll("video[data-autoplay]").forEach(watch);

  // ---- players: optional tab row (groups) -> chip row (clips) -> one <video>
  document.querySelectorAll("[data-player]").forEach((player) => {
    const video = player.querySelector("video");
    const caption = player.querySelector("[data-caption-slot]");
    const tabs = [...player.querySelectorAll('[role="tab"]')];
    const groups = [...player.querySelectorAll(".chips")];

    const load = (chip) => {
      groups.forEach((g) => g.querySelectorAll("button").forEach((b) =>
        b.setAttribute("aria-pressed", String(b === chip))));
      const name = chip.dataset.src;
      if (!video.src.endsWith(`/${name}.mp4`)) {
        video.poster = `media/poster/${name}.webp`;
        video.src = `media/video/${name}.mp4`;
        if (!reduced) video.play().catch(() => {});
      }
      if (caption) caption.innerHTML = chip.dataset.caption || "";
    };

    groups.forEach((g) => g.addEventListener("click", (e) => {
      const b = e.target.closest("button");
      if (b) load(b);
    }));

    tabs.forEach((tab) => tab.addEventListener("click", () => {
      tabs.forEach((t) => t.setAttribute("aria-selected", String(t === tab)));
      groups.forEach((g) => { g.hidden = g.dataset.for !== tab.dataset.group; });
      load(player.querySelector(`.chips[data-for="${tab.dataset.group}"] button`));
    }));

    // arrow keys move between tabs
    tabs.forEach((tab, i) => tab.addEventListener("keydown", (e) => {
      const d = { ArrowRight: 1, ArrowLeft: -1 }[e.key];
      if (!d) return;
      const next = tabs[(i + d + tabs.length) % tabs.length];
      next.focus(); next.click();
    }));

    const first = player.querySelector('.chips:not([hidden]) button[aria-pressed="true"]');
    if (first && caption) caption.innerHTML = first.dataset.caption || "";
  });

  // ---- BibTeX copy
  const copy = document.getElementById("copy-bib");
  copy.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(document.getElementById("bibtex").textContent);
      copy.textContent = "Copied";
    } catch (_) {
      copy.textContent = "Select & copy";
    }
    setTimeout(() => { copy.textContent = "Copy"; }, 1600);
  });
})();

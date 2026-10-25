const root = document.documentElement;
const storageKey = "klyvera-theme";

function applyTheme(theme: string | null) {
  if (theme === "light" || theme === "dark" || theme === "high-contrast") {
    root.setAttribute("data-theme", theme);
  } else {
    root.removeAttribute("data-theme");
  }
}

const saved = localStorage.getItem(storageKey);
applyTheme(saved);

const toggles = document.querySelectorAll("[data-theme-toggle]");
toggles.forEach((btn) => {
  btn.addEventListener("click", () => {
    const currentAttr = root.getAttribute("data-theme");
    let current: "dark" | "light" | "high-contrast" | null = null;
    if (currentAttr === "light" || currentAttr === "dark" || currentAttr === "high-contrast") {
      current = currentAttr;
    }
    const order: Array<"dark" | "light" | "high-contrast" | null> = ["dark", "light", "high-contrast", null];
    const idx = order.indexOf(current);
    const nextIdx = (idx + 1) % order.length;
    const next = order[nextIdx] as "dark" | "light" | "high-contrast" | null;
    if (next === null) {
      applyTheme(null);
      try { localStorage.removeItem(storageKey); } catch {}
    } else {
      applyTheme(next);
      try { localStorage.setItem(storageKey, next); } catch {}
    }
  });
});

const menuBtnEl = document.querySelector("[data-menu-toggle]");
const menuEl = document.querySelector("[data-mobile-menu]");
if (menuBtnEl && menuEl) {
  const menuBtn = menuBtnEl as HTMLButtonElement;
  const menu = menuEl as HTMLElement;
  menuBtn.addEventListener("click", () => {
    const open = menu.classList.toggle("open");
    menuBtn.setAttribute("aria-expanded", open ? "true" : "false");
  });
  menu.querySelectorAll("a").forEach((a) => {
    a.addEventListener("click", () => {
      menu.classList.remove("open");
      menuBtn.setAttribute("aria-expanded", "false");
    });
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") {
      menu.classList.remove("open");
      menuBtn.setAttribute("aria-expanded", "false");
    }
  });
}

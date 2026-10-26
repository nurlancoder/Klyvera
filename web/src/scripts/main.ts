const root = document.documentElement;
const storageKey = "klyvera-theme";
const themes = ["dark", "light", "high-contrast"] as const;
type Theme = (typeof themes)[number];

function isTheme(theme: string | null): theme is Theme {
  return themes.some((candidate) => candidate === theme);
}

function applyTheme(theme: Theme) {
  root.setAttribute("data-theme", theme);
}

let savedTheme: string | null = null;
try {
  savedTheme = localStorage.getItem(storageKey);
} catch {
  savedTheme = null;
}
applyTheme(isTheme(savedTheme) ? savedTheme : "dark");

const toggles = document.querySelectorAll("[data-theme-toggle]");
toggles.forEach((btn) => {
  btn.addEventListener("click", () => {
    const current = root.getAttribute("data-theme");
    const next: Theme = current === "dark" ? "light" : current === "light" ? "high-contrast" : "dark";
    applyTheme(next);
    try {
      localStorage.setItem(storageKey, next);
    } catch {
      return;
    }
  });
});

const menuBtnEl = document.querySelector("[data-menu-toggle]");
const menuEl = document.querySelector("[data-mobile-nav]");
if (menuBtnEl && menuEl) {
  const menuBtn = menuBtnEl as HTMLButtonElement;
  const menu = menuEl as HTMLElement;
  const closeMenu = (returnFocus: boolean) => {
    menu.hidden = true;
    menuBtn.setAttribute("aria-expanded", "false");
    if (returnFocus) menuBtn.focus();
  };

  menuBtn.addEventListener("click", () => {
    const open = menu.hidden;
    menu.hidden = !open;
    menuBtn.setAttribute("aria-expanded", open ? "true" : "false");
    if (open) menu.querySelector("a")?.focus();
  });
  menu.querySelectorAll("a").forEach((a) => {
    a.addEventListener("click", () => {
      closeMenu(false);
    });
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && !menu.hidden) {
      closeMenu(true);
    }
  });
}

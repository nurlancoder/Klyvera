type Theme = "dark" | "light" | "high-contrast";

const root = document.documentElement;
const isAzerbaijani = root.lang === "az";

const copy = isAzerbaijani
  ? {
      theme: "Rəng teması",
      dark: "Tünd",
      light: "İşıqlı",
      "high-contrast": "Yüksək kontrast",
      openMenu: "Menyunu aç",
      closeMenu: "Menyunu bağla",
      copied: "Kopyalandı",
      copyFailed: "Kopyalama alınmadı",
    }
  : {
      theme: "Colour theme",
      dark: "Dark",
      light: "Light",
      "high-contrast": "High contrast",
      openMenu: "Open menu",
      closeMenu: "Close menu",
      copied: "Copied",
      copyFailed: "Copy failed",
    };

const themeColours: Record<Theme, string> = {
  dark: "#0a0b10",
  light: "#f7f8fb",
  "high-contrast": "#000000",
};

const nextTheme: Record<Theme, Theme> = {
  dark: "light",
  light: "high-contrast",
  "high-contrast": "dark",
};

function isTheme(value: string | undefined): value is Theme {
  return value === "dark" || value === "light" || value === "high-contrast";
}

function currentTheme(): Theme {
  return isTheme(root.dataset.theme) ? root.dataset.theme : "dark";
}

const themeStatus = document.querySelector<HTMLElement>("[data-theme-status]");
const themeMeta = document.querySelector<HTMLMetaElement>('meta[name="theme-color"]');
const themeButtons = document.querySelectorAll<HTMLButtonElement>("[data-theme-toggle]");

function applyTheme(theme: Theme): void {
  root.dataset.theme = theme;
  if (themeMeta) themeMeta.content = themeColours[theme];
  for (const button of themeButtons) {
    const label = `${copy.theme}: ${copy[theme]}`;
    button.setAttribute("aria-label", label);
    button.title = label;
  }
  if (themeStatus) themeStatus.textContent = `${copy.theme}: ${copy[theme]}`;
}

function storeTheme(theme: Theme): void {
  try {
    localStorage.setItem("klyvera-theme", theme);
  } catch {
    // Storage can be unavailable in private or restricted contexts.
  }
}

applyTheme(currentTheme());

for (const button of themeButtons) {
  button.addEventListener("click", () => {
    const theme = nextTheme[currentTheme()];
    applyTheme(theme);
    storeTheme(theme);
  });
}

const header = document.querySelector<HTMLElement>("[data-header]");

if (header) {
  const updateHeader = (): void => {
    header.classList.toggle("is-scrolled", window.scrollY > 6);
  };
  updateHeader();
  window.addEventListener("scroll", updateHeader, { passive: true });
}

const menuButton = document.querySelector<HTMLButtonElement>("[data-menu-toggle]");
const mobileNav = document.querySelector<HTMLElement>("[data-mobile-nav]");
const desktopQuery = window.matchMedia("(min-width: 901px)");

function setMenu(open: boolean, restoreFocus = false): void {
  if (!menuButton || !mobileNav) return;
  menuButton.setAttribute("aria-expanded", String(open));
  menuButton.setAttribute("aria-label", open ? copy.closeMenu : copy.openMenu);
  menuButton.title = open ? copy.closeMenu : copy.openMenu;
  mobileNav.hidden = !open;
  document.body.classList.toggle("nav-open", open);

  if (open) {
    requestAnimationFrame(() => {
      mobileNav.querySelector<HTMLAnchorElement>("a")?.focus();
    });
  } else if (restoreFocus) {
    menuButton.focus();
  }
}

if (menuButton && mobileNav) {
  menuButton.addEventListener("click", () => {
    setMenu(mobileNav.hidden !== false);
  });

  mobileNav.addEventListener("click", (event) => {
    if ((event.target as Element).closest("a")) setMenu(false);
  });

  document.addEventListener("click", (event) => {
    if (mobileNav.hidden) return;
    if (!(event.target as Element).closest(".site-header")) setMenu(false);
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && !mobileNav.hidden) setMenu(false, true);
  });

  desktopQuery.addEventListener("change", (event) => {
    if (event.matches) setMenu(false);
  });
}

const copyStatus = document.createElement("p");
copyStatus.className = "sr-only";
copyStatus.setAttribute("aria-live", "polite");
document.body.append(copyStatus);

async function writeClipboard(text: string): Promise<void> {
  if (navigator.clipboard && window.isSecureContext) {
    await navigator.clipboard.writeText(text);
    return;
  }

  const textarea = document.createElement("textarea");
  textarea.value = text;
  textarea.setAttribute("readonly", "");
  textarea.style.position = "fixed";
  textarea.style.opacity = "0";
  document.body.append(textarea);
  textarea.select();
  const succeeded = document.execCommand("copy");
  textarea.remove();
  if (!succeeded) throw new Error("copy command failed");
}

for (const button of document.querySelectorAll<HTMLButtonElement>("[data-copy-target]")) {
  button.addEventListener("click", async () => {
    const targetId = button.dataset.copyTarget;
    const target = targetId ? document.getElementById(targetId) : null;
    if (!target) return;

    try {
      await writeClipboard(target.textContent?.trim() ?? "");
      copyStatus.textContent = copy.copied;

      const use = button.querySelector("use");
      const previousHref = use?.getAttribute("href");
      if (use) use.setAttribute("href", "#i-check");
      button.classList.add("is-copied");
      button.title = copy.copied;

      window.setTimeout(() => {
        if (use && previousHref) use.setAttribute("href", previousHref);
        button.classList.remove("is-copied");
        button.title = isAzerbaijani ? "Kopyala" : "Copy";
      }, 1800);
    } catch {
      copyStatus.textContent = copy.copyFailed;
    }
  });
}

const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
const revealItems = document.querySelectorAll<HTMLElement>(".reveal");

if (!reducedMotion.matches && "IntersectionObserver" in window && revealItems.length > 0) {
  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        entry.target.classList.add("reveal-is-visible");
        observer.unobserve(entry.target);
      }
    },
    { rootMargin: "0px 0px -8% 0px", threshold: 0.08 },
  );

  for (const item of revealItems) {
    if (item.getBoundingClientRect().top < window.innerHeight * 0.92) continue;
    item.classList.add("reveal-will-change");
    observer.observe(item);
  }
}

const toggle = document.querySelector(".menu-toggle");
const menu = document.getElementById("site-menu");
const backdrop = document.querySelector(".menu-backdrop");

function setMenu(open) {
  menu.classList.toggle("is-open", open);
  menu.setAttribute("aria-hidden", open ? "false" : "true");
  toggle.setAttribute("aria-expanded", open ? "true" : "false");
  backdrop.hidden = !open;
}

toggle.addEventListener("click", () => {
  setMenu(!menu.classList.contains("is-open"));
});

backdrop.addEventListener("click", () => setMenu(false));

menu.querySelectorAll("a").forEach((link) => {
  link.addEventListener("click", () => setMenu(false));
});

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") setMenu(false);
});

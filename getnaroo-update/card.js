// Renders one memory card. Used by the Share preview, the Wall and the approvals page.
(function () {
  const TAGS = { work: "Work", tennis: "Tennis", beer: "Beer", life: "Life" };

  function esc(s) {
    return String(s ?? "").replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  }

  function safeUrl(u) {
    try {
      const url = new URL(u);
      return url.protocol === "https:" || url.protocol === "http:" ? url.href : "";
    } catch { return ""; }
  }

  function linkLabel(u) {
    try {
      const h = new URL(u).hostname.replace(/^www\./, "");
      if (h.includes("youtu")) return "Watch on YouTube";
      if (h.includes("drive.google")) return "Open in Google Drive";
      if (h.includes("photos.google") || h.includes("photos.app.goo.gl")) return "Open in Google Photos";
      if (h.includes("instagram")) return "Open on Instagram";
      return "Open link (" + h + ")";
    } catch { return "Open link"; }
  }

  // media: [{ url, kind: "image"|"video" }]
  function renderCard(m, media) {
    media = media || [];
    const imgs = media.filter(x => x.kind === "image");
    const vids = media.filter(x => x.kind === "video");
    let mediaHtml = "";
    if (vids.length || imgs.length) {
      const items = [
        ...vids.map(v => `<video src="${esc(v.url)}" controls playsinline preload="none"></video>`),
        ...imgs.map(i => `<img src="${esc(i.url)}" alt="Photo shared by ${esc(m.name)}" loading="lazy">`),
      ];
      mediaHtml = `<div class="media${items.length > 1 ? " multi" : ""}">${items.join("")}</div>`;
    }
    const tag = TAGS[m.relation] ? `<span class="pill ${m.relation}">${TAGS[m.relation]}</span>` : "";
    const meta = [m.how_known, m.year_met ? "since " + m.year_met : ""].filter(Boolean).map(esc).join(" · ");
    const section = (title, text) => text ? `<div><h4>${title}</h4><p>${esc(text)}</p></div>` : "";
    const link = safeUrl(m.video_link);
    return `
      <article class="card" data-relation="${esc(m.relation)}">
        ${mediaHtml}
        <div class="body">
          ${m.moment ? `<p class="words">${esc(m.moment)}</p>` : ""}
          ${section("Something he taught me", m.taught)}
          ${section("Wish for v6.0", m.wish)}
          ${link ? `<div class="link"><a href="${esc(link)}" target="_blank" rel="noopener noreferrer">${linkLabel(link)} ↗</a></div>` : ""}
          <div class="who"><span class="name">— ${esc(m.name)}</span>${tag}</div>
          ${meta ? `<div class="meta">${meta}</div>` : ""}
        </div>
      </article>`;
  }

  window.NarooCard = { renderCard, esc, TAGS };
})();

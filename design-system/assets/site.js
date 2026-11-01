/* Meridian design system: data and behaviour. Plain JS, no dependencies.
   Every value below comes from the app's source at the commit shown in the top bar (see design-inventory). */
(function () {
  'use strict';
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
  const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const slug = (s) => String(s).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

  /* ------------------------------------------------------------------ logo */
  let uid = 0;
  const MERIDIANS = [22.28, 28.79, 38.52, 61.48, 71.21, 77.72];
  function logoInner(ink, star, id, faint = 0.32) {
    return `<defs><clipPath id="${id}"><circle cx="50" cy="56" r="30"/></clipPath></defs>` +
      `<g clip-path="url(#${id})" stroke="${ink}" stroke-opacity="${faint}" stroke-width="2.5" stroke-linecap="round" fill="none">` +
      MERIDIANS.map((x) => `<path d="M ${x} 20 V 92"/>`).join('') + `</g>` +
      `<path d="M 50 86 V 20" stroke="${ink}" stroke-width="3.5" stroke-linecap="round" fill="none"/>` +
      `<circle cx="50" cy="12" r="3.5" fill="${star || ink}"/>`;
  }
  function logoSVG({ size = 32, ink = 'currentColor', star = null, label = 'Meridian logo', faint } = {}) {
    const id = 'mlg' + (++uid);
    return `<svg viewBox="0 0 100 100" width="${size}" height="${size}" role="img" aria-label="${esc(label)}">${logoInner(ink, star, id, faint)}</svg>`;
  }
  const ICONS = {
    dark: { bg: ['#1C1C1C', '#0D0D0E'], ink: '#F4EFE4', star: null, label: 'Default (dark)' },
    light: { bg: ['#FFFFFF', '#E6E6EA'], ink: '#1C1C1C', star: null, label: 'Light' },
    mono: { bg: ['#1A1A1A', '#000000'], ink: '#FFFFFF', star: null, label: 'Tinted: mono source' },
    tinted: { bg: ['#1A1A1A', '#000000'], ink: '#A9C1EA', star: null, label: 'Tinted (example tint)' },
    gold: { bg: ['#1C1C1C', '#0D0D0E'], ink: '#F4EFE4', star: '#E9C46A', label: 'Option B' },
    indigo: { bg: ['#1D2547', '#0C0F1D'], ink: '#F4EFE4', star: null, label: 'Option C' },
  };
  function iconSVG(kind) {
    const k = ICONS[kind] || ICONS.dark; const g = 'mig' + (++uid); const c = 'mic' + (++uid);
    return `<svg viewBox="0 0 1024 1024" role="img" aria-label="Meridian app icon, ${esc(k.label)}">` +
      `<defs><radialGradient id="${g}" cx="0.5" cy="0.35" r="0.75"><stop offset="0" stop-color="${k.bg[0]}"/><stop offset="1" stop-color="${k.bg[1]}"/></radialGradient></defs>` +
      `<rect width="1024" height="1024" fill="url(#${g})"/>` +
      `<g transform="translate(202 219) scale(6.2)">${logoInner(k.ink, k.star, c)}</g></svg>`;
  }
  function construction() {
    let s = '<svg viewBox="-14 -4 128 108" role="img" aria-label="Construction of the Longitudes mark on a 100-unit grid">';
    for (let i = 0; i <= 100; i += 5) {
      const major = i % 10 === 0;
      const o = major ? 0.13 : 0.06;
      s += `<path d="M ${i} 0 V 100 M 0 ${i} H 100" stroke="#fff" stroke-opacity="${o}" stroke-width="${major ? 0.25 : 0.15}"/>`;
    }
    s += '<rect x="0" y="0" width="100" height="100" fill="none" stroke="#fff" stroke-opacity=".3" stroke-width=".3"/>';
    s += '<circle cx="50" cy="56" r="30" fill="none" stroke="#E9C46A" stroke-opacity=".55" stroke-width=".35" stroke-dasharray="1.2 1"/>';
    s += '<g font-family="ui-monospace, Menlo, monospace" font-size="2.6" fill="#bbb">';
    // longitude guides
    const ks = [-3, -2, -1, 0, 1, 2, 3];
    ks.forEach((k) => {
      const x = (50 + 30 * Math.sin((k * 22.5 * Math.PI) / 180)).toFixed(2);
      s += `<text x="${x}" y="${k % 2 ? 103 : 106.5}" text-anchor="middle">${x}</text>`;
    });
    s += '<text x="-1.5" y="13" text-anchor="end">12</text><text x="-1.5" y="21" text-anchor="end">20</text><text x="-1.5" y="57" text-anchor="end">56</text><text x="-1.5" y="87" text-anchor="end">86</text>';
    s += '</g>';
    s += '<path d="M 0 12 H 100 M 0 20 H 100 M 0 86 H 100 M 0 56 H 100" stroke="#9fc3ff" stroke-opacity=".28" stroke-width=".25" stroke-dasharray=".8 .8"/>';
    s += `<g color="#F4EFE4">${logoInner('currentColor', null, 'mcs' + (++uid))}</g>`;
    s += '<g font-family="-apple-system, system-ui, sans-serif" font-size="2.9" fill="#F4EFE4">' +
      '<text x="56" y="10">star r 3.5 at (50, 12)</text>' +
      '<text x="81" y="31">globe r 30</text><text x="81" y="34.5">at (50, 56)</text>' +
      '<text x="53" y="94">your meridian: stroke 3.5, 100%</text>' +
      '<text x="2" y="97.5">others: stroke 2.5, 32%, clipped to the globe</text></g>';
    s += '</svg>';
    return s;
  }

  /* --------------------------------------------------------------- colours */
  // [name, value(css), hex label, cssVar, swift, where, file, base (for alpha preview), flags]
  const COLOR_GROUPS = [
    { id: 'night-ink', title: 'NightInk: app text on the night base', file: 'Airstamp/Features/Common/NightStyle.swift', items: [
      ['Primary', '#FFFFFF', '#FFFFFF', '--night-ink-primary', 'NightInk.primary', 'Out line on the hero, Show detail and the show page', 'NightStyle.swift:18', '#1C1C1C'],
      ['Secondary', 'rgba(255,255,255,.75)', '#FFFFFFBF', '--night-ink-secondary', 'NightInk.secondary', 'Row out line, Show detail source sentence, Welcome zone line, "Not now"', 'NightStyle.swift:19', '#1C1C1C'],
      ['Muted', 'rgba(235,235,245,.6)', '#EBEBF599', '--night-ink-muted', 'NightInk.muted (Color.secondary)', 'Meta lines, section headers, labels, search messages', 'NightStyle.swift:20', '#1C1C1C', 'system'],
    ] },
    { id: 'night-bases', title: 'Night bases: computed from each show’s art', file: 'Airstamp/Features/Common/NightStyle.swift:9-13, Shared/Design/ArtworkPalette.swift', items: [
      ['Neutral night', '#1C1C1C', '#1C1C1C', '--night-neutral', 'ArtworkPalette.neutral.night', 'Before art loads or with none; Search and Welcome backgrounds', 'ArtworkPalette.swift:12'],
      ['Warm: red art', '#1C1A1A', '#1C1A1A', '--night-sample-red', 'palette(hue: 0).night', 'Warm hues (<75° or >320°) get brightness 0.11, saturation ≤ 0.08, so never brown', 'NightStyle.swift:10-12'],
      ['Warm: orange art', '#1C1B1A', '#1C1B1A', '--night-sample-orange', 'palette(hue: 30).night', 'Sample value', 'NightStyle.swift:10-12'],
      ['Warm: yellow art', '#1C1C1A', '#1C1C1A', '--night-sample-yellow', 'palette(hue: 60).night', 'Sample value', 'NightStyle.swift:10-12'],
      ['Cool: green art', '#182418', '#182418', '--night-sample-green', 'palette(hue: 120).night', 'Cool hues get brightness 0.14, saturation ≤ 0.32', 'NightStyle.swift:10-12'],
      ['Cool: teal art', '#182420', '#182420', '--night-sample-teal', 'palette(hue: 160).night', 'Sample value', 'NightStyle.swift:10-12'],
      ['Cool: blue art', '#181E24', '#181E24', '--night-sample-blue', 'palette(hue: 210).night', 'Sample value', 'NightStyle.swift:10-12'],
      ['Cool: indigo art', '#181824', '#181824', '--night-sample-indigo', 'palette(hue: 240).night', 'Sample value', 'NightStyle.swift:10-12'],
      ['Cool: purple art', '#201824', '#201824', '--night-sample-purple', 'palette(hue: 280).night', 'Sample value', 'NightStyle.swift:10-12'],
      ['Palette base (neutral)', '#525252', '#525252', '--art-base-neutral', 'ArtworkPalette.neutral.base', 'Row-art placeholder before it loads (ArtworkFill palette: .neutral)', 'ArtworkPalette.swift:18-28'],
      ['Palette accent', '#FFFFFF', '#FFFFFF', '--art-accent', 'ArtworkPalette.accent', 'Computed but read by no view', 'ArtworkPalette.swift:27', null, 'unused'],
    ] },
    { id: 'widget-ink', title: 'WidgetInk: Home Screen widgets', file: 'Shared/Widgets/WidgetInk.swift', items: [
      ['Base', '#1C1C1C', '#1C1C1C', '--widget-base', 'WidgetInk.base', 'WidgetBackdrop base and art fade (literal 0.11 grey)', 'WidgetInk.swift:7'],
      ['Primary', '#FFFFFF', '#FFFFFF', '--widget-primary', 'WidgetInk.primary', 'Titles, countdowns, tags, empty headline', 'WidgetInk.swift:8', '#1C1C1C'],
      ['Secondary', 'rgba(255,255,255,.75)', '#FFFFFFBF', '--widget-secondary', 'WidgetInk.secondary', 'Out lines, empty detail, quiet row name, compact-row countdown', 'WidgetInk.swift:9', '#1C1C1C'],
      ['Muted', 'rgba(255,255,255,.55)', '#FFFFFF8C', '--widget-muted', 'WidgetInk.muted', 'Compact row "when", quiet row reason and "Nothing scheduled"', 'WidgetInk.swift:10', '#1C1C1C'],
      ['Tile', 'rgba(255,255,255,.08)', '#FFFFFF14', '--widget-tile', 'WidgetInk.tile', 'Empty poster thumbnail', 'WidgetInk.swift:12', '#1C1C1C'],
      ['Always-On dim', 'rgba(255,255,255,.525)', '× 0.7', '--widget-always-on-factor', 'WidgetInk.dimmed(_:when:)', 'Always-On multiplies every ink except the countdown by 0.7 (secondary shown)', 'WidgetInk.swift:15-17', '#1C1C1C'],
    ] },
    { id: 'la-ink', title: 'LiveActivityInk: Lock Screen and Dynamic Island', file: 'Shared/LiveActivity/LiveActivityInk.swift', items: [
      ['Base', '#0D0D0E', '#0D0D0E', '--la-base', 'LiveActivityInk.base', 'activityBackgroundTint, LiveActivityArtEdge', 'LiveActivityInk.swift:7'],
      ['Primary', '#FFFFFF', '#FFFFFF', '--la-primary', 'LiveActivityInk.primary', 'Titles, "Out now", countdown, monogram', 'LiveActivityInk.swift:8', '#0D0D0E'],
      ['Secondary', 'rgba(255,255,255,.75)', '#FFFFFFBF', '--la-secondary', 'LiveActivityInk.secondary', 'Label "Expected in", time line, "+ 1 more"', 'LiveActivityInk.swift:9', '#0D0D0E'],
      ['Muted', 'rgba(255,255,255,.55)', '#FFFFFF8C', '--la-muted', 'LiveActivityInk.muted', 'Details "S2E5 · Apple TV", struck-through old time', 'LiveActivityInk.swift:10', '#0D0D0E'],
      ['Fill', '#FFFFFF', '#FFFFFF', '--la-fill', 'LiveActivityInk.fill', 'Ring and bar fill', 'LiveActivityInk.swift:12', '#0D0D0E'],
      ['Track', 'rgba(255,255,255,.18)', '#FFFFFF2E', '--la-track', 'LiveActivityInk.track', 'Ring and bar track', 'LiveActivityInk.swift:13', '#0D0D0E'],
      ['Disc', 'rgba(255,255,255,.16)', '#FFFFFF29', '--la-disc', 'LiveActivityInk.disc', 'Disc behind the monogram', 'LiveActivityInk.swift:15', '#0D0D0E'],
      ['Keyline', 'rgba(255,255,255,.35)', '#FFFFFF59', '--la-keyline', 'LiveActivityInk.keyline', 'Dynamic Island outline', 'LiveActivityInk.swift:17', '#000000'],
      ['Monogram ghost', 'rgba(255,255,255,.07)', '#FFFFFF12', '--la-monogram', 'primary.opacity(0.07)', 'Faint giant initial when there is no art', 'LiveActivityArtEdge.swift:38', '#0D0D0E', 'raw'],
    ] },
    { id: 'control-colours', title: 'Controls and overlays (raw values in views)', file: 'Airstamp/Features/Search, Shared/Widgets, NightStyle.swift', items: [
      ['Control fill', 'rgba(0,0,0,.55)', '#0000008C', '--control-fill', '.black.opacity(0.55)', 'Unpicked filter chip, follow (+) button', 'SearchFilterRow.swift:86; SearchView.swift:237', '#1C1C1C', 'raw'],
      ['Hairline', 'rgba(255,255,255,.35)', '#FFFFFF59', '--control-hairline', '.white.opacity(0.35)', 'Unpicked chip, (+) and "Following" strokes', 'SearchFilterRow.swift:87; SearchView.swift:238; ShowPreviewView.swift:105', '#1C1C1C', 'raw'],
      ['Following fill', 'rgba(255,255,255,.12)', '#FFFFFF1F', '--following-fill', '.white.opacity(0.12)', '"Following" capsule; episode divider', 'ShowPreviewView.swift:104; ShowDetailView.swift:130', '#1C1C1C', 'raw'],
      ['Episode ink', 'rgba(255,255,255,.6)', '#FFFFFF99', '--episode-ink', 'ink.opacity(0.6)', 'Episode label and date; Live Activity toggle tint', 'ShowDetailView.swift:97,122,126', '#1C1C1C', 'raw'],
      ['Tag fill', 'rgba(0,0,0,.45)', '#00000073', '--widget-tag-fill', '.black.opacity(0.45)', 'WidgetTag capsule over art', 'WidgetTag.swift:18', '#8C8C8C', 'raw'],
      ['Art scrim', 'rgba(0,0,0,.4)', '#00000066', '--art-scrim', '.black.opacity(0.4)', 'Top of NightArtHeader, fading to clear at 25%', 'NightStyle.swift:61', '#8C8C8C', 'raw'],
      ['Picked / primary', '#FFFFFF', '#FFFFFF', '--control-picked', '.white', 'Picked chip, Following (+), Follow and Find a show buttons, tab tint (text #000)', 'SearchFilterRow.swift:83-86; RootView.swift:73', null, 'raw'],
    ] },
    { id: 'legacy-status', title: 'Status inks (legacy; superseded by words, D-40)', file: 'Shared/Design/Tokens.swift:26-33', items: [
      ['Exact', '#5BE38A', '#17692A / #5BE38A', '--legacy-exact', 'Tokens.Ink.exact', 'Legacy SourceChip only', 'Tokens.swift:27', null, 'legacy'],
      ['Estimated', '#8AB0FF', '#1F5FCC / #8AB0FF', '--legacy-estimated', 'Tokens.Ink.estimated', 'Legacy SourceChip only', 'Tokens.swift:28', null, 'legacy'],
      ['Adjusted', '#C9A6FF', '#7B3FC4 / #C9A6FF', '--legacy-adjusted', 'Tokens.Ink.adjusted', 'Legacy SourceChip only', 'Tokens.swift:29', null, 'legacy'],
      ['Date only', '#A8A8B0', '#5E5E66 / #A8A8B0', '--legacy-date-only', 'Tokens.Ink.dateOnly', 'Legacy SourceChip only', 'Tokens.swift:30', null, 'legacy'],
      ['Delayed', '#FDBA74', '#96440A / #FDBA74', '--legacy-delayed', 'Tokens.Ink.delayed', 'Legacy DropRow "Delayed"', 'Tokens.swift:31', null, 'legacy'],
      ['No stream', '#FF8A80', '#B01F1F / #FF8A80', '--legacy-no-stream', 'Tokens.Ink.noStream', 'Legacy ProviderLabelView', 'Tokens.swift:32', null, 'legacy'],
    ] },
  ];

  function renderSwatches() {
    const host = $('#swatch-groups'); if (!host) return;
    host.innerHTML = COLOR_GROUPS.map((g) => {
      const items = g.items.map(([name, css, hex, v, swift, where, file, base, flag]) => {
        const id = 'color-' + slug(g.id + '-' + name);
        const alpha = /rgba/.test(css);
        const tags = flag === 'system' ? '<span class="badge system">system</span>' : flag === 'legacy' ? '<span class="badge legacy">legacy</span>' : flag === 'raw' ? '<span class="badge legacy">raw</span>' : flag === 'unused' ? '<span class="badge legacy">unused</span>' : '';
        const chipBg = alpha && base ? `background:${base}` : '';
        return `<div class="swatch" id="${id}" data-search="${esc(name + ' ' + swift + ' ' + hex + ' ' + v + ' ' + g.title + ' colour color')}" data-title="${esc(swift)}" data-kind="Colour" data-sub="${esc(hex)}">
          <div class="chip${alpha && !base ? ' alpha' : ''}" style="${chipBg}"><i style="background:${css}"></i>${alpha && base ? `<span class="on">on ${base}</span>` : ''}</div>
          <div class="body"><div class="name">${esc(name)} ${tags}<button class="anchor-btn" data-link="${id}" aria-label="Copy link to ${esc(name)}">#</button></div>
          <div class="vals"><button class="copy-val" data-copy="${esc(hex)}" title="Copy hex">${esc(hex)}</button><button class="copy-val" data-copy="var(${v})" title="Copy CSS variable">${esc(v)}</button><button class="copy-val" data-copy="${esc(swift)}" title="Copy SwiftUI name">${esc(swift)}</button></div>
          <div class="use">${esc(where)}<br><code>${esc(file)}</code></div></div></div>`;
      }).join('');
      return `<h4 id="${g.id}" style="margin-top:26px" data-search="${esc(g.title)}" data-kind="Colour group">${esc(g.title)} <button class="anchor-btn" data-link="${g.id}" aria-label="Copy link">#</button></h4><p class="small muted" style="margin:4px 0 0">${esc(g.file)}</p><div class="swatches">${items}</div>`;
    }).join('');
  }

  /* -------------------------------------------------------------- contrast */
  function parseColor(c) {
    c = c.trim();
    if (c[0] === '#') {
      const h = c.slice(1);
      const n = (i) => parseInt(h.slice(i, i + 2), 16) / 255;
      return [n(0), n(2), n(4), h.length === 8 ? n(6) : 1];
    }
    const m = c.match(/rgba?\(([^)]+)\)/); const p = m[1].split(',').map((x) => parseFloat(x));
    return [p[0] / 255, p[1] / 255, p[2] / 255, p[3] === undefined ? 1 : p[3]];
  }
  const over = (fg, bg) => [0, 1, 2].map((i) => fg[i] * fg[3] + bg[i] * (1 - fg[3])).concat(1);
  const lin = (c) => (c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4));
  const lum = (c) => 0.2126 * lin(c[0]) + 0.7152 * lin(c[1]) + 0.0722 * lin(c[2]);
  const ratio = (a, b) => { const la = lum(a), lb = lum(b); return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05); };
  function bg(spec) { // spec: list of layers bottom→top
    return spec.reduce((acc, layer) => (acc ? over(parseColor(layer), acc) : parseColor(layer)), null);
  }
  const ROLES = [
    ['Primary', '#FFFFFF', 'NightInk.primary · WidgetInk.primary'],
    ['Secondary', 'rgba(255,255,255,.75)', 'NightInk / WidgetInk / LA .secondary'],
    ['Muted (app)', 'rgba(235,235,245,.6)', 'NightInk.muted = system secondary'],
    ['Muted (widgets, LA)', 'rgba(255,255,255,.55)', 'WidgetInk.muted · LiveActivityInk.muted'],
    ['Episode ink', 'rgba(255,255,255,.6)', 'EpisodeRows label + date'],
    ['Always-On secondary', 'rgba(255,255,255,.525)', 'secondary × 0.7'],
    ['Always-On muted', 'rgba(255,255,255,.385)', 'muted × 0.7'],
  ];
  const BASES = [
    ['Neutral night', ['#1C1C1C']],
    ['Live Activity', ['#0D0D0E']],
    ['Blue night', ['#181E24']],
    ['Green night', ['#182418']],
    ['Purple night', ['#201824']],
    ['Warm night', ['#1C1A1A']],
    ['Settings cell', ['#1C1C1E']],
    ['Chip on night', ['#1C1C1C', 'rgba(0,0,0,.55)']],
    ['Tag over grey art', ['#8C8C8C', 'rgba(0,0,0,.45)']],
    ['Widget fade 50% on light art', ['#CCCCCC', 'rgba(28,28,28,.7)']],
  ];
  // Where each role actually appears (true) — the worst-pair stat uses only real pairs.
  const REAL = {
    'Primary': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 'Secondary': [0, 1, 2, 3, 4, 5, 9], 'Muted (app)': [0, 2, 3, 4, 5, 6],
    'Muted (widgets, LA)': [0, 1, 9], 'Episode ink': [0, 2, 3, 4, 5], 'Always-On secondary': [0, 1], 'Always-On muted': [0, 1],
  };
  function grade(r) { return r >= 7 ? ['aaa', 'AAA'] : r >= 4.5 ? ['aa', 'AA'] : r >= 3 ? ['large', 'AA large'] : ['fail', 'Fail']; }
  let worst = null;
  function renderContrast() {
    const host = $('#contrast-table'); if (!host) return;
    let h = '<table class="contrast"><thead><tr><th>Text role</th>' + BASES.map(([n, l]) => `<th>${esc(n)}<br><span class="muted" style="font-weight:400">${esc(l.join(' + '))}</span></th>`).join('') + '</tr></thead><tbody>';
    ROLES.forEach(([name, css, src]) => {
      h += `<tr><td><b>${esc(name)}</b><br><span class="muted small">${esc(src)}</span><br><code>${esc(css)}</code></td>`;
      BASES.forEach(([bn, layers], bi) => {
        const b = bg(layers); const f = over(parseColor(css), b); const r = ratio(f, b); const [cls, label] = grade(r);
        const real = (REAL[name] || []).includes(bi);
        if (real && (!worst || r < worst.r)) worst = { r, role: name, base: bn };
        const bgCss = `rgb(${b.slice(0, 3).map((x) => Math.round(x * 255)).join(',')})`;
        h += `<td class="cell" style="${real ? '' : 'opacity:.38'}"><span class="sample" style="background:${bgCss};color:${css}">Aa 2:10</span><br><span class="tnum">${r.toFixed(2)}:1</span> <span class="pill ${cls}">${label}</span></td>`;
      });
      h += '</tr>';
    });
    h += '</tbody></table>';
    host.innerHTML = h;
    const pairs = [
      ['Picked chip, Follow, Find a show', '#000000', ['#FFFFFF']],
      ['Logo-tile letter (proposed stand-in)', '#1C1C1C', ['#FFFFFF']],
      ['Option A starlight on night', '#F4EFE4', ['#1C1C1C']],
      ['Option B gold on night', '#E9C46A', ['#1C1C1C']],
      ['Option B gold on Live Activity base', '#E9C46A', ['#0D0D0E']],
      ['Option C starlight on indigo', '#F4EFE4', ['#1D2547']],
      ['Link blue on Settings cell (system)', '#0A84FF', ['#1C1C1E']],
    ];
    $('#contrast-pairs').innerHTML = '<table><thead><tr><th>Pair</th><th>Sample</th><th>Ratio</th><th>Grade</th></tr></thead><tbody>' + pairs.map(([n, fg, layers]) => {
      const b = bg(layers); const r = ratio(parseColor(fg), b); const [cls, label] = grade(r);
      return `<tr><td>${esc(n)}</td><td><span class="sample" style="background:${layers[0]};color:${fg};padding:2px 8px;border-radius:6px">Out now</span></td><td class="num">${r.toFixed(2)}:1</td><td><span class="pill ${cls}">${label}</span></td></tr>`;
    }).join('') + '</tbody></table>';
    const w = $('#worst-contrast');
    if (w && worst) w.innerHTML = `<b>${worst.r.toFixed(2)}:1</b><span>worst real pair: ${esc(worst.role)} on ${esc(worst.base)}</span>`;
    const w2 = $('#worst-contrast-note');
    if (w2 && worst) w2.textContent = `${worst.role} on ${worst.base}: ${worst.r.toFixed(2)}:1.`;
    const w3 = $('#worst-contrast-a11y');
    if (w3 && worst) w3.textContent = `${worst.role} on ${worst.base}, ${worst.r.toFixed(2)}:1`;
  }

  /* ------------------------------------------------------------ typography */
  // [role, surface, family, size, weight, numerals, where, file]
  const TYPE = [
    ['Hero countdown', 'App', 'serif', 88, 300, true, 'Upcoming hero, Show detail, show page', 'UpcomingHero.swift:33'],
    ['Widget large countdown', 'Widget', 'serif', 46, 300, true, 'systemLarge hero', 'LargeWidgetView.swift:81'],
    ['LA countdown (default)', 'Live Activity', 'serif', 44, 300, true, 'LiveActivityCountdown default size', 'LiveActivityCountdown.swift:10'],
    ['Small widget countdown', 'Widget', 'serif', 36, 300, true, 'systemSmall', 'SmallWidgetView.swift:38'],
    ['Lock banner countdown', 'Live Activity', 'serif', 36, 300, true, 'Lock Screen banner', 'LiveActivityLockScreenView.swift:46'],
    ['Welcome headline', 'App', 'serif', 34, 400, false, 'Welcome', 'WelcomeView.swift:17'],
    ['Expanded countdown / Out now', 'Live Activity', 'serif', 34, 300, true, 'Expanded island bottom', 'LiveActivityExpandedView.swift:82,91'],
    ['Hero title', 'App', 'serif', 32, 400, false, 'ReleaseHeadline title, spotlight, show page', 'UpcomingHero.swift:32,40'],
    ['Medium widget countdown', 'Widget', 'serif', 32, 300, true, 'systemMedium hero', 'MediumWidgetView.swift:83'],
    ['Empty headline', 'App', 'serif', 28, 400, false, '"Follow a show…", "Nothing scheduled…"', 'UpcomingView.swift:73,123'],
    ['Rectangular countdown', 'Lock Screen', 'serif', 26, 300, true, 'accessoryRectangular', 'RectangularWidgetView.swift:38'],
    ['Row countdown', 'App', 'serif', 24, 300, true, 'Upcoming row', 'UpcomingView.swift:205'],
    ['Large widget title', 'Widget', 'serif', 24, 400, false, 'systemLarge hero', 'LargeWidgetView.swift:77'],
    ['Small LA countdown', 'Live Activity', 'serif', 24, 300, true, '.small family', 'LiveActivitySmallView.swift:31'],
    ['Grid section header', 'App', 'serif', 22, 400, false, '"Airing in the next few days", "Results"', 'SearchView.swift:183'],
    ['Widget empty headline', 'Widget', 'serif', 22, 300, false, '"Follow a show", "Nothing scheduled"', 'WidgetEmptyState.swift:17'],
    ['Large row countdown', 'Widget', 'serif', 22, 300, true, 'MediumWidgetRow', 'MediumWidgetRow.swift:34'],
    ['Circular date-only day', 'Lock Screen', 'serif', 22, 400, true, 'accessoryCircular', 'CircularWidgetView.swift:85'],
    ['Row title', 'App', 'serif', 20, 400, false, 'Upcoming row', 'UpcomingView.swift:199'],
    ['Medium widget title', 'Widget', 'serif', 19, 400, false, 'systemMedium hero', 'MediumWidgetView.swift:72'],
    ['Lock banner title', 'Live Activity', 'serif', 19, 500, false, 'Lock Screen banner', 'LiveActivityLockScreenView.swift:67'],
    ['Expanded title', 'Live Activity', 'serif', 18, 500, false, 'Expanded leading', 'LiveActivityExpandedView.swift:44'],
    ['Out line (hero)', 'App', 'sans', 17, 500, false, '.body medium: "Expected Wed at 23:00 Lagos time"', 'UpcomingHero.swift:48'],
    ['Follow button', 'App', 'sans', 17, 600, false, '.headline', 'ShowPreviewView.swift:101'],
    ['Episode title', 'App', 'sans', 17, 500, false, '.body medium', 'ShowDetailView.swift:124'],
    ['Small widget title', 'Widget', 'serif', 16, 400, false, 'systemSmall', 'SmallWidgetView.swift:33'],
    ['Out line (row)', 'App', 'sans', 15, 400, false, '.subheadline, secondary', 'UpcomingView.swift:211'],
    ['List section header', 'App', 'sans', 15, 500, false, '.subheadline medium, muted', 'UpcomingView.swift:144'],
    ['Filter chip', 'App', 'sans', 15, 500, false, '.subheadline medium', 'SearchFilterRow.swift:46'],
    ['Rectangular title', 'Lock Screen', 'serif', 15, 600, false, 'accessoryRectangular', 'RectangularWidgetView.swift:32'],
    ['Compact island timer', 'Live Activity', 'serif', 15, 500, true, 'Compact trailing', 'LiveActivityCompactView.swift:44'],
    ['Large / quiet row title', 'Widget', 'serif', 15, 400, false, 'MediumWidgetRow, WidgetQuietRow', 'MediumWidgetRow.swift:24'],
    ['Compact row title', 'Widget', 'serif', 14, 400, false, 'WidgetCompactRow', 'WidgetCompactRow.swift:24'],
    ['Circular value number', 'Lock Screen', 'serif', 14, 400, true, '"2" in "2d"', 'CircularWidgetView.swift:72'],
    ['Expanded label', 'Live Activity', 'sans', 14, 600, false, '"Expected in"', 'LiveActivityExpandedView.swift:87'],
    ['Meta / footnote', 'App', 'sans', 13, 400, false, '.footnote muted: "S4E1 · Apple TV"', 'UpcomingHero.swift:63'],
    ['Grid cell title', 'App', 'sans', 13, 500, false, '.footnote medium', 'SearchView.swift:208'],
    ['Episode label', 'App', 'sans', 13, 600, true, '.footnote monospacedDigit semibold', 'ShowDetailView.swift:121'],
    ['Lock label / details / time', 'Live Activity', 'sans', 13, 600, false, '"Expected in" semibold; details and time medium', 'LiveActivityLockScreenView.swift:34,41,94'],
    ['Large widget out line', 'Widget', 'sans', 13, 500, false, 'systemLarge', 'LargeWidgetView.swift:84'],
    ['Widget out line', 'Widget', 'sans', 12, 500, false, 'Small, medium; empty detail', 'SmallWidgetView.swift:42'],
    ['Grid cell meta', 'App', 'sans', 12, 400, false, '.caption muted', 'SearchView.swift:216'],
    ['Rectangular meta / provider', 'Lock Screen', 'sans', 12, 500, false, '"Expected Wed 23:00"', 'RectangularWidgetView.swift:27,44'],
    ['Widget row "when" / reason', 'Widget', 'sans', 11, 500, false, 'WidgetCompactRow, WidgetQuietRow', 'WidgetCompactRow.swift:29'],
    ['Widget tag', 'Widget', 'sans', 11, 600, false, '"HBO · US", "+3 more this week"', 'WidgetTag.swift:13'],
    ['Small LA label / time', 'Live Activity', 'sans', 11, 600, false, '.small family', 'LiveActivitySmallView.swift:28,34'],
    ['Circular unit', 'Lock Screen', 'serif', 10, 400, true, '"d" in "2d" (secondary)', 'CircularWidgetView.swift:72'],
  ];
  const sampleFor = (row) => {
    const r = row[0];
    if (/countdown|timer|Out now/i.test(r)) return '2:10:07';
    if (/value number|date-only day/.test(r)) return '11';
    if (/unit/.test(r)) return 'd';
    if (/Episode label/.test(r)) return 'S3E10';
    if (/when/.test(r)) return 'Expected Wed 23:00';
    if (/tag/i.test(r)) return 'HBO · US';
    if (/Out line|out line/.test(r)) return 'Expected Wed at 23:00';
    if (/Welcome/.test(r)) return 'How long until your next episode';
    if (/Empty|empty/.test(r)) return 'Follow a show';
    if (/meta|Meta|footnote/.test(r)) return 'S4E1 · Apple TV';
    if (/chip/.test(r)) return 'Exact time';
    if (/label|Label/.test(r)) return 'Expected in';
    if (/Follow/.test(r)) return 'Follow';
    if (/Grid section/.test(r)) return 'Airing in the next few days';
    if (/section header/i.test(r)) return 'Next 24 hours';
    return 'House of the Dragon';
  };
  const W = { 300: 'Light', 400: 'Regular', 500: 'Medium', 600: 'Semibold' };
  function renderType() {
    const host = $('#type-scale'); if (!host) return;
    host.innerHTML = '<table><thead><tr><th>Role</th><th>Surface</th><th>Family</th><th>Size (pt)</th><th>Weight</th><th>Numerals</th><th>Where</th><th>File</th></tr></thead><tbody>' +
      TYPE.map((t) => {
        const id = 'type-' + slug(t[0] + '-' + t[1]);
        return `<tr id="${id}" data-search="${esc(t.join(' ') + ' typography font')}" data-title="${esc(t[0])}" data-kind="Type" data-sub="${esc((t[2] === 'serif' ? 'New York ' : 'SF Pro ') + t[3])}"><td><b>${esc(t[0])}</b></td><td>${esc(t[1])}</td><td>${t[2] === 'serif' ? 'New York' : 'SF Pro'}</td><td class="num">${t[3]}</td><td>${W[t[4]]}</td><td>${t[5] ? 'tabular' : '—'}</td><td>${esc(t[6])}</td><td><code>${esc(t[7])}</code></td></tr>`;
      }).join('') + '</tbody></table>';
    const spec = $('#type-specimens');
    spec.innerHTML = TYPE.filter((t, i, a) => a.findIndex((u) => u[3] === t[3] && u[2] === t[2] && u[4] === t[4]) === i).map((t) =>
      `<div class="type-row"><div class="spec">${t[3]} pt · ${t[2] === 'serif' ? 'New York' : 'SF Pro'} ${W[t[4]]}${t[5] ? ' · tabular' : ''} · ${esc(t[0])}</div>
      <div class="sample${t[2] === 'serif' ? ' serif' : ''}${t[5] ? ' tnum' : ''}" style="font-size:${t[3]}px;font-weight:${t[4]}" data-sample>${esc(sampleFor(t))}</div></div>`).join('');
  }
  function bindCustomType() {
    const input = $('#custom-text'), fam = $('#custom-family');
    if (!input) return;
    const apply = () => {
      $$('#type-specimens [data-sample]').forEach((el) => { if (input.value.trim()) el.textContent = input.value; });
      const out = $('#custom-out');
      const [family, weight] = fam.value.split('|');
      out.style.fontFamily = family === 'serif' ? 'var(--serif)' : 'var(--sans)';
      out.style.fontWeight = weight;
      out.textContent = input.value || 'House of the Dragon';
    };
    input.addEventListener('input', apply); fam.addEventListener('change', apply);
    $('#custom-reset').addEventListener('click', () => { input.value = ''; renderType(); apply(); });
    apply();
  }

  /* -------------------------------------------------------------- countdown */
  const t0 = Date.now();
  function clock(s) {
    s = Math.max(0, Math.ceil(s));
    const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), sec = s % 60;
    const p = (n) => String(n).padStart(2, '0');
    return h > 0 ? `${h}:${p(m)}:${p(sec)}` : `${m}:${p(sec)}`;
  }
  // CountdownFormatter.daySplit: days = max(0, ceil(remaining / 86400) - 1), the timer runs to the next day edge.
  function countdownHTML(remaining) {
    if (remaining <= 0) return null;
    const days = Math.max(0, Math.ceil(remaining / 86400) - 1);
    const edge = remaining - days * 86400;
    return days > 0 ? `${days}<span class="d">d </span>${clock(edge)}` : clock(edge);
  }
  function tick() {
    const now = Date.now();
    $$('[data-cd]').forEach((el) => {
      const target = Number(el.dataset.cdTarget || (el.dataset.cdTarget = t0 + Number(el.dataset.cd) * 1000));
      const rem = (target - now) / 1000;
      const html = countdownHTML(rem);
      if (html === null) {
        // Rule 4: stops at zero and never counts up; the state becomes "Out now".
        if (el.dataset.state !== 'out') { el.dataset.state = 'out'; el.innerHTML = '<span style="font-size:.7em">Out now</span>'; el.setAttribute('aria-label', 'Out now'); }
      } else if (el.innerHTML !== html) { el.innerHTML = html; el.dataset.state = ''; }
    });
  }
  function bindDemo() {
    const el = $('#demo-cd'); if (!el) return;
    const status = $('#demo-status');
    const set = (secs, label) => { el.dataset.cdTarget = String(Date.now() + secs * 1000); el.dataset.state = ''; status.textContent = label; tick(); };
    $$('[data-demo]').forEach((b) => b.addEventListener('click', () => {
      const v = b.dataset.demo;
      if (v === '10') set(10, 'Ten seconds to the drop. Watch it stop at 0:00 and turn into “Out now”.');
      if (v === '3725') set(3725, 'Ticking: under 24 hours, a plain timer.');
      if (v === 'days') set(2 * 86400 + 4 * 3600 + 10 * 60 + 22, 'More than a day: whole days, a dim “d”, then the timer to the next day edge.');
      if (v === 'edge') set(4 * 86400, 'Exactly on a day edge the clock starts at 24:00:00 and ticks, instead of sitting at 0:00.');
    }));
  }

  /* ---------------------------------------------------------------- galleries */
  const WIDGET_FAMILIES = [
    ['inline', 'accessoryInline', 234, 22, 'lock'], ['circular', 'accessoryCircular', 72, 72, 'lock'], ['rectangular', 'accessoryRectangular', 160, 72, 'lock'],
    ['small', 'systemSmall', 158, 158, ''], ['medium', 'systemMedium', 338, 158, ''], ['large', 'systemLarge', 338, 354, ''],
  ];
  const WSTATES = [
    ['countdown', 'Silo in 2 days 4 hours (+2 rows)'], ['ticking', 'House of the Dragon in 3:10:00, no official stream'], ['outNow', 'Out 20 minutes ago'],
    ['dateOnly', 'Wonder Man: date, no time'], ['nothing', 'Nothing followed'], ['returns', 'Nothing scheduled; Silo returns'],
    ['busy', 'Six shows: “+N more this week”'], ['quiet', 'Two scheduled + quiet rows'], ['allQuiet', 'Followed, none scheduled'], ['ticking-always-on', 'Always-On (dimmed)'],
  ];
  const LA_PRES = [
    ['lock', 'Lock Screen banner', 'lock'], ['compact', 'Dynamic Island: compact', 'island'], ['minimal', 'Dynamic Island: minimal', 'island'],
    ['expanded', 'Dynamic Island: expanded', 'island'], ['small', '.small (Watch, Mac, CarPlay)', 'lock'],
  ];
  const LSTATES = [['countingDown', 'Silo, Expected, 2 h'], ['delayed', 'HotD moved +1 h, old time struck'], ['longName', 'Frieren, Airs in Japan'], ['merged', 'Silo + 1 more'], ['outNow', 'Out 10 min ago'], ['stale', 'Content stale at the drop']];
  function shot(src, cap, frame) {
    return `<figure class="shot"><div class="frame ${frame}"><img src="${src}" alt="${esc(cap)}" loading="lazy" decoding="async" data-3x></div><figcaption>${esc(cap)}</figcaption></figure>`;
  }
  function renderWidgets(fam) {
    const f = WIDGET_FAMILIES.find((x) => x[0] === fam);
    let h = `<p class="small muted">${f[1]} · ${f[2]} × ${f[3]} pt (the smallest current iPhone Pro size; images are 3x renders shown at 1x).</p><div class="gallery">`;
    h += WSTATES.map(([s, d]) => shot(`assets/widgets/${fam}-${s}.png`, `${fam}-${s} · ${d}`, f[4])).join('') + '</div>';
    if (['small', 'medium', 'large'].includes(fam)) {
      h += '<h4 style="margin-top:18px">With art (neutral placeholders: square, then 16:9 key art)</h4><div class="gallery">';
      ['countdown', 'ticking', 'busy', 'quiet', 'allQuiet'].forEach((s) => {
        h += shot(`assets/widgets/${fam}-${s}-art.png`, `${fam}-${s}-art`, '') + shot(`assets/widgets/${fam}-${s}-art-wide.png`, `${fam}-${s}-art-wide`, '');
      });
      h += '</div>';
    }
    $('#widget-gallery').innerHTML = h; size3x();
  }
  function renderLA(p) {
    const f = LA_PRES.find((x) => x[0] === p);
    let h = '<div class="gallery">';
    LSTATES.forEach(([s, d]) => { h += shot(`assets/live-activity/${p}-${s}.png`, `${p}-${s} · ${d}`, f[2]) + shot(`assets/live-activity/${p}-${s}-art.png`, `${p}-${s}-art`, f[2]); });
    h += '</div>';
    if (p === 'lock') {
      h += '<h4 style="margin-top:18px">Longest name (“The Lord of the Rings: The Rings of Power, Season Two Finale”, Paramount+ · US) and Always-On</h4><div class="gallery">';
      LSTATES.forEach(([s]) => { h += shot(`assets/live-activity/lock-${s}-longest.png`, `lock-${s}-longest`, 'lock') + shot(`assets/live-activity/lock-${s}-longest-art.png`, `lock-${s}-longest-art`, 'lock'); });
      h += shot('assets/live-activity/lock-delayed-always-on.png', 'lock-delayed-always-on', 'lock') + '</div>';
    }
    if (p === 'minimal') {
      h += '<h4 style="margin-top:18px">Limited width (must fit 28 pt)</h4><div class="gallery">';
      ['countingDown', 'outNow'].forEach((s) => { h += shot(`assets/live-activity/minimal-limited-${s}.png`, `minimal-limited-${s}`, 'island') + shot(`assets/live-activity/minimal-limited-${s}-art.png`, `minimal-limited-${s}-art`, 'island'); });
      h += '</div>';
    }
    $('#la-gallery').innerHTML = h; size3x();
  }
  function size3x() {
    $$('img[data-3x]').forEach((img) => {
      const fit = () => { if (img.naturalWidth) { const w = img.naturalWidth / 3; img.style.width = w + 'px'; const fig = img.closest('.shot'); if (fig) fig.style.width = Math.max(w + 28, 150) + 'px'; } };
      if (img.complete) fit(); else img.addEventListener('load', fit, { once: true });
    });
  }
  function bindTabs(hostSel, render) {
    const host = $(hostSel); if (!host) return;
    host.addEventListener('click', (e) => {
      const b = e.target.closest('button[data-tab]'); if (!b) return;
      $$('button', host).forEach((x) => x.setAttribute('aria-selected', String(x === b)));
      render(b.dataset.tab);
    });
    render(host.querySelector('button[aria-selected=true]').dataset.tab);
  }

  /* ------------------------------------------------------------------ logo slots */
  function renderLogos() {
    $$('[data-logo]').forEach((el) => {
      el.innerHTML = logoSVG({ size: Number(el.dataset.size || 32), ink: el.dataset.ink || 'currentColor', star: el.dataset.star || null, label: el.dataset.label || 'Meridian logo' });
    });
    $$('[data-icon]').forEach((el) => { el.innerHTML = iconSVG(el.dataset.icon); });
    const c = $('#construction'); if (c) c.innerHTML = construction();
  }

  /* --------------------------------------------------------------- copy & toast */
  const toastEl = $('#toast'); let toastTimer;
  function toast(msg) { toastEl.textContent = msg; toastEl.classList.add('show'); clearTimeout(toastTimer); toastTimer = setTimeout(() => toastEl.classList.remove('show'), 1400); }
  async function copy(text, msg = 'Copied') {
    try { await navigator.clipboard.writeText(text); }
    catch (e) {
      const ta = document.createElement('textarea'); ta.value = text; ta.style.position = 'fixed'; ta.style.opacity = '0';
      document.body.appendChild(ta); ta.select(); try { document.execCommand('copy'); } catch (_) { /* ignore */ } ta.remove();
    }
    toast(msg);
  }
  function injectAnchors() {
    $$('h2[id], h3[id], .comp[id] .comp-head h4, .cd-card[id] .label').forEach((h) => {
      const id = h.id || h.closest('[id]').id;
      if (h.querySelector('.anchor-btn')) return;
      const b = document.createElement('button'); b.className = 'anchor-btn'; b.dataset.link = id; b.textContent = '#'; b.setAttribute('aria-label', 'Copy link to this item');
      h.appendChild(b);
    });
    $$('.codebox').forEach((box) => {
      if (box.querySelector('.copy-code')) return;
      const b = document.createElement('button'); b.className = 'copy-code'; b.textContent = 'Copy'; b.setAttribute('aria-label', 'Copy code');
      b.addEventListener('click', () => copy(box.querySelector('code').innerText, 'Code copied'));
      box.appendChild(b);
    });
  }
  document.addEventListener('click', (e) => {
    const c = e.target.closest('[data-copy]'); if (c) { copy(c.dataset.copy, `Copied ${c.dataset.copy.length > 28 ? '' : c.dataset.copy}`.trim()); return; }
    const l = e.target.closest('[data-link]');
    if (l) { const id = l.dataset.link; history.replaceState(null, '', '#' + id); copy(location.href.split('#')[0] + '#' + id, 'Link copied'); }
  });

  /* ------------------------------------------------------------------- rail */
  function buildRail() {
    const ol = $('#rail-list'); const secs = $$('section.sec');
    ol.innerHTML = secs.map((s) => {
      const h2 = $('h2', s); const num = s.dataset.num; const subs = $$('h3[id]', s);
      return `<li><a href="#${s.id}" data-sec="${s.id}"><span class="n">${num}</span><span>${esc(h2.firstChild.textContent.trim())}</span></a>` +
        (subs.length ? `<ul class="sub">${subs.map((h) => `<li><a href="#${h.id}" data-subsec="${h.id}">${esc(h.firstChild.textContent.trim())}</a></li>`).join('')}</ul>` : '') + '</li>';
    }).join('');
    const links = new Map($$('a[data-sec]', ol).map((a) => [a.dataset.sec, a]));
    const subLinks = new Map($$('a[data-subsec]', ol).map((a) => [a.dataset.subsec, a]));
    const io = new IntersectionObserver((entries) => {
      entries.forEach((en) => {
        if (!en.isIntersecting) return;
        const sec = en.target.closest('section.sec');
        links.forEach((a) => a.classList.toggle('active', a.dataset.sec === sec.id));
        if (en.target.tagName === 'H3') subLinks.forEach((a) => a.classList.toggle('active', a.dataset.subsec === en.target.id));
      });
    }, { rootMargin: '-15% 0px -75% 0px' });
    secs.forEach((s) => io.observe(s)); $$('section.sec h3[id]').forEach((h) => io.observe(h));
    const rail = $('#rail'); const mb = $('#menu-btn');
    mb.addEventListener('click', () => { const open = rail.classList.toggle('open'); mb.setAttribute('aria-expanded', String(open)); });
    ol.addEventListener('click', (e) => { if (e.target.closest('a')) { rail.classList.remove('open'); mb.setAttribute('aria-expanded', 'false'); } });
  }

  /* ------------------------------------------------------------------ search */
  let index = [];
  function buildIndex() {
    index = [];
    $$('section.sec').forEach((s) => { const h = $('h2', s); index.push({ id: s.id, title: h.firstChild.textContent.trim(), kind: 'Section', sub: s.dataset.num, text: s.dataset.search || '' }); });
    $$('section.sec h3[id]').forEach((h) => index.push({ id: h.id, title: h.firstChild.textContent.trim(), kind: 'Topic', sub: h.closest('section').querySelector('h2').firstChild.textContent.trim(), text: '' }));
    $$('[data-search][id]').forEach((el) => {
      if (el.tagName === 'SECTION') return;
      index.push({ id: el.id, title: el.dataset.title || (el.querySelector('h4, .name, b') || el).textContent.trim().split('\n')[0], kind: el.dataset.kind || 'Item', sub: el.dataset.sub || '', text: el.dataset.search });
    });
  }
  function score(item, terms) {
    const t = item.title.toLowerCase(), all = (item.title + ' ' + item.text + ' ' + item.sub + ' ' + item.kind).toLowerCase();
    let s = 0;
    for (const q of terms) { if (!all.includes(q)) return -1; s += t.startsWith(q) ? 6 : t.includes(q) ? 3 : 1; }
    if (item.kind === 'Section') s += 1;
    return s;
  }
  function openSearch() {
    const dlg = $('#search'); dlg.classList.add('open'); dlg.setAttribute('aria-hidden', 'false');
    const input = $('#search-input'); input.value = ''; renderResults(''); setTimeout(() => input.focus(), 0);
  }
  function closeSearch() { const dlg = $('#search'); dlg.classList.remove('open'); dlg.setAttribute('aria-hidden', 'true'); $('#search-btn').focus(); }
  let sel = 0, current = [];
  function renderResults(q) {
    const terms = q.toLowerCase().split(/\s+/).filter(Boolean);
    current = terms.length ? index.map((i) => [score(i, terms), i]).filter((x) => x[0] >= 0).sort((a, b) => b[0] - a[0]).slice(0, 40).map((x) => x[1])
      : index.filter((i) => i.kind === 'Section');
    sel = 0;
    const ul = $('#search-results');
    ul.innerHTML = current.length ? current.map((i, n) => `<li role="option" id="sr-${n}" aria-selected="${n === 0}"><a href="#${i.id}" tabindex="-1"><span class="k">${esc(i.kind)}</span><span>${esc(i.title)}</span><span class="s">${esc(i.sub)}</span></a></li>`).join('')
      : `<li class="search-empty">Nothing matches “${esc(q)}”. Try a token (“muted”), a hex (“1C1C1C”), a component (“chip”) or a word (“Expected”).</li>`;
    $('#search-input').setAttribute('aria-activedescendant', current.length ? 'sr-0' : '');
  }
  function go(id) {
    closeSearch(); const el = document.getElementById(id); if (!el) return;
    history.pushState(null, '', '#' + id); el.scrollIntoView({ block: 'start' });
    el.classList.remove('flash'); void el.offsetWidth; el.classList.add('flash');
  }
  function bindSearch() {
    $('#search-btn').addEventListener('click', openSearch);
    $('#search').addEventListener('click', (e) => { if (e.target.id === 'search') closeSearch(); const a = e.target.closest('a'); if (a) { e.preventDefault(); go(a.getAttribute('href').slice(1)); } });
    const input = $('#search-input');
    input.addEventListener('input', () => renderResults(input.value));
    input.addEventListener('keydown', (e) => {
      const lis = $$('#search-results li[role=option]');
      if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
        e.preventDefault(); if (!lis.length) return;
        sel = (sel + (e.key === 'ArrowDown' ? 1 : -1) + lis.length) % lis.length;
        lis.forEach((li, n) => li.setAttribute('aria-selected', String(n === sel)));
        lis[sel].scrollIntoView({ block: 'nearest' }); input.setAttribute('aria-activedescendant', 'sr-' + sel);
      } else if (e.key === 'Enter') { e.preventDefault(); if (current[sel]) go(current[sel].id); }
      else if (e.key === 'Escape') { e.preventDefault(); closeSearch(); }
    });
    document.addEventListener('keydown', (e) => {
      const typing = /INPUT|TEXTAREA|SELECT/.test(document.activeElement.tagName) || document.activeElement.isContentEditable;
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') { e.preventDefault(); $('#search').classList.contains('open') ? closeSearch() : openSearch(); }
      else if (e.key === '/' && !typing) { e.preventDefault(); openSearch(); }
      else if (e.key === 'Escape' && $('#search').classList.contains('open')) closeSearch();
    });
  }

  /* ------------------------------------------------------------- motion demo */
  function bindMotion() {
    const b = $('#motion-play'); if (!b) return;
    b.addEventListener('click', () => {
      const a = $('#motion-art'); a.classList.remove('in'); void a.offsetWidth;
      requestAnimationFrame(() => a.classList.add('in'));
    });
  }

  /* --------------------------------------------------------------- checklist */
  function bindChecklist() {
    const KEY = 'meridian-ds-rename';
    let saved = {};
    try { saved = JSON.parse(localStorage.getItem(KEY) || '{}') || {}; } catch (e) { saved = {}; }
    $$('#rename-list input[type=checkbox]').forEach((cb) => {
      cb.checked = !!saved[cb.id];
      cb.addEventListener('change', () => { saved[cb.id] = cb.checked; try { localStorage.setItem(KEY, JSON.stringify(saved)); } catch (e) { /* private mode */ } });
    });
  }

  /* -------------------------------------------------------------------- stats */
  function stats() {
    const set = (id, n) => { const el = document.getElementById(id); if (el) el.textContent = n; };
    set('stat-tokens', $$('.swatch').length + TYPE.length + $$('[data-token]').length);
    set('stat-components', $$('.comp').length);
    set('stat-states', $$('.comp .state').length + $$('.cd-card').length + 90 + 77);
    set('stat-symbols', $$('.symbol:not(#sym-legacy)').length);
  }

  /* --------------------------------------------------------------------- init */
  document.addEventListener('DOMContentLoaded', () => {
    renderLogos(); renderSwatches(); renderContrast(); renderType(); bindCustomType();
    bindTabs('#widget-tabs', renderWidgets); bindTabs('#la-tabs', renderLA);
    injectAnchors(); buildRail(); buildIndex(); bindSearch(); bindDemo(); bindMotion(); bindChecklist(); stats();
    tick(); setInterval(tick, 250);
    if (location.hash) { const el = document.getElementById(location.hash.slice(1)); if (el) setTimeout(() => el.scrollIntoView({ block: 'start' }), 60); }
  });
})();

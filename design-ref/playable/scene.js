// 角落垂钓 — canvas scene renderer (520×400 art space, 1:1 with Godot main.gd)
window.Scene = (function () {
  const ART = { w: 520, h: 400 };
  let canvas, ctx, dpr = 1;
  let A = {};                 // loaded images
  let spot = "river_bend";
  let bite = [300, 322];
  let state = "wait";        // wait | bite | reel
  let t = 0;                 // global time (s)
  let dip = 0;               // 0 idle .. 1 fully dipped
  let ripples = [];          // {x,y,r,max,a}
  let flyers = [];           // catch sprites in flight {img,x,y,vx,vy,t,life,scale,tier,onland}
  let splashFlash = 0;
  let last = performance.now();

  // fisher composite (flipped to face left toward the water)
  const FISHER = { dx: 332, dy: 214, w: 188, h: 188, scale: 1 };
  const ROD_TIP = { x: 380, y: 236 };   // approx rod tip after horizontal flip

  function img(name) { return A[name]; }

  function init(c, assets) {
    canvas = c; A = assets;
    ctx = canvas.getContext("2d");
    resize();
    window.addEventListener("resize", resize);
    last = performance.now();
    setInterval(step, 1000 / 30);
  }
  function resize() {
    dpr = Math.min(2, window.devicePixelRatio || 1);
    const rect = canvas.getBoundingClientRect();
    canvas.width = Math.round(rect.width * dpr);
    canvas.height = Math.round(rect.height * dpr);
  }
  function setSpot(id, biteXY) { spot = id; if (biteXY) bite = biteXY; ripples = []; }
  function setState(s) {
    state = s;
    if (s === "bite") {
      addRipple(bite[0], bite[1], 26);
      setTimeout(() => addRipple(bite[0], bite[1], 34), 140);
    }
  }
  function addRipple(x, y, max) { ripples.push({ x, y, r: 6, max, a: 0.55 }); }
  function splash() { splashFlash = 1; addRipple(bite[0], bite[1], 30); }

  // launch a caught fish from the bobber toward the basket (bottom-right)
  function playCatch(c, onArrive) {
    splash();
    const start = { x: bite[0], y: bite[1] };
    const target = { x: 452, y: 372 };
    const f = {
      img: img(c.art), x: start.x, y: start.y, t: 0, life: 0.85,
      sx: start.x, sy: start.y, tx: target.x, ty: target.y,
      tier: c.tier, varc: c.varColor, onArrive
    };
    flyers.push(f);
  }

  function step() {
    const now = performance.now();
    const dt = Math.min(0.06, (now - last) / 1000); last = now; t += dt;
    // ease dip toward target
    const target = state === "bite" ? 1 : 0;
    dip += (target - dip) * Math.min(1, dt * (state === "bite" ? 10 : 6));
    // ripples
    for (const r of ripples) { r.r += dt * 42; r.a -= dt * 0.5; }
    ripples = ripples.filter(r => r.a > 0.02 && r.r < r.max);
    if (splashFlash > 0) splashFlash = Math.max(0, splashFlash - dt * 2.2);
    // flyers
    for (const f of flyers) {
      f.t += dt;
      const p = Math.min(1, f.t / f.life);
      const e = 1 - Math.pow(1 - p, 2);
      f.x = f.sx + (f.tx - f.sx) * e;
      const arc = Math.sin(p * Math.PI) * 70;     // arc upward
      f.y = f.sy + (f.ty - f.sy) * e - arc;
      if (p >= 1 && !f._done) { f._done = true; if (f.onArrive) f.onArrive(); }
    }
    flyers = flyers.filter(f => f.t < f.life + 0.05);
    render();
  }

  function render() {
    if (!ctx) return;
    const W = canvas.width, H = canvas.height;
    ctx.clearRect(0, 0, W, H);
    ctx.save();
    // map art space to canvas (contain)
    const sx = W / ART.w, sy = H / ART.h, s = Math.min(sx, sy);
    ctx.translate((W - ART.w * s) / 2, (H - ART.h * s) / 2);
    ctx.scale(s, s);

    // background scene
    const bg = img(spot);
    if (bg) ctx.drawImage(bg, 0, 0, ART.w, ART.h);

    // animated water shimmer
    const wh = img("water_highlight_overlay");
    if (wh) {
      ctx.save();
      ctx.globalAlpha = 0.28 + 0.12 * Math.sin(t * 1.3);
      const drift = Math.sin(t * 0.6) * 8;
      ctx.drawImage(wh, bite[0] - 130 + drift, bite[1] - 30, 260, 110);
      ctx.restore();
    }

    // ripples
    ctx.save();
    ctx.lineWidth = 1.4;
    for (const r of ripples) {
      ctx.strokeStyle = `rgba(231,228,220,${r.a})`;
      ctx.beginPath();
      ctx.ellipse(r.x, r.y, r.r, r.r * 0.42, 0, 0, Math.PI * 2);
      ctx.stroke();
    }
    ctx.restore();

    // fishing line + bobber
    const bob = bobberPos();
    ctx.save();
    ctx.strokeStyle = "rgba(40,44,46,0.5)";
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(ROD_TIP.x, ROD_TIP.y);
    ctx.lineTo(bob.x, bob.y - 8);
    ctx.stroke();
    ctx.restore();

    const bobImg = state === "bite" ? img("bobber_bite") : img("bobber_idle");
    if (bobImg) {
      const bs = state === "bite" ? 34 : 30;
      ctx.drawImage(bobImg, bob.x - bs / 2, bob.y - bs + 6, bs, bs);
    }

    // fisher (flipped horizontally to face the water)
    const pose = state === "reel" ? (img("fisher_pull_02") || img("fisher_idle"))
      : (dip > 0.5 ? (img("fisher_pull_01") || img("fisher_idle")) : img("fisher_idle"));
    if (pose) {
      ctx.save();
      ctx.translate(FISHER.dx + FISHER.w, FISHER.dy);
      ctx.scale(-1, 1);
      const breathe = Math.sin(t * 1.6) * 1.2;
      ctx.drawImage(pose, 0, breathe, FISHER.w, FISHER.h);
      ctx.restore();
    }

    // flyers (caught fish arcing to basket)
    for (const f of flyers) {
      if (!f.img) continue;
      const fade = f.t > f.life * 0.8 ? Math.max(0, 1 - (f.t - f.life * 0.8) / (f.life * 0.2)) : 1;
      const sc = 0.5 + 0.18 * Math.sin(Math.min(1, f.t / f.life) * Math.PI);
      const fw = 64 * sc, fh = 64 * sc;
      ctx.save();
      ctx.globalAlpha = fade;
      if (f.tier >= 4) {
        ctx.shadowColor = f.varc && f.varc !== "#ffffff" ? f.varc : "#FFD659";
        ctx.shadowBlur = 16;
      }
      ctx.drawImage(f.img, f.x - fw / 2, f.y - fh / 2, fw, fh);
      ctx.restore();
    }

    ctx.restore();
  }

  function bobberPos() {
    const bobAmt = state === "bite" ? 6 + dip * 10 : 3;
    const y = bite[1] + Math.sin(t * 2.1) * (state === "bite" ? 1.2 : 2.6) + dip * 10;
    const x = bite[0] + Math.sin(t * 0.9) * 1.5;
    return { x, y };
  }

  return { init, setSpot, setState, playCatch, splash, addRipple, ART };
})();

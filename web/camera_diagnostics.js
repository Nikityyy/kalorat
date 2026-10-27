// Measurements for diagnosing camera layout problems on devices where they
// cannot be reproduced. Shown by long-pressing the logo on the camera screen.
window.kaloratCameraDiagnostics = function () {
  const r1 = (n) => (typeof n === 'number' ? Math.round(n * 10) / 10 : n);
  const rect = (el) => {
    const b = el.getBoundingClientRect();
    return `${r1(b.left)},${r1(b.top)} ${r1(b.width)}x${r1(b.height)}`;
  };
  const lines = [];
  const vv = window.visualViewport;
  lines.push(
    `window ${innerWidth}x${innerHeight} dpr ${devicePixelRatio}` +
      ` screen ${screen.width}x${screen.height}` +
      (vv ? ` visual ${r1(vv.width)}x${r1(vv.height)} scale ${r1(vv.scale)}` : '') +
      ` orient ${(screen.orientation && screen.orientation.type) || '-'}` +
      ` standalone ${matchMedia('(display-mode: standalone)').matches || navigator.standalone === true}`
  );
  for (const sel of ['flutter-view', 'flt-glass-pane']) {
    const el = document.querySelector(sel);
    if (el) lines.push(`${sel} ${rect(el)}`);
  }
  lines.push(`canvas preview ${window.kaloratCameraCanvasEnabled ? kaloratCameraCanvasEnabled() : 'n/a'}`);
  const videos = [...document.querySelectorAll('video')];
  lines.push(`videos ${videos.length}`);
  videos.forEach((v, i) => {
    const cs = getComputedStyle(v);
    const track = v.srcObject && v.srcObject.getVideoTracks && v.srcObject.getVideoTracks()[0];
    const st = track ? track.getSettings() : {};
    lines.push(
      `video${i} natural ${v.videoWidth}x${v.videoHeight} client ${v.clientWidth}x${v.clientHeight}` +
        ` rect ${rect(v)} fit ${cs.objectFit} paused ${v.paused} ready ${v.readyState}`
    );
    lines.push(
      `  track ${st.width}x${st.height} fps ${st.frameRate} facing ${st.facingMode}` +
        ` state ${track ? track.readyState : '-'} transform ${cs.transform}`
    );
    if (track) {
      let caps = {};
      try {
        caps = track.getCapabilities ? track.getCapabilities() : {};
      } catch (_) {}
      const supported = navigator.mediaDevices.getSupportedConstraints
        ? navigator.mediaDevices.getSupportedConstraints().torch
        : undefined;
      lines.push(
        `  torch supported ${supported} capability ${JSON.stringify(caps.torch)}` +
          ` on ${st.torch} label ${track.label}`
      );
    }
    let el = v.parentElement;
    for (let depth = 0; el && el !== document.body && depth < 8; depth++, el = el.parentElement) {
      const c = getComputedStyle(el);
      const bits = [
        el.tagName.toLowerCase(),
        `rect ${rect(el)}`,
        `client ${el.clientWidth}x${el.clientHeight}`,
        c.transform !== 'none' ? `transform ${c.transform}` : '',
        c.clipPath !== 'none' ? `clip ${c.clipPath}` : '',
        c.overflow !== 'visible' ? `overflow ${c.overflow}` : '',
        c.zoom && c.zoom !== '1' ? `zoom ${c.zoom}` : '',
      ].filter(Boolean);
      lines.push('  < ' + bits.join(' | '));
    }
  });
  return lines.join('\n');
};

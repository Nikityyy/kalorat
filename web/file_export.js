// Hands a text file to the user. On phones the share sheet is the dependable
// way ("Save to Files", AirDrop, Mail); a plain download link is unreliable in
// iOS Safari and in installed web apps. Resolves with:
//   'shared'      the share sheet took the file
//   'cancelled'   the user dismissed the share sheet
//   'downloaded'  fell back to a normal browser download
(function () {
  'use strict';

  function download(blob, fileName) {
    var url = URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = url;
    a.download = fileName;
    a.style.display = 'none';
    document.body.appendChild(a);
    a.click();
    // Safari starts the download after the click returns; revoking right away
    // can cancel it.
    setTimeout(function () {
      a.remove();
      URL.revokeObjectURL(url);
    }, 60000);
  }

  window.kaloratSaveFile = async function (content, fileName, mime) {
    var nav = window.navigator;
    if (nav.share && nav.canShare) {
      // iOS only shares some file types; fall back to plain text if needed.
      var types = [mime, 'text/plain'];
      for (var i = 0; i < types.length; i++) {
        var file = new File([content], fileName, { type: types[i] });
        if (!nav.canShare({ files: [file] })) continue;
        try {
          await nav.share({ files: [file], title: fileName });
          return 'shared';
        } catch (e) {
          if (e && e.name === 'AbortError') return 'cancelled';
          break; // e.g. the tap's permission expired; use a download instead
        }
      }
    }
    download(new Blob([content], { type: mime }), fileName);
    return 'downloaded';
  };
})();

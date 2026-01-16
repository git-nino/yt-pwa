const bar = document.getElementById("bar");
const log = document.getElementById("log");
const fileInfo = document.getElementById("fileInfo");
const fileNameDisp = document.getElementById("fileName");
const filePathDisp = document.getElementById("filePath");
let es = null;

function start(mode) {
  const url = document.getElementById("url").value.trim();
  const quality = document.getElementById("quality").value;

  if (!url) return alert("Paste a URL");

  log.textContent = "Starting...";
  bar.value = 0;
  fileInfo.hidden = true;

  if (es) es.close();

  es = new EventSource(`/download/${mode}?url=${encodeURIComponent(url)}&quality=${encodeURIComponent(quality)}`);

  es.onmessage = e => {
    if (e.data === "__DONE__") {
      bar.value = 100;
      fileInfo.hidden = false;
      es.close();
      return;
    }

    const line = e.data;
    log.textContent += line + "\n";
    log.scrollTop = log.scrollHeight;

    // Try to catch the filename from the log
    if (line.includes("[download] Destination:") || line.includes("[ExtractAudio] Destination:")) {
        const parts = line.split("/");
        const name = parts[parts.length - 1];
        fileNameDisp.textContent = name;
        filePathDisp.textContent = `Téléchargements/${mode}/`;
    }

    const m = line.match(/(\d{1,3}\.\d)%/);
    if (m) bar.value = parseFloat(m[1]);
  };
}

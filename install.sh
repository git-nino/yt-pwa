#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "🚀 Installing YT-PWA on Termux..."

### VARIABLES
APP_NAME="app1"
REPO_URL="https://github.com/git-nino/yt-pwa.git"
APP_BASE="$HOME/app_volumes"
APP_DIR="$APP_BASE/$APP_NAME"
VENV_DIR="$APP_DIR/venv"
PYTHON="$VENV_DIR/bin/python"
BIN_DIR="$PREFIX/bin"
SERVICE_DIR="$PREFIX/var/service/$APP_NAME"

### 1️⃣ Verify Termux environment
if [[ -z "${PREFIX:-}" || ! -d "$PREFIX" ]]; then
  echo "❌ This installer must be run inside Termux"
  exit 1
fi

### 2️⃣ Storage permission (non-fatal)
echo "📂 Setting up storage access..."
termux-setup-storage >/dev/null 2>&1 || true

### 3️⃣ Update system
echo "🔄 Updating packages..."
pkg update -y && pkg upgrade -y

### 4️⃣ Install required packages
echo "📦 Installing dependencies..."
pkg install -y \
  python \
  git \
  yt-dlp \
  ffmpeg \
  runit

### 5️⃣ Clone or update app
echo "📥 Deploying application..."
mkdir -p "$APP_BASE"

if [[ -d "$APP_DIR/.git" ]]; then
  cd "$APP_DIR"
  git pull --rebase
else
  git clone "$REPO_URL" "$APP_DIR"
fi

### 6️⃣ Create venv (only if missing)
if [[ ! -d "$VENV_DIR" ]]; then
  echo "🐍 Creating Python virtual environment..."
  python -m venv "$VENV_DIR"
fi

### 7️⃣ Install Python dependencies
echo "📦 Installing Python dependencies..."
"$PYTHON" -m pip install --upgrade pip setuptools wheel

if [[ -f "$APP_DIR/requirements.txt" ]]; then
  "$PYTHON" -m pip install -r "$APP_DIR/requirements.txt"
else
  "$PYTHON" -m pip install flask
fi

### 8️⃣ Verify tools
echo "🔍 Verifying installation..."
"$PYTHON" - <<'EOF'
import flask
print("Flask OK:", flask.__version__)
EOF

yt-dlp --version >/dev/null
ffmpeg -version >/dev/null

### 9️⃣ Install mp3 helper
echo "🎵 Installing mp3 helper..."
cat > "$BIN_DIR/mp3" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -e
DEST="$HOME/storage/downloads/mp3"
mkdir -p "$DEST"
QUALITY="${2:-0}"
yt-dlp -x --audio-format mp3 \
  --audio-quality "$QUALITY" \
  --restrict-filenames \
  -o "$DEST/%(title).100s.%(ext)s" "$1"
EOF
chmod +x "$BIN_DIR/mp3"

### 🔟 Install mp4 helper
echo "🎬 Installing mp4 helper..."
cat > "$BIN_DIR/mp4" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -e
DEST="$HOME/storage/downloads/mp4"
mkdir -p "$DEST"
QUALITY="${2:-best}"
yt-dlp -f "$QUALITY" \
  --restrict-filenames \
  -o "$DEST/%(title).100s.%(ext)s" "$1"
EOF
chmod +x "$BIN_DIR/mp4"

### 1️⃣1️⃣ Create runit service (DO NOT start yet)
if command -v sv >/dev/null 2>&1; then
  echo "⚙️ Creating runit service..."

  mkdir -p "$SERVICE_DIR"

  cat > "$SERVICE_DIR/run" <<EOF
#!/data/data/com.termux/files/usr/bin/sh
cd "$APP_DIR"
exec "$PYTHON" app.py
EOF

  chmod +x "$SERVICE_DIR/run"

  echo "ℹ️ Service '$APP_NAME' created successfully"
else
  echo "⚠️ runit not available, skipping service setup"
fi

### ✅ Done
echo ""
echo "✅ Installation completed successfully!"
echo ""
echo "⚠️ IMPORTANT:"
echo "You MUST restart Termux before using 'sv' commands."
echo ""
echo "📌 After restarting Termux, run:"
echo "   sv up $APP_NAME"
echo ""
echo "🌐 Manual start (no service):"
echo "   cd $APP_DIR && $PYTHON app.py"
echo ""
echo "📥 Download helpers:"
echo "   mp3 <url> [quality]"
echo "   mp4 <url> [format]"

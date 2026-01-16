#!/data/data/com.termux/files/usr/bin/bash
set -e
set -o pipefail

echo "🚀 Installing YT-PWA on Termux..."

### VARIABLES
APP_NAME="app1"
REPO_URL="https://github.com/git-nino/yt-pwa.git"
APP_DIR="$HOME/app_volumes/$APP_NAME"
SERVICE_DIR="$PREFIX/var/service/$APP_NAME"
BIN_DIR="$PREFIX/bin"
VENV_DIR="$APP_DIR/venv"
PYTHON_VENV="$VENV_DIR/bin/python"

### 1️⃣ Check Termux
if [ -z "$PREFIX" ]; then
  echo "❌ This installer must be run inside Termux"
  exit 1
fi

### 2️⃣ Storage access
echo "📂 Ensuring storage access..."
termux-setup-storage || true

### 3️⃣ Update system
echo "🔄 Updating packages..."
pkg update -y
pkg upgrade -y

### 4️⃣ Install dependencies
echo "📦 Installing dependencies..."
pkg install -y python git ffmpeg yt-dlp runit

### 5️⃣ Clone or update repo
echo "📥 Deploying application..."
mkdir -p "$HOME/app_volumes"

if [ -d "$APP_DIR/.git" ]; then
  cd "$APP_DIR"
  git pull
else
  git clone "$REPO_URL" "$APP_DIR"
fi

### 6️⃣ Create Python virtual environment (clean)
echo "🐍 Creating Python virtual environment..."
rm -rf "$VENV_DIR"
python -m venv "$VENV_DIR"

### 7️⃣ Install Flask inside venv (STRICT)
echo "📦 Installing Flask..."
"$PYTHON_VENV" -m pip install --upgrade pip setuptools wheel
"$PYTHON_VENV" -m pip install flask

### 8️⃣ Verify Flask install
echo "🔍 Verifying Flask installation..."
"$PYTHON_VENV" - <<'EOF'
import flask
print("Flask version:", flask.__version__)
EOF

### 9️⃣ mp3 helper
echo "🎵 Installing mp3 helper..."
cat > "$BIN_DIR/mp3" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
DEST="$HOME/storage/downloads/mp3"
mkdir -p "$DEST"
QUALITY="${2:-0}"
yt-dlp -x --audio-format mp3 \
  --audio-quality "$QUALITY" \
  --restrict-filenames \
  -o "$DEST/%(title).100s.%(ext)s" "$1"
EOF
chmod +x "$BIN_DIR/mp3"

### 🔟 mp4 helper
echo "🎬 Installing mp4 helper..."
cat > "$BIN_DIR/mp4" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
DEST="$HOME/storage/downloads/mp4"
mkdir -p "$DEST"
QUALITY="${2:-best}"
yt-dlp -f "$QUALITY" \
  --restrict-filenames \
  -o "$DEST/%(title).100s.%(ext)s" "$1"
EOF
chmod +x "$BIN_DIR/mp4"

### 1️⃣1️⃣ Create runit service (NO source)
echo "⚙️ Creating runit service..."
mkdir -p "$SERVICE_DIR"

cat > "$SERVICE_DIR/run" <<EOF
#!/data/data/com.termux/files/usr/bin/sh
cd $APP_DIR
exec $PYTHON_VENV app.py
EOF

chmod +x "$SERVICE_DIR/run"

### 1️⃣2️⃣ Enable & start service
echo "▶️ Starting service..."
sv-enable "$APP_NAME" || true
sv restart "$APP_NAME" || sv up "$APP_NAME"

### ✅ Done
echo ""
echo "✅ Installation successful!"
echo "🌐 App running (check app.py port)"
echo "📍 Service path: $SERVICE_DIR"
echo ""
echo "Service commands:"
echo "  sv status $APP_NAME"
echo "  sv restart $APP_NAME"
echo "  sv down $APP_NAME"

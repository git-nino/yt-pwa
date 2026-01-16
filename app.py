import os
import subprocess
import shutil
from flask import Flask, render_template, request, Response, redirect

app = Flask(__name__)

@app.route("/")
def root():
    # Redirect to the PWA entry point 
    return redirect("/app1/")

@app.route("/app1/")
def index():
    # Renders the updated professional index.html 
    return render_template("index.html")

@app.route("/download/<mode>")
def download(mode):
    url = request.args.get("url")
    quality = request.args.get("quality")

    if not url or mode not in ("mp3", "mp4"):
        return "Invalid request", 400

    # Check if the termux helper scripts exist in path
    if not shutil.which(mode):
        return f"Error: Command '{mode}' not found", 500

    def generate():
        # stdbuf -oL ensures unbuffered output for the UI log 
        cmd = ["stdbuf", "-oL", mode, url]
        if quality:
            cmd.append(quality)

        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )

        for line in process.stdout:
            yield f"data:{line.rstrip()}\n\n"

        process.wait()
        yield "data:__DONE__\n\n"

    return Response(generate(), mimetype="text/event-stream")

if __name__ == "__main__":
    # Standard configuration for local Termux hosting
    app.run(host="0.0.0.0", port=8001, threaded=True)

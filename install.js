var binaryName = "giavascript";
var shortcutName = "gs";
var buildOutput = "bin/" + binaryName;
var installDir = process.env.INSTALL_DIR || "/usr/local/bin";
var targetPath = installDir + "/" + binaryName;
var shortcutPath = installDir + "/" + shortcutName;

function run(command, args) {
  var result = process.run(command, args);
  if (result.stdout) console.log(result.stdout);
  if (result.stderr) console.error(result.stderr);
  return result.status;
}

if (run("mkdir", ["-p", "bin"]) != 0) process.exit(1);

console.log("Building " + binaryName + " with Crystal release optimizations...");
if (run("crystal", ["build", "src/giavascript_cli.cr", "--release", "--no-debug", "-o", buildOutput]) != 0) {
  console.error("Error: build failed.");
  process.exit(1);
}

var installStatus = run("mkdir", ["-p", installDir]);
if (installStatus == 0) installStatus = run("install", ["-m", "755", buildOutput, targetPath]);
if (installStatus == 0) installStatus = run("ln", ["-sf", targetPath, shortcutPath]);

if (installStatus != 0) {
  console.log("Could not install to " + installDir + ". Trying with sudo...");
  if (run("sudo", ["mkdir", "-p", installDir]) != 0 ||
      run("sudo", ["install", "-m", "755", buildOutput, targetPath]) != 0 ||
      run("sudo", ["ln", "-sf", targetPath, shortcutPath]) != 0) {
    console.error("Error: installation failed.");
    process.exit(1);
  }
}

console.log("Installed to " + targetPath);
console.log("Shortcut: " + shortcutName + " -> " + binaryName);

if (!(process.env.PATH || "").split(":").includes(installDir)) {
  console.warn("Warning: '" + installDir + "' is not currently in your PATH.");
  console.warn("Add this to your shell config:");
  console.warn("  export PATH=\"" + installDir + ":$PATH\"");
}

console.log("Done. Run:");
console.log("  " + shortcutName);
console.log("  " + shortcutName + " path/to/file.js");
process.exit(0);

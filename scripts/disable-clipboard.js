const fs = require("fs");

const path = "node_modules/@mariozechner/clipboard/index.js";

if (fs.existsSync(path)) {
  fs.writeFileSync(path, "module.exports = { writeSync(){}, readSync(){ return '' } }");
  console.log("Clipboard module patched");
}

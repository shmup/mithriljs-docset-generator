#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

if [[ ! -d "build" ]]; then
	mkdir build
fi

pushd build

# dependencies
if ! [ "$(command -v npm)" ]; then
	echo "gonna need npm/node" && exit 0
fi

if ! [ "$(command -v sqlite3)" ]; then
	echo "gonna need sqlite3" && exit 0
fi

if [[ ! -d "mithril.js" ]]; then
	git clone https://github.com/lhorie/mithril.js.git
fi

curl -ORs http://mithril.js.org/style.css

mkdir -p Mithril.docset/Contents/Resources/Documents/
cp ../package.json .
npm install

# markdown
rm -f Mithril.docset/Contents/Resources/Documents/*

read -r -d '' js <<EOS || true
'use strict';
const marked = require('marked');
const fs = require('fs');
const path = require('path');

let css = fs.readFileSync("style.css").toString("utf8");

// pasted in from highlight.js bundle download, googlecode style
css += "\n/*  Google Code style (c) Aahan Krish <geekpanth3r@gmail.com>  */  .hljs {   display: block;   overflow-x: auto;   padding: 0.5em;   background: white;   color: black; }  .hljs-comment, .hljs-quote {   color: #800; }  .hljs-keyword, .hljs-selector-tag, .hljs-section, .hljs-title, .hljs-name {   color: #008; }  .hljs-variable, .hljs-template-variable {   color: #660; }  .hljs-string, .hljs-selector-attr, .hljs-selector-pseudo, .hljs-regexp {   color: #080; }  .hljs-literal, .hljs-symbol, .hljs-bullet, .hljs-meta, .hljs-number, .hljs-link {   color: #066; }  .hljs-title, .hljs-doctag, .hljs-type, .hljs-attr, .hljs-built_in, .hljs-builtin-name, .hljs-params {   color: #606; }  .hljs-attribute, .hljs-subst {   color: #000; }  .hljs-formula {   background-color: #eee;   font-style: italic; }  .hljs-selector-id, .hljs-selector-class {   color: #9B703F }  .hljs-addition {   background-color: #baeeba; }  .hljs-deletion {   background-color: #ffc8bd; }  .hljs-doctag, .hljs-strong {   font-weight: bold; }  .hljs-emphasis {   font-style: italic; }\n";

// some style override hacks to fix zeal misbehaving with the downloaded mithril
// stylesheet. this may not play nice with Dash or if the mithril style gets
// updated.
css += "\n" +
   "html { font-size: 1.2em; font-family: Helvetica, Arial, Sans-Serif; }\n" + 
   ".content { padding: 15px; }\n";

let outPath = __dirname + "/Mithril.docset/Contents/Resources/Documents/";
let tplUpper = "<!doctype html>\n<html>\n<head>\n" +
    "<style type=\"text/css\">\n" + css + "</style>" + 
    "</head><body><main><section class='content'>";

let tplLower = "</body></html>";

marked.setOptions({
  highlight: function (code) { return require('highlight.js').highlightAuto(code).value; }
});

let d = "mithril.js/docs/";
let tplFiles = fs.readdirSync(d);
let tplContents = {};

for (let i = 0; i < tplFiles.length; i++) {
  let f = tplFiles[i];
  let ff = d + f;
  if (!fs.lstatSync(ff).isFile()) {
    continue;
  }
  let p = path.parse(f);
  tplContents[p.name] = fs.readFileSync(ff).toString('utf8');
}

Object.keys(tplContents).forEach((k) => {
  console.log(k);
  let contents = tplContents[k];
  let o = contents;
  Object.keys(tplContents).forEach((l) => {
    // the open bracket helps make sure we are (probably) only stuffing around
    // with the markdown links and nothing else.
    contents = contents.split("(" + l + ".md").join("(" + l + ".html");
  });
  fs.writeFileSync(outPath + "/" + k + '.html', tplUpper + marked.parse(contents) + tplLower);
});
EOS
echo "$js" | node

# logo
echo "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAACYVBMVEVGokZGo0ZHo0dIo0hJpElKpEpLpUtMpUxMpkxNpk1Opk5Op05Pp09Qp1BQqFBRqFFSqFJRqVFSqVJTqVNUqVRUqlRVqlVWqlZXqldWq1ZXq1dYq1hYrFhZrFlarFparVpbrVtcrVxcrlxdrl1dr11fr19gr2BgsGBhsGFisGJhsWFjsWNksWRksmRlsmVmsmZns2dos2hotGhptGlrtWtttm1ut25vt29wt3BwuHBxuHFyuHJzuXN0uXR0unR1unV3und2u3Z3u3d4vHh5vHl6vHp8vXx7vnt9vn19v31+v35/v39/wH+BwIGCwIKCwYKDwYOEwYSFwoWGwoaGw4aHw4eJxImKxIqKxYqLxYuNxo2Pxo+RyJGTyZOVypWWypaWy5aYy5iYzJiazJqazZqbzZuezp6fz5+gz6Ci0aKj0aOk0aSm0qan06eo1Kip1Kmq1Kqs1ayt1q2t162v16+w2LCx2LGz2bO02rS12rW327e43Li63Lq73Lu63bq73bu83by93b283ry+376/37/A38DD4cPE4cTF4cXE4sTG4sbG48bH48fI48jI5MjJ5MnK5MrK5crL5cvM5szN5s3O5s7P58/Q59DR6NHT6dPU6dTV6dXT6tPV6tXX69fY7Nja7Nrb7dvc7dzc7tzd7t3e797f79/g8ODh8OHh8eHj8ePj8uPl8uXn8+fo9Ojp9Onq9Orp9enr9evs9ezs9uzt9u3u9u7v9+/x9/Hx+PHy+PLz+fP0+fTz+vP2+vb2+/b3+/f4+/j4/Pj5/Pn7/fv8/vz9/v3+/v79//3+//7///+mQrhrAAAAAWJLR0QAiAUdSAAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB+AJCQU4GKiwep8AAAJTSURBVDjLYzhFADBQUcGq9trO5SDGrskNzXPQFRxr0+IXFhEW1ujY4iUkLCIiLJi4G1nBCg8WpYCk7OQAXQ5OKefYrLQoMxalGoSCudq8cZsPgwyyF+LhnwlkHN/ZJiuWCVOw21wsH2JeKrtHs5TEdjB7rTbnBKiCdKY8iPw0HrsDpwpFIo9BVGiK7wUr2MprdxgscsRfvA9I6cmsgagvFY4FKygSqIAIbNLRPrBh0/5+pjIoX9VkD0iBp8J8iMBKHm1LfUObIGE/aBjYqi4DKbBVXQfmTpIXFZcyUBUXFxXZBVEQLTkXqOCYtdpmEK+IR5SnCEgf7pYVkp8FVhAnNhNkgoPyMiCnjlejlaUcLC5ryqsM1uOmsBCkIFWs+dSpdZzqO9Yq2IOEFzFmT+IxBjL2aRhuASlYwhZ66lSEePWpA06iILO8+eediuGrPnWqTcoPElA+7NO3G6oAGRUi4UdPdYu7HDo1X9b1yAkr9hUQBevl+KuEEkCmW7BXLtOXmghkaRisimRLgUVWC68IZyeIsd9RQF24HcQKljHlCjwCj+4p/KJKWTNWz87RFhMTC+tZuahRU1Qg4CRSgunkUWdnZGBk1YnMsBJgZGBgFpcsR0lRC0T8FjcW189cf/LUrqVtJRW9ikZbURRsM1E4hJxUp8t4HEdNtLFiBUjyJwO5u9BS9R5+qeUIBflc7hjJfpYI39SjEOb+dA7jg5j5ol2MP6Rpzf5dCwtt2ExXYctZG534xaVlZKTEhJOP4ch6M+I9HF18c9fgyZvH9h8iNfMCAEmLaj5hVA4RAAAAAElFTkSuQmCC" |
	base64 -d >Mithril.docset/icon.png

# plist
read -r -d '' plist <<EOS || true
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>mithril</string>
    <key>CFBundleName</key>
    <string>Mithril</string>
    <key>DocSetPlatformFamily</key>
    <string>mithril</string>
    <key>isDashDocset</key>
    <true/>
    <key>dashIndexFilePath</key>
    <string>mithril.html</string>
</dict>
</plist>
EOS
echo "$plist" >Mithril.docset/Contents/Info.plist

# index
index_path="Mithril.docset/Contents/Resources/docSet.dsidx"
rm -f "$index_path"

echo '
    CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);
    CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);
' | sqlite3 "$index_path"

find mithril.js/docs -maxdepth 1 -type f -name '*.md' -printf '%f\n' | while read -r line; do
	type="Guide"
	if [[ "$line" =~ ^mithril\. ]]; then
		type="Module"
	fi
	sqlite3 "$index_path" "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES('${line%%.md}', '$type', '${line%%.md}.html')"
done

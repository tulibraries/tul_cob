//require('mutationobserver-shim');
//global.MutationObserver = window.MutationObserver;
const fs = require('fs')
const path = require('path')
const mo = fs.readFileSync(
  path.resolve('node_modules', 'mutationobserver-shim', 'dist', 'mutationobserver.min.js'),
  { encoding: 'utf-8' },
);
const moScript = window.document.createElement('script');
moScript.textContent = mo;

window.document.body.appendChild(moScript);

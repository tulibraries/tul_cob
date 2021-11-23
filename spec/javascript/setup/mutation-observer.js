/**
 * @jest-environment jsdom
 */
require('mutationobserver-shim');
global.MutationObserver = window.MutationObserver;

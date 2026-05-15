// @selectize/selectize@0.15.2 downloaded from https://ga.jspm.io/npm:@selectize/selectize@0.15.2/dist/js/selectize.js

import*as t from"jquery";var e="default"in t?t.default:t;var n="undefined"!==typeof globalThis?globalThis:"undefined"!==typeof self?self:global;var i={};(function(t,n){i=n(e)})(0,(function(t){var highlight=function(t,e){if("string"!==typeof e||e.length){var i="string"===typeof e?new RegExp(e,"i"):e;var highlight=function(t){var e=0;if(3===t.nodeType){var n=t.data.search(i);if(n>=0&&t.data.length>0){var r=t.data.match(i);var o=document.createElement("span");o.className="highlight";var s=t.splitText(n);s.splitText(r[0].length);var a=s.cloneNode(true);o.appendChild(a);s.parentNode.replaceChild(o,s);e=1}}else if(1===t.nodeType&&t.childNodes&&!/(script|style)/i.test(t.tagName)&&("highlight"!==t.className||"SPAN"!==t.tagName))for(var l=0;l<t.childNodes.length;++l)l+=highlight(t.childNodes[l]);return e};return t.each((function(){highlight(this||n)}))}};t.fn.removeHighlight=function(){return this.find("span.highlight").each((function(){(this||n).parentNode.firstChild.nodeName;var t=(this||n).parentNode;t.replaceChild((this||n).firstChild,this||n);t.normalize()})).end()};var MicroEvent=function(){};MicroEvent.prototype={on:function(t,e){(this||n)._events=(this||n)._events||{};(this||n)._events[t]=(this||n)._events[t]||[];(this||n)._events[t].push(e)},off:function(t,e){var i=arguments.length;if(0===i)return delete(this||n)._events;if(1===i)return delete(this||n)._events[t];(this||n)._events=(this||n)._events||{};t in(this||n)._events!==false&&(this||n)._events[t].splice((this||n)._events[t].indexOf(e),1)},trigger:function(t){const e=(this||n)._events=(this||n)._events||{};if(t in e!==false)for(var i=0;i<e[t].length;i++)e[t][i].apply(this||n,Array.prototype.slice.call(arguments,1))}};
/**
   * Mixin will delegate all MicroEvent.js function in the destination object.
   *
   * - MicroEvent.mixin(Foobar) will make Foobar able to use MicroEvent
   *
   * @param {object} the object which will support MicroEvent
   */MicroEvent.mixin=function(t){var e=["on","off","trigger"];for(var n=0;n<e.length;n++)t.prototype[e[n]]=MicroEvent.prototype[e[n]]};var e={};e.mixin=function(t){t.plugins={};
/**
     * Initializes the listed plugins (with options).
     * Acceptable formats:
     *
     * List (without options):
     *   ['a', 'b', 'c']
     *
     * List (with options):
     *   [{'name': 'a', options: {}}, {'name': 'b', options: {}}]
     *
     * Hash (with options):
     *   {'a': { ... }, 'b': { ... }, 'c': { ... }}
     *
     * @param {mixed} plugins
     */t.prototype.initializePlugins=function(t){var e,r,o;var s=this||n;var a=[];s.plugins={names:[],settings:{},requested:{},loaded:{}};if(i.isArray(t))for(e=0,r=t.length;e<r;e++)if("string"===typeof t[e])a.push(t[e]);else{s.plugins.settings[t[e].name]=t[e].options;a.push(t[e].name)}else if(t)for(o in t)if(t.hasOwnProperty(o)){s.plugins.settings[o]=t[o];a.push(o)}while(a.length)s.require(a.shift())};t.prototype.loadPlugin=function(e){var i=this||n;var r=i.plugins;var o=t.plugins[e];if(!t.plugins.hasOwnProperty(e))throw new Error('Unable to find "'+e+'" plugin');r.requested[e]=true;r.loaded[e]=o.fn.apply(i,[i.plugins.settings[e]||{}]);r.names.push(e)};
/**
     * Initializes a plugin.
     *
     * @param {string} name
     */t.prototype.require=function(t){var e=this||n;var i=e.plugins;if(!e.plugins.loaded.hasOwnProperty(t)){if(i.requested[t])throw new Error('Plugin has circular dependency ("'+t+'")');e.loadPlugin(t)}return i.loaded[t]};
/**
     * Registers a plugin.
     *
     * @param {string} name
     * @param {function} fn
     */t.define=function(e,n){t.plugins[e]={name:e,fn:n}}};var i={isArray:Array.isArray||function(t){return"[object Array]"===Object.prototype.toString.call(t)}};
/**
   * Textually searches arrays and hashes of objects
   * by property (or multiple properties). Designed
   * specifically for autocomplete.
   *
   * @constructor
   * @param {array|object} items
   * @param {object} items
   */var Sifter=function(t,e){(this||n).items=t;(this||n).settings=e||{diacritics:true}};
/**
   * Splits a search string into an array of individual
   * regexps to be used to match results.
   *
   * @param {string} query
   * @returns {array}
   */Sifter.prototype.tokenize=function(t,e){t=trim(String(t||"").toLowerCase());if(!t||!t.length)return[];var i,r,s,a;var l=[];var u=t.split(/ +/);for(i=0,r=u.length;i<r;i++){s=escape_regex(u[i]);if((this||n).settings.diacritics)for(a in o)o.hasOwnProperty(a)&&(s=s.replace(new RegExp(a,"g"),o[a]));e&&(s="\\b"+s);l.push({string:u[i],regex:new RegExp(s,"i")})}return l};
/**
   * Iterates over arrays and hashes.
   *
   * ```
   * this.iterator(this.items, function(item, id) {
   *    // invoked for each item
   * });
   * ```
   *
   * @param {array|object} object
   */Sifter.prototype.iterator=function(t,e){var i;i=r(t)?Array.prototype.forEach||function(t){for(var e=0,i=(this||n).length;e<i;e++)t((this||n)[e],e,this||n)}:function(t){for(var e in this||n)this.hasOwnProperty(e)&&t((this||n)[e],e,this||n)};i.apply(t,[e])};
/**
   * Returns a function to be used to score individual results.
   *
   * Good matches will have a higher score than poor matches.
   * If an item is not a match, 0 will be returned by the function.
   *
   * @param {object|string} search
   * @param {object} options (optional)
   * @returns {function}
   */Sifter.prototype.getScoreFunction=function(t,e){var i,r,o,s,a;i=this||n;t=i.prepareSearch(t,e);o=t.tokens;r=t.options.fields;s=o.length;a=t.options.nesting;
/**
     * Calculates how close of a match the
     * given value is against a search token.
     *
     * @param {mixed} value
     * @param {object} token
     * @return {number}
     */var scoreValue=function(t,e){var n,i;if(!t)return 0;t=String(t||"");i=t.search(e.regex);if(-1===i)return 0;n=e.string.length/t.length;0===i&&(n+=.5);return n};
/**
     * Calculates the score of an object
     * against the search query.
     *
     * @param {object} token
     * @param {object} data
     * @return {number}
     */var l=function(){var t=r.length;return t?1===t?function(t,e){return scoreValue(getattr(e,r[0],a),t)}:function(e,n){for(var i=0,o=0;i<t;i++)o+=scoreValue(getattr(n,r[i],a),e);return o/t}:function(){return 0}}();return s?1===s?function(t){return l(o[0],t)}:"and"===t.options.conjunction?function(t){var e;for(var n=0,i=0;n<s;n++){e=l(o[n],t);if(e<=0)return 0;i+=e}return i/s}:function(t){for(var e=0,n=0;e<s;e++)n+=l(o[e],t);return n/s}:function(){return 0}};
/**
   * Returns a function that can be used to compare two
   * results, for sorting purposes. If no sorting should
   * be performed, `null` will be returned.
   *
   * @param {string|object} search
   * @param {object} options
   * @return function(a,b)
   */Sifter.prototype.getSortFunction=function(t,e){var i,r,o,s,a,l,u,p,d,c,f;o=this||n;t=o.prepareSearch(t,e);f=!t.query&&e.sort_empty||e.sort;
/**
     * Fetches the specified sort field value
     * from a search result item.
     *
     * @param  {string} name
     * @param  {object} result
     * @return {mixed}
     */d=function(t,n){return"$score"===t?n.score:getattr(o.items[n.id],t,e.nesting)};a=[];if(f)for(i=0,r=f.length;i<r;i++)(t.query||"$score"!==f[i].field)&&a.push(f[i]);if(t.query){c=true;for(i=0,r=a.length;i<r;i++)if("$score"===a[i].field){c=false;break}c&&a.unshift({field:"$score",direction:"desc"})}else for(i=0,r=a.length;i<r;i++)if("$score"===a[i].field){a.splice(i,1);break}p=[];for(i=0,r=a.length;i<r;i++)p.push("desc"===a[i].direction?-1:1);l=a.length;if(l){if(1===l){s=a[0].field;u=p[0];return function(t,e){return u*cmp(d(s,t),d(s,e))}}return function(t,e){var n,i,r;for(n=0;n<l;n++){r=a[n].field;i=p[n]*cmp(d(r,t),d(r,e));if(i)return i}return 0}}return null};
/**
   * Parses a search query and returns an object
   * with tokens and fields ready to be populated
   * with results.
   *
   * @param {string} query
   * @param {object} options
   * @returns {object}
   */Sifter.prototype.prepareSearch=function(t,e){if("object"===typeof t)return t;e=extend({},e);var n=e.fields;var i=e.sort;var o=e.sort_empty;n&&!r(n)&&(e.fields=[n]);i&&!r(i)&&(e.sort=[i]);o&&!r(o)&&(e.sort_empty=[o]);return{options:e,query:String(t||"").toLowerCase(),tokens:this.tokenize(t,e.respect_word_boundaries),total:0,items:[]}};
/**
   * Searches through all items and returns a sorted array of matches.
   *
   * The `options` parameter can contain:
   *
   *   - fields {string|array}
   *   - sort {array}
   *   - score {function}
   *   - filter {bool}
   *   - limit {integer}
   *
   * Returns an object containing:
   *
   *   - options {object}
   *   - query {string}
   *   - tokens {array}
   *   - total {int}
   *   - items {array}
   *
   * @param {string} query
   * @param {object} options
   * @returns {object}
   */Sifter.prototype.search=function(t,e){var i,r,o=this||n;var s;var a;r=this.prepareSearch(t,e);e=r.options;t=r.query;a=e.score||o.getScoreFunction(r);t.length?o.iterator(o.items,(function(t,n){i=a(t);(false===e.filter||i>0)&&r.items.push({score:i,id:n})})):o.iterator(o.items,(function(t,e){r.items.push({score:1,id:e})}));s=o.getSortFunction(r,e);s&&r.items.sort(s);r.total=r.items.length;"number"===typeof e.limit&&(r.items=r.items.slice(0,e.limit));return r};var cmp=function(t,e){if("number"===typeof t&&"number"===typeof e)return t>e?1:t<e?-1:0;t=s(String(t||""));e=s(String(e||""));return t>e?1:e>t?-1:0};var extend=function(t,e){var n,i,r,o;for(n=1,i=arguments.length;n<i;n++){o=arguments[n];if(o)for(r in o)o.hasOwnProperty(r)&&(t[r]=o[r])}return t};
/**
   * A property getter resolving dot-notation
   * @param  {Object}  obj     The root object to fetch property on
   * @param  {String}  name    The optionally dotted property name to fetch
   * @param  {Boolean} nesting Handle nesting or not
   * @return {Object}          The resolved property value
   */var getattr=function(t,e,n){if(t&&e){if(!n)return t[e];var i=e.split(".");while(i.length&&(t=t[i.shift()]));return t}};var trim=function(t){return(t+"").replace(/^\s+|\s+$|/g,"")};var escape_regex=function(t){return(t+"").replace(/([.?*+^$[\]\\(){}|-])/g,"\\$1")};var r=Array.isArray||"undefined"!==typeof t&&t.isArray||function(t){return"[object Array]"===Object.prototype.toString.call(t)};var o={a:"[aḀḁĂăÂâǍǎȺⱥȦȧẠạÄäÀàÁáĀāÃãÅåąĄÃąĄ]",b:"[b␢βΒB฿𐌁ᛒ]",c:"[cĆćĈĉČčĊċC̄c̄ÇçḈḉȻȼƇƈɕᴄＣｃ]",d:"[dĎďḊḋḐḑḌḍḒḓḎḏĐđD̦d̦ƉɖƊɗƋƌᵭᶁᶑȡᴅＤｄð]",e:"[eÉéÈèÊêḘḙĚěĔĕẼẽḚḛẺẻĖėËëĒēȨȩĘęᶒɆɇȄȅẾếỀềỄễỂểḜḝḖḗḔḕȆȇẸẹỆệⱸᴇＥｅɘǝƏƐε]",f:"[fƑƒḞḟ]",g:"[gɢ₲ǤǥĜĝĞğĢģƓɠĠġ]",h:"[hĤĥĦħḨḩẖẖḤḥḢḣɦʰǶƕ]",i:"[iÍíÌìĬĭÎîǏǐÏïḮḯĨĩĮįĪīỈỉȈȉȊȋỊịḬḭƗɨɨ̆ᵻᶖİiIıɪＩｉ]",j:"[jȷĴĵɈɉʝɟʲ]",k:"[kƘƙꝀꝁḰḱǨǩḲḳḴḵκϰ₭]",l:"[lŁłĽľĻļĹĺḶḷḸḹḼḽḺḻĿŀȽƚⱠⱡⱢɫɬᶅɭȴʟＬｌ]",n:"[nŃńǸǹŇňÑñṄṅŅņṆṇṊṋṈṉN̈n̈ƝɲȠƞᵰᶇɳȵɴＮｎŊŋ]",o:"[oØøÖöÓóÒòÔôǑǒŐőŎŏȮȯỌọƟɵƠơỎỏŌōÕõǪǫȌȍՕօ]",p:"[pṔṕṖṗⱣᵽƤƥᵱ]",q:"[qꝖꝗʠɊɋꝘꝙq̃]",r:"[rŔŕɌɍŘřŖŗṘṙȐȑȒȓṚṛⱤɽ]",s:"[sŚśṠṡṢṣꞨꞩŜŝŠšŞşȘșS̈s̈]",t:"[tŤťṪṫŢţṬṭƮʈȚțṰṱṮṯƬƭ]",u:"[uŬŭɄʉỤụÜüÚúÙùÛûǓǔŰűŬŭƯưỦủŪūŨũŲųȔȕ∪]",v:"[vṼṽṾṿƲʋꝞꝟⱱʋ]",w:"[wẂẃẀẁŴŵẄẅẆẇẈẉ]",x:"[xẌẍẊẋχ]",y:"[yÝýỲỳŶŷŸÿỸỹẎẏỴỵɎɏƳƴ]",z:"[zŹźẐẑŽžŻżẒẓẔẕƵƶ]"};var s=function(){var t,e,n,i;var r="";var s={};for(n in o)if(o.hasOwnProperty(n)){i=o[n].substring(2,o[n].length-1);r+=i;for(t=0,e=i.length;t<e;t++)s[i.charAt(t)]=n}var a=new RegExp("["+r+"]","g");return function(t){return t.replace(a,(function(t){return s[t]})).toLowerCase()}}();function uaDetect(t,e){return navigator.userAgentData?t===navigator.userAgentData.platform:e.test(navigator.userAgent)}var a=uaDetect("macOS",/Mac/);var l=65;var u=13;var p=27;var d=37;var c=38;var f=80;var h=39;var g=40;var v=78;var m=8;var y=46;var w=16;var O=a?91:17;var $=a?18:17;var b=9;var C=1;var x=2;var _=!uaDetect("Android",/android/i)&&!!document.createElement("input").validity;
/**
   * Determines if the provided value has been defined.
   *
   * @param {mixed} object
   * @returns {boolean}
   */var isset=function(t){return"undefined"!==typeof t};
/**
   * Converts a scalar to its best string representation
   * for hash keys and HTML attribute values.
   *
   * Transformations:
   *   'str'     -> 'str'
   *   null      -> ''
   *   undefined -> ''
   *   true      -> '1'
   *   false     -> '0'
   *   0         -> '0'
   *   1         -> '1'
   *
   * @param {string} value
   * @returns {string|null}
   */var hash_key=function(t){return"undefined"===typeof t||null===t?null:"boolean"===typeof t?t?"1":"0":t+""};
/**
   * Escapes a string for use within HTML.
   *
   * @param {string} str
   * @returns {string}
   */var escape_html=function(t){return(t+"").replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;")};
/**
   * Escapes "$" characters in replacement strings.
   *
   * @param {string} str
   * @returns {string}
   */var I={};
/**
   * Wraps `method` on `self` so that `fn`
   * is invoked before the original method.
   *
   * @param {object} self
   * @param {string} method
   * @param {function} fn
   */I.before=function(t,e,n){var i=t[e];t[e]=function(){n.apply(t,arguments);return i.apply(t,arguments)}};
/**
   * Wraps `method` on `self` so that `fn`
   * is invoked after the original method.
   *
   * @param {object} self
   * @param {string} method
   * @param {function} fn
   */I.after=function(t,e,n){var i=t[e];t[e]=function(){var e=i.apply(t,arguments);n.apply(t,arguments);return e}};
/**
   * Wraps `fn` so that it can only be invoked once.
   *
   * @param {function} fn
   * @returns {function}
   */var once=function(t){var e=false;return function(){if(!e){e=true;t.apply(this||n,arguments)}}};
/**
   * Wraps `fn` so that it can only be called once
   * every `delay` milliseconds (invoked on the falling edge).
   *
   * @param {function} fn
   * @param {int} delay
   * @returns {function}
   */var debounce=function(t,e){var i;return function(){var r=this||n;var o=arguments;window.clearTimeout(i);i=window.setTimeout((function(){t.apply(r,o)}),e)}};
/**
   * Debounce all fired events types listed in `types`
   * while executing the provided `fn`.
   *
   * @param {object} self
   * @param {array} types
   * @param {function} fn
   */var debounce_events=function(t,e,n){var i;var r=t.trigger;var o={};t.trigger=function(){var n=arguments[0];if(-1===e.indexOf(n))return r.apply(t,arguments);o[n]=arguments};n.apply(t,[]);t.trigger=r;for(i in o)o.hasOwnProperty(i)&&r.apply(t,o[i])};
/**
   * A workaround for http://bugs.jquery.com/ticket/6696
   *
   * @param {object} $parent - Parent element to listen on.
   * @param {string} event - Event name.
   * @param {string} selector - Descendant selector to filter by.
   * @param {function} fn - Event handler.
   */var watchChildEvent=function(t,e,i,r){t.on(e,i,(function(e){var i=e.target;while(i&&i.parentNode!==t[0])i=i.parentNode;e.currentTarget=i;return r.apply(this||n,[e])}))};
/**
   * Determines the current selection within a text input control.
   * Returns an object containing:
   *   - start
   *   - length
   *
   * @param {object} input
   * @returns {object}
   */var getInputSelection=function(t){var e={};if(void 0===t){console.warn("WARN getInputSelection cannot locate input control");return e}if("selectionStart"in t){e.start=t.selectionStart;e.length=t.selectionEnd-e.start}else if(document.selection){t.focus();var n=document.selection.createRange();var i=document.selection.createRange().text.length;n.moveStart("character",-t.value.length);e.start=n.text.length-i;e.length=i}return e};
/**
   * Copies CSS properties from one element to another.
   *
   * @param {object} $from
   * @param {object} $to
   * @param {array} properties
   */var transferStyles=function(t,e,n){var i,r,o={};if(n)for(i=0,r=n.length;i<r;i++)o[n[i]]=t.css(n[i]);else o=t.css();e.css(o)};
/**
   * Measures the width of a string within a
   * parent element (in pixels).
   *
   * @param {string} str
   * @param {object} $parent
   * @returns {int}
   */var measureString=function(e,n){if(!e)return 0;if(!Selectize.$testInput){Selectize.$testInput=t("<span />").css({position:"absolute",width:"auto",padding:0,whiteSpace:"pre"});t("<div />").css({position:"absolute",width:0,height:0,overflow:"hidden"}).append(Selectize.$testInput).appendTo("body")}Selectize.$testInput.text(e);transferStyles(n,Selectize.$testInput,["letterSpacing","fontSize","fontFamily","fontWeight","textTransform"]);return Selectize.$testInput.width()};
/**
   * Sets up an input to grow horizontally as the user
   * types. If the value is changed manually, you can
   * trigger the "update" handler to resize:
   *
   * $input.trigger('update');
   *
   * @param {object} $input
   */var autoGrow=function(t){var e=null;var update=function(n,i){var r,o,s,a;var l,u;var p,d,c;n=n||window.event||{};i=i||{};if(!n.metaKey&&!n.altKey&&(i.force||false!==t.data("grow"))){r=t.val();if(n.type&&"keydown"===n.type.toLowerCase()){o=n.keyCode;s=o>=48&&o<=57||o>=65&&o<=90||o>=96&&o<=111||o>=186&&o<=222||32===o;if(o===y||o===m){c=getInputSelection(t[0]);c.length?r=r.substring(0,c.start)+r.substring(c.start+c.length):o===m&&c.start?r=r.substring(0,c.start-1)+r.substring(c.start+1):o===y&&"undefined"!==typeof c.start&&(r=r.substring(0,c.start)+r.substring(c.start+1))}else if(s){p=n.shiftKey;d=String.fromCharCode(n.keyCode);d=p?d.toUpperCase():d.toLowerCase();r+=d}}l=t.attr("placeholder");u=l?measureString(l,t)+4:0;a=Math.max(measureString(r,t),u)+4;if(a!==e){e=a;t.width(a);t.triggerHandler("resize")}}};t.on("keydown keyup update blur",update);update()};var domToString=function(t){var e=document.createElement("div");e.appendChild(t.cloneNode(true));return e.innerHTML};
/**
   *
   * @param {any} data Data to testing
   * @returns {Boolean} true if is an JSON object
   */
var isJSON=function(t){try{JSON.parse(str)}catch(t){return false}return true};var Selectize=function(e,i){var r,o,s,a,l=this||n;a=e[0];a.selectize=l;var u=window.getComputedStyle&&window.getComputedStyle(a,null);s=u?u.getPropertyValue("direction"):a.currentStyle&&a.currentStyle.direction;s=s||e.parents("[dir]:first").attr("dir")||"";t.extend(l,{order:0,settings:i,$input:e,tabIndex:e.attr("tabindex")||"",tagType:"select"===a.tagName.toLowerCase()?C:x,rtl:/rtl/i.test(s),eventNS:".selectize"+ ++Selectize.count,highlightedValue:null,isBlurring:false,isOpen:false,isDisabled:false,isRequired:e.is("[required]"),isInvalid:false,isLocked:false,isFocused:false,isInputHidden:false,isSetup:false,isShiftDown:false,isCmdDown:false,isCtrlDown:false,ignoreFocus:false,ignoreBlur:false,ignoreHover:false,hasOptions:false,currentResults:null,lastValue:"",lastValidValue:"",lastOpenTarget:false,caretPos:0,loading:0,loadedSearches:{},isDropdownClosing:false,$activeOption:null,$activeItems:[],optgroups:{},options:{},userOptions:{},items:[],renderCache:{},onSearchChange:null===i.loadThrottle?l.onSearchChange:debounce(l.onSearchChange,i.loadThrottle)});l.sifter=new Sifter((this||n).options,{diacritics:i.diacritics});if(l.settings.options){for(r=0,o=l.settings.options.length;r<o;r++)l.registerOption(l.settings.options[r]);delete l.settings.options}if(l.settings.optgroups){for(r=0,o=l.settings.optgroups.length;r<o;r++)l.registerOptionGroup(l.settings.optgroups[r]);delete l.settings.optgroups}l.settings.mode=l.settings.mode||(1===l.settings.maxItems?"single":"multi");"boolean"!==typeof l.settings.hideSelected&&(l.settings.hideSelected="multi"===l.settings.mode);l.initializePlugins(l.settings.plugins);l.setupCallbacks();l.setupTemplates();l.setup()};MicroEvent.mixin(Selectize);e.mixin(Selectize);t.extend(Selectize.prototype,{setup:function(){var e=this||n;var i=e.settings;var r=e.eventNS;var o=t(window);var s=t(document);var l=e.$input;var u;var p;var d;var c;var f;var h;var g;var v;var m;var y;g=e.settings.mode;v=l.attr("class")||"";u=t("<div>").addClass(i.wrapperClass).addClass(v+" selectize-control").addClass(g);p=t("<div>").addClass(i.inputClass+" selectize-input items").appendTo(u);d=t('<input type="select-one" autocomplete="new-password" autofill="no" />').appendTo(p).attr("tabindex",l.is(":disabled")?"-1":e.tabIndex);h=t(i.dropdownParent||u);c=t("<div>").addClass(i.dropdownClass).addClass(g+" selectize-dropdown").hide().appendTo(h);f=t("<div>").addClass(i.dropdownContentClass+" selectize-dropdown-content").attr("tabindex","-1").appendTo(c);if(y=l.attr("id")){d.attr("id",y+"-selectized");t("label[for='"+y+"']").attr("for",y+"-selectized")}e.settings.copyClassesToDropdown&&c.addClass(v);u.css({width:l[0].style.width});if(e.plugins.names.length){m="plugin-"+e.plugins.names.join(" plugin-");u.addClass(m);c.addClass(m)}(null===i.maxItems||i.maxItems>1)&&e.tagType===C&&l.attr("multiple","multiple");e.settings.placeholder&&d.attr("placeholder",i.placeholder);if(!e.settings.search){d.attr("readonly",true);d.attr("inputmode","none");p.css("cursor","pointer")}if(!e.settings.splitOn&&e.settings.delimiter){var b=e.settings.delimiter.replace(/[-\/\\^$*+?.()|[\]{}]/g,"\\$&");e.settings.splitOn=new RegExp("\\s*"+b+"+\\s*")}l.attr("autocorrect")&&d.attr("autocorrect",l.attr("autocorrect"));l.attr("autocapitalize")&&d.attr("autocapitalize",l.attr("autocapitalize"));l.is("input")&&(d[0].type=l[0].type);e.$wrapper=u;e.$control=p;e.$control_input=d;e.$dropdown=c;e.$dropdown_content=f;c.on("mouseenter mousedown mouseup click","[data-disabled]>[data-selectable]",(function(t){t.stopImmediatePropagation()}));c.on("mouseenter","[data-selectable]",(function(){return e.onOptionHover.apply(e,arguments)}));c.on("mouseup click","[data-selectable]",(function(){return e.onOptionSelect.apply(e,arguments)}));watchChildEvent(p,"mouseup","*:not(input)",(function(){return e.onItemSelect.apply(e,arguments)}));autoGrow(d);p.on({mousedown:function(){return e.onMouseDown.apply(e,arguments)},click:function(){return e.onClick.apply(e,arguments)}});d.on({mousedown:function(t){(""!==e.$control_input.val()||e.settings.openOnFocus)&&t.stopPropagation()},keydown:function(){return e.onKeyDown.apply(e,arguments)},keypress:function(){return e.onKeyPress.apply(e,arguments)},input:function(){return e.onInput.apply(e,arguments)},resize:function(){e.positionDropdown.apply(e,[])},focus:function(){e.ignoreBlur=false;return e.onFocus.apply(e,arguments)},paste:function(){return e.onPaste.apply(e,arguments)}});s.on("keydown"+r,(function(t){e.isCmdDown=t[a?"metaKey":"ctrlKey"];e.isCtrlDown=t[a?"altKey":"ctrlKey"];e.isShiftDown=t.shiftKey}));s.on("keyup"+r,(function(t){t.keyCode===$&&(e.isCtrlDown=false);t.keyCode===w&&(e.isShiftDown=false);t.keyCode===O&&(e.isCmdDown=false)}));s.on("mousedown"+r,(function(t){if(e.isFocused){if(t.target===e.$dropdown[0]||t.target.parentNode===e.$dropdown[0])return false;e.$dropdown.has(t.target).length||t.target===e.$control[0]||e.blur(t.target)}}));o.on(["scroll"+r,"resize"+r].join(" "),(function(){e.isOpen&&e.positionDropdown.apply(e,arguments)}));o.on("mousemove"+r,(function(){e.ignoreHover=e.settings.ignoreHover}));var x=t("<div></div>");var I=l.children().detach();l.replaceWith(x);x.replaceWith(l);(this||n).revertSettings={$children:I,tabindex:l.attr("tabindex")};l.attr("tabindex",-1).hide().after(e.$wrapper);if(Array.isArray(i.items)){e.lastValidValue=i.items;e.setValue(i.items);delete i.items}_&&l.on("invalid"+r,(function(t){t.preventDefault();e.isInvalid=true;e.refreshState()}));e.updateOriginalInput();e.refreshItems();e.refreshState();e.updatePlaceholder();e.isSetup=true;l.is(":disabled")&&e.disable();e.on("change",(this||n).onChange);l.data("selectize",e);l.addClass("selectized");e.trigger("initialize");true===i.preload&&e.onSearchChange("")},setupTemplates:function(){var e=this||n;var i=e.settings.labelField;var r=e.settings.valueField;var o=e.settings.optgroupLabelField;var s={optgroup:function(t){return'<div class="optgroup">'+t.html+"</div>"},optgroup_header:function(t,e){return'<div class="optgroup-header">'+e(t[o])+"</div>"},option:function(t,e){var n=t.classes?" "+t.classes:"";n+=""===t[r]?" selectize-dropdown-emptyoptionlabel":"";var o=t.styles?' style="'+t.styles+'"':"";return"<div"+o+' class="option'+n+'">'+e(t[i])+"</div>"},item:function(t,e){return'<div class="item">'+e(t[i])+"</div>"},option_create:function(t,e){return'<div class="create">Add <strong>'+e(t.input)+"</strong>&#x2026;</div>"}};e.settings.render=t.extend({},s,e.settings.render)},setupCallbacks:function(){var t,e,i={initialize:"onInitialize",change:"onChange",item_add:"onItemAdd",item_remove:"onItemRemove",clear:"onClear",option_add:"onOptionAdd",option_remove:"onOptionRemove",option_clear:"onOptionClear",optgroup_add:"onOptionGroupAdd",optgroup_remove:"onOptionGroupRemove",optgroup_clear:"onOptionGroupClear",dropdown_open:"onDropdownOpen",dropdown_close:"onDropdownClose",type:"onType",load:"onLoad",focus:"onFocus",blur:"onBlur",dropdown_item_activate:"onDropdownItemActivate",dropdown_item_deactivate:"onDropdownItemDeactivate"};for(t in i)if(i.hasOwnProperty(t)){e=(this||n).settings[i[t]];e&&this.on(t,e)}},
/**
     * Triggered when the main control element
     * has a click event.
     *
     * @param {PointerEvent} e
     * @return {boolean}
     */
onClick:function(t){var e=this||n;if(!e.isDropdownClosing&&(!e.isFocused||!e.isOpen)){e.focus();t.preventDefault()}},
/**
     * Triggered when the main control element
     * has a mouse down event.
     *
     * @param {object} e
     * @return {boolean}
     */
onMouseDown:function(e){var i=this||n;var r=e.isDefaultPrevented();t(e.target);i.isFocused||r||window.setTimeout((function(){i.focus()}),0);if(e.target!==i.$control_input[0]||""===i.$control_input.val()){if("single"===i.settings.mode)i.isOpen?i.close():i.open();else{r||i.setActiveItem(null);if(!i.settings.openOnFocus)if(i.isOpen&&e.target===i.lastOpenTarget){i.close();i.lastOpenTarget=false}else if(i.isOpen)i.lastOpenTarget=e.target;else{i.refreshOptions();i.open();i.lastOpenTarget=e.target}}return false}},onChange:function(){var t=this||n;""!==t.getValue()&&(t.lastValidValue=t.getValue());(this||n).$input.trigger("input");(this||n).$input.trigger("change")},
/**
     * Triggered on <input> paste.
     *
     * @param {object} e
     * @returns {boolean}
     */
onPaste:function(t){var e=this||n;e.isFull()||e.isInputHidden||e.isLocked?t.preventDefault():e.settings.splitOn&&setTimeout((function(){var t=e.$control_input.val();if(t.match(e.settings.splitOn)){var n=t.trim().split(e.settings.splitOn);for(var i=0,r=n.length;i<r;i++)e.createItem(n[i])}}),0)},
/**
     * Triggered on <input> keypress.
     *
     * @param {object} e
     * @returns {boolean}
     */
onKeyPress:function(t){if((this||n).isLocked)return t&&t.preventDefault();var e=String.fromCharCode(t.keyCode||t.which);if((this||n).settings.create&&"multi"===(this||n).settings.mode&&e===(this||n).settings.delimiter){this.createItem();t.preventDefault();return false}},
/**
     * Triggered on <input> keydown.
     *
     * @param {object} e
     * @returns {boolean}
     */
onKeyDown:function(t){t.target,(this||n).$control_input[0];var e=this||n;if(e.isLocked)t.keyCode!==b&&t.preventDefault();else{switch(t.keyCode){case l:if(e.isCmdDown){e.selectAll();return}break;case p:if(e.isOpen){t.preventDefault();t.stopPropagation();e.close()}return;case v:if(!t.ctrlKey||t.altKey)break;case g:if(!e.isOpen&&e.hasOptions)e.open();else if(e.$activeOption){e.ignoreHover=true;var i=e.getAdjacentOption(e.$activeOption,1);i.length&&e.setActiveOption(i,true,true)}t.preventDefault();return;case f:if(!t.ctrlKey||t.altKey)break;case c:if(e.$activeOption){e.ignoreHover=true;var r=e.getAdjacentOption(e.$activeOption,-1);r.length&&e.setActiveOption(r,true,true)}t.preventDefault();return;case u:if(e.isOpen&&e.$activeOption){e.onOptionSelect({currentTarget:e.$activeOption});t.preventDefault()}return;case d:e.advanceSelection(-1,t);return;case h:e.advanceSelection(1,t);return;case b:if(e.settings.selectOnTab&&e.isOpen&&e.$activeOption){e.onOptionSelect({currentTarget:e.$activeOption});e.isFull()||t.preventDefault()}e.settings.create&&e.createItem()&&e.settings.showAddOptionOnCreate&&t.preventDefault();return;case m:case y:e.deleteSelection(t);return}!e.isFull()&&!e.isInputHidden||(a?t.metaKey:t.ctrlKey)||t.preventDefault()}},
/**
     * Triggered on <input> input.
     *
     * @param {object} e
     * @returns {boolean}
     */
onInput:function(t){var e=this||n;var i=e.$control_input.val()||"";if(e.lastValue!==i){e.lastValue=i;e.onSearchChange(i);e.refreshOptions();e.trigger("type",i)}},
/**
     * Invokes the user-provide option provider / loader.
     *
     * Note: this function is debounced in the Selectize
     * constructor (by `settings.loadThrottle` milliseconds)
     *
     * @param {string} value
     */
onSearchChange:function(t){var e=this||n;var i=e.settings.load;if(i&&!e.loadedSearches.hasOwnProperty(t)){e.loadedSearches[t]=true;e.load((function(n){i.apply(e,[t,n])}))}},
/**
     * Triggered on <input> focus.
     *
     * @param {FocusEvent} e (optional)
     * @returns {boolean}
     */
onFocus:function(t){var e=this||n;var i=e.isFocused;if(e.isDisabled){e.blur();t&&t.preventDefault();return false}if(!e.ignoreFocus){e.isFocused=true;"focus"===e.settings.preload&&e.onSearchChange("");i||e.trigger("focus");if(!e.$activeItems.length){e.showInput();e.setActiveItem(null);e.refreshOptions(!!e.settings.openOnFocus)}e.refreshState()}},
/**
     * Triggered on <input> blur.
     *
     * @param {object} e
     * @param {Element} dest
     */
onBlur:function(t,e){var i=this||n;if(i.isFocused){i.isFocused=false;if(!i.ignoreFocus){var deactivate=function(){i.close();i.setTextboxValue("");i.setActiveItem(null);i.setActiveOption(null);i.setCaret(i.items.length);i.refreshState();e&&e.focus&&e.focus();i.isBlurring=false;i.ignoreFocus=false;i.trigger("blur")};i.isBlurring=true;i.ignoreFocus=true;i.settings.create&&i.settings.createOnBlur?i.createItem(null,false,deactivate):deactivate()}}},
/**
     * Triggered when the user rolls over
     * an option in the autocomplete dropdown menu.
     *
     * @param {object} e
     * @returns {boolean}
     */
onOptionHover:function(t){(this||n).ignoreHover||this.setActiveOption(t.currentTarget,false)},
/**
     * Triggered when the user clicks on an option
     * in the autocomplete dropdown menu.
     *
     * @param {object} e
     * @returns {boolean}
     */
onOptionSelect:function(e){var i,r,o=this||n;if(e.preventDefault){e.preventDefault();e.stopPropagation()}r=t(e.currentTarget);if(r.hasClass("create"))o.createItem(null,(function(){o.settings.closeAfterSelect&&o.close()}));else{i=r.attr("data-value");if("undefined"!==typeof i){o.lastQuery=null;o.setTextboxValue("");o.addItem(i);o.settings.closeAfterSelect?o.close():!o.settings.hideSelected&&e.type&&/mouse/.test(e.type)&&o.setActiveOption(o.getOption(i))}}},
/**
     * Triggered when the user clicks on an item
     * that has been selected.
     *
     * @param {object} e
     * @returns {boolean}
     */
onItemSelect:function(t){var e=this||n;if(!e.isLocked&&"multi"===e.settings.mode){t.preventDefault();e.setActiveItem(t.currentTarget,t)}},
/**
     * Invokes the provided method that provides
     * results to a callback---which are then added
     * as options to the control.
     *
     * @param {function} fn
     */
load:function(t){var e=this||n;var i=e.$wrapper.addClass(e.settings.loadingClass);e.loading++;t.apply(e,[function(t){e.loading=Math.max(e.loading-1,0);if(t&&t.length){e.addOption(t);e.refreshOptions(e.isFocused&&!e.isInputHidden)}e.loading||i.removeClass(e.settings.loadingClass);e.trigger("load",t)}])},
/**
     * Gets the value of input field of the control.
     *
     * @returns {string} value
     */
getTextboxValue:function(){var t=(this||n).$control_input;return t.val()},
/**
     * Sets the input field of the control to the specified value.
     *
     * @param {string} value
     */
setTextboxValue:function(t){var e=(this||n).$control_input;var i=e.val()!==t;if(i){e.val(t).triggerHandler("update");(this||n).lastValue=t}},
/**
     * Returns the value of the control. If multiple items
     * can be selected (e.g. <select multiple>), this returns
     * an array. If only one item can be selected, this
     * returns a string.
     *
     * @returns {mixed}
     */
getValue:function(){return(this||n).tagType===C&&(this||n).$input.attr("multiple")?(this||n).items:(this||n).items.join((this||n).settings.delimiter)},
/**
     * Resets the selected items to the given value.
     *
     * @param {Array<String|Number>} value
     */
setValue:function(t,e){const i=Array.isArray(t)?t:[t];if(i.join("")!==(this||n).items.join("")){var r=e?[]:["change"];debounce_events(this||n,r,(function(){this.clear(e);this.addItems(t,e)}))}},
/**
     * Resets the number of max items to the given value
     *
     * @param {number} value
     */
setMaxItems:function(t){0===t&&(t=null);(this||n).settings.maxItems=t;(this||n).settings.mode=(this||n).settings.mode||(1===(this||n).settings.maxItems?"single":"multi");this.refreshState()},
/**
     * Sets the selected item.
     *
     * @param {object} $item
     * @param {object} e (optional)
     */
setActiveItem:function(e,i){var r=this||n;var o;var s,a,l,u,p,d;var c;if("single"!==r.settings.mode){e=t(e);if(e.length){o=i&&i.type.toLowerCase();if("mousedown"===o&&r.isShiftDown&&r.$activeItems.length){c=r.$control.children(".active:last");l=Array.prototype.indexOf.apply(r.$control[0].childNodes,[c[0]]);u=Array.prototype.indexOf.apply(r.$control[0].childNodes,[e[0]]);if(l>u){d=l;l=u;u=d}for(s=l;s<=u;s++){p=r.$control[0].childNodes[s];if(-1===r.$activeItems.indexOf(p)){t(p).addClass("active");r.$activeItems.push(p)}}i.preventDefault()}else if("mousedown"===o&&r.isCtrlDown||"keydown"===o&&(this||n).isShiftDown)if(e.hasClass("active")){a=r.$activeItems.indexOf(e[0]);r.$activeItems.splice(a,1);e.removeClass("active")}else r.$activeItems.push(e.addClass("active")[0]);else{t(r.$activeItems).removeClass("active");r.$activeItems=[e.addClass("active")[0]]}r.hideInput();(this||n).isFocused||r.focus()}else{t(r.$activeItems).removeClass("active");r.$activeItems=[];r.isFocused&&r.showInput()}}},
/**
     * Sets the selected item in the dropdown menu
     * of available options.
     *
     * @param {object} $object
     * @param {boolean} scroll
     * @param {boolean} animate
     */
setActiveOption:function(e,i,r){var o,s,a;var l,u;var p=this||n;if(p.$activeOption){p.$activeOption.removeClass("active");p.trigger("dropdown_item_deactivate",p.$activeOption.attr("data-value"))}p.$activeOption=null;e=t(e);if(e.length){p.$activeOption=e.addClass("active");p.isOpen&&p.trigger("dropdown_item_activate",p.$activeOption.attr("data-value"));if(i||!isset(i)){o=p.$dropdown_content.height();s=p.$activeOption.outerHeight(true);i=p.$dropdown_content.scrollTop()||0;a=p.$activeOption.offset().top-p.$dropdown_content.offset().top+i;l=a;u=a-o+s;a+s>o+i?p.$dropdown_content.stop().animate({scrollTop:u},r?p.settings.scrollDuration:0):a<i&&p.$dropdown_content.stop().animate({scrollTop:l},r?p.settings.scrollDuration:0)}}},selectAll:function(){var t=this||n;if("single"!==t.settings.mode){t.$activeItems=Array.prototype.slice.apply(t.$control.children(":not(input)").addClass("active"));if(t.$activeItems.length){t.hideInput();t.close()}t.focus()}},hideInput:function(){var t=this||n;t.setTextboxValue("");t.$control_input.css({opacity:0,position:"absolute",left:t.rtl?1e4:0});t.isInputHidden=true},showInput:function(){(this||n).$control_input.css({opacity:1,position:"relative",left:0});(this||n).isInputHidden=false},focus:function(){var t=this||n;if(t.isDisabled)return t;t.ignoreFocus=true;t.$control_input[0].focus();window.setTimeout((function(){t.ignoreFocus=false;t.onFocus()}),0);return t},
/**
     * Forces the control out of focus.
     *
     * @param {Element} dest
     */
blur:function(t){(this||n).$control_input[0].blur();this.onBlur(null,t);return this||n},
/**
     * Returns a function that scores an object
     * to show how good of a match it is to the
     * provided query.
     *
     * @param {string} query
     * @param {object} options
     * @return {function}
     */
getScoreFunction:function(t){return(this||n).sifter.getScoreFunction(t,this.getSearchOptions())},getSearchOptions:function(){var t=(this||n).settings;var e=t.sortField;"string"===typeof e&&(e=[{field:e}]);return{fields:t.searchField,conjunction:t.searchConjunction,sort:e,nesting:t.nesting,filter:t.filter,respect_word_boundaries:t.respect_word_boundaries}},
/**
     * Searches through available options and returns
     * a sorted array of matches.
     *
     * Returns an object containing:
     *
     *   - query {string}
     *   - tokens {array}
     *   - total {int}
     *   - items {array}
     *
     * @param {string} query
     * @returns {object}
     */
search:function(e){var i,r,o;var s=this||n;var a=s.settings;var l=this.getSearchOptions();if(a.score){o=s.settings.score.apply(this||n,[e]);if("function"!==typeof o)throw new Error('Selectize "score" setting must be a function that returns a function')}if(e!==s.lastQuery){a.normalize&&(e=e.normalize("NFD").replace(/[\u0300-\u036f]/g,""));s.lastQuery=e;r=s.sifter.search(e,t.extend(l,{score:o}));s.currentResults=r}else r=t.extend(true,{},s.currentResults);if(a.hideSelected)for(i=r.items.length-1;i>=0;i--)-1!==s.items.indexOf(hash_key(r.items[i].id))&&r.items.splice(i,1);return r},
/**
     * Refreshes the list of available options shown
     * in the autocomplete dropdown menu.
     *
     * @param {boolean} triggerDropdown
     */
refreshOptions:function(e){var i,r,o,s,a,l,u,p,d,c,f,h,g;var v,m,y;"undefined"===typeof e&&(e=true);var w=this||n;var O=w.$control_input.val().trim();var $=w.search(O);var b=w.$dropdown_content;var C=w.$activeOption&&hash_key(w.$activeOption.attr("data-value"));s=$.items.length;"number"===typeof w.settings.maxOptions&&(s=Math.min(s,w.settings.maxOptions));a={};l=[];for(i=0;i<s;i++){u=w.options[$.items[i].id];p=w.render("option",u);d=u[w.settings.optgroupField]||"";c=Array.isArray(d)?d:[d];for(r=0,o=c&&c.length;r<o;r++){d=c[r];if(!w.optgroups.hasOwnProperty(d)&&"function"===typeof w.settings.optionGroupRegister){var x;(x=w.settings.optionGroupRegister.apply(w,[d]))&&w.registerOptionGroup(x)}w.optgroups.hasOwnProperty(d)||(d="");if(!a.hasOwnProperty(d)){a[d]=document.createDocumentFragment();l.push(d)}a[d].appendChild(p)}}(this||n).settings.lockOptgroupOrder&&l.sort((function(t,e){var n=w.optgroups[t]&&w.optgroups[t].$order||0;var i=w.optgroups[e]&&w.optgroups[e].$order||0;return n-i}));f=document.createDocumentFragment();for(i=0,s=l.length;i<s;i++){d=l[i];if(w.optgroups.hasOwnProperty(d)&&a[d].childNodes.length){h=document.createDocumentFragment();h.appendChild(w.render("optgroup_header",w.optgroups[d]));h.appendChild(a[d]);f.appendChild(w.render("optgroup",t.extend({},w.optgroups[d],{html:domToString(h),dom:h})))}else f.appendChild(a[d])}b.html(f);if(w.settings.highlight){b.removeHighlight();if($.query.length&&$.tokens.length)for(i=0,s=$.tokens.length;i<s;i++)highlight(b,$.tokens[i].regex)}if(!w.settings.hideSelected){w.$dropdown.find(".selected").removeClass("selected");for(i=0,s=w.items.length;i<s;i++)w.getOption(w.items[i]).addClass("selected")}"auto"!==w.settings.dropdownSize.sizeType&&w.isOpen&&w.setupDropdownHeight();g=w.canCreate(O);if(g&&w.settings.showAddOptionOnCreate){b.prepend(w.render("option_create",{input:O}));y=t(b[0].childNodes[0])}w.hasOptions=$.items.length>0||g&&w.settings.showAddOptionOnCreate||w.settings.setFirstOptionActive;if(w.hasOptions){if($.items.length>0){m=C&&w.getOption(C);""!==$.query&&w.settings.setFirstOptionActive?v=b.find("[data-selectable]:first"):""!==$.query&&m&&m.length?v=m:"single"===w.settings.mode&&w.items.length&&(v=w.getOption(w.items[0]));v&&v.length||(v=y&&!w.settings.addPrecedence?w.getAdjacentOption(y,1):b.find("[data-selectable]:first"))}else v=y;w.setActiveOption(v);e&&!w.isOpen&&w.open()}else{w.setActiveOption(null);e&&w.isOpen&&w.close()}},
/**
     * Adds an available option. If it already exists,
     * nothing will happen. Note: this does not refresh
     * the options list dropdown (use `refreshOptions`
     * for that).
     *
     * Usage:
     *
     *   this.addOption(data)
     *
     * @param {object|array} data
     */
addOption:function(t){var e,i,r,o=this||n;if(Array.isArray(t))for(e=0,i=t.length;e<i;e++)o.addOption(t[e]);else if(r=o.registerOption(t)){o.userOptions[r]=true;o.lastQuery=null;o.trigger("option_add",r,t)}},
/**
     * Registers an option to the pool of options.
     *
     * @param {object} data
     * @return {boolean|string}
     */
registerOption:function(t){var e=hash_key(t[(this||n).settings.valueField]);if("undefined"===typeof e||null===e||(this||n).options.hasOwnProperty(e))return false;t.$order=t.$order||++(this||n).order;(this||n).options[e]=t;return e},
/**
     * Registers an option group to the pool of option groups.
     *
     * @param {object} data
     * @return {boolean|string}
     */
registerOptionGroup:function(t){var e=hash_key(t[(this||n).settings.optgroupValueField]);if(!e)return false;t.$order=t.$order||++(this||n).order;(this||n).optgroups[e]=t;return e},
/**
     * Registers a new optgroup for options
     * to be bucketed into.
     *
     * @param {string} id
     * @param {object} data
     */
addOptionGroup:function(t,e){e[(this||n).settings.optgroupValueField]=t;(t=this.registerOptionGroup(e))&&this.trigger("optgroup_add",t,e)},
/**
     * Removes an existing option group.
     *
     * @param {string} id
     */
removeOptionGroup:function(t){if((this||n).optgroups.hasOwnProperty(t)){delete(this||n).optgroups[t];(this||n).renderCache={};this.trigger("optgroup_remove",t)}},clearOptionGroups:function(){(this||n).optgroups={};(this||n).renderCache={};this.trigger("optgroup_clear")},
/**
     * Updates an option available for selection. If
     * it is visible in the selected items or options
     * dropdown, it will be re-rendered automatically.
     *
     * @param {string} value
     * @param {object} data
     */
updateOption:function(e,i){var r=this||n;var o,s;var a,l,u,p,d;e=hash_key(e);a=hash_key(i[r.settings.valueField]);if(null!==e&&r.options.hasOwnProperty(e)){if("string"!==typeof a)throw new Error("Value must be set in option data");d=r.options[e].$order;if(a!==e){delete r.options[e];l=r.items.indexOf(e);-1!==l&&r.items.splice(l,1,a)}i.$order=i.$order||d;r.options[a]=i;u=r.renderCache.item;p=r.renderCache.option;if(u){delete u[e];delete u[a]}if(p){delete p[e];delete p[a]}if(-1!==r.items.indexOf(a)){o=r.getItem(e);s=t(r.render("item",i));o.hasClass("active")&&s.addClass("active");o.replaceWith(s)}r.lastQuery=null;r.isOpen&&r.refreshOptions(false)}},
/**
     * Removes a single option.
     *
     * @param {string} value
     * @param {boolean} silent
     */
removeOption:function(t,e){var i=this||n;t=hash_key(t);var r=i.renderCache.item;var o=i.renderCache.option;r&&delete r[t];o&&delete o[t];delete i.userOptions[t];delete i.options[t];i.lastQuery=null;i.trigger("option_remove",t);i.removeItem(t,e)},
/**
     * Clears all options, including all selected items
     *
     * @param {boolean} silent
     */
clearOptions:function(e){var i=this||n;i.loadedSearches={};i.userOptions={};i.renderCache={};var r=i.options;t.each(i.options,(function(t,e){-1==i.items.indexOf(t)&&delete r[t]}));i.options=i.sifter.items=r;i.lastQuery=null;i.trigger("option_clear");i.clear(e)},
/**
     * Returns the jQuery element of the option
     * matching the given value.
     *
     * @param {string} value
     * @returns {object}
     */
getOption:function(t){return this.getElementWithValue(t,(this||n).$dropdown_content.find("[data-selectable]"))},getFirstOption:function(){var e=(this||n).$dropdown.find("[data-selectable]");return e.length>0?e.eq(0):t()},
/**
     * Returns the jQuery element of the next or
     * previous selectable option.
     *
     * @param {object} $option
     * @param {int} direction  can be 1 for next or -1 for previous
     * @return {object}
     */
getAdjacentOption:function(e,i){var r=(this||n).$dropdown.find("[data-selectable]");var o=r.index(e)+i;return o>=0&&o<r.length?r.eq(o):t()},
/**
     * Finds the first element with a "data-value" attribute
     * that matches the given value.
     *
     * @param {mixed} value
     * @param {object} $els
     * @return {object}
     */
getElementWithValue:function(e,n){e=hash_key(e);if("undefined"!==typeof e&&null!==e)for(var i=0,r=n.length;i<r;i++)if(n[i].getAttribute("data-value")===e)return t(n[i]);return t()},
/**
     * Finds the first element with a "textContent" property
     * that matches the given textContent value.
     *
     * @param {mixed} textContent
     * @param {boolean} ignoreCase
     * @param {object} $els
     * @return {object}
     */
getElementWithTextContent:function(e,n,i){e=hash_key(e);if("undefined"!==typeof e&&null!==e)for(var r=0,o=i.length;r<o;r++){var s=i[r].textContent;if(true==n){s=null!==s?s.toLowerCase():null;e=e.toLowerCase()}if(s===e)return t(i[r])}return t()},
/**
     * Returns the jQuery element of the item
     * matching the given value.
     *
     * @param {string} value
     * @returns {object}
     */
getItem:function(t){return this.getElementWithValue(t,(this||n).$control.children())},
/**
     * Returns the jQuery element of the item
     * matching the given textContent.
     *
     * @param {string} value
     * @param {boolean} ignoreCase
     * @returns {object}
     */
getFirstItemMatchedByTextContent:function(t,e){e=null!==e&&true===e;return this.getElementWithTextContent(t,e,(this||n).$dropdown_content.find("[data-selectable]"))},
/**
     * "Selects" multiple items at once. Adds them to the list
     * at the current caret position.
     *
     * @param {string} values
     * @param {boolean} silent
     */
addItems:function(t,e){(this||n).buffer=document.createDocumentFragment();var i=(this||n).$control[0].childNodes;for(var r=0;r<i.length;r++)(this||n).buffer.appendChild(i[r]);var o=Array.isArray(t)?t:[t];r=0;for(var s=o.length;r<s;r++){(this||n).isPending=r<s-1;this.addItem(o[r],e)}var a=(this||n).$control[0];a.insertBefore((this||n).buffer,a.firstChild);(this||n).buffer=null},
/**
     * "Selects" an item. Adds it to the list
     * at the current caret position.
     *
     * @param {string} value
     * @param {boolean} silent
     */
addItem:function(e,i){var r=i?[]:["change"];debounce_events(this||n,r,(function(){var r,o,s;var a=this||n;var l=a.settings.mode;var u,p;e=hash_key(e);if(-1===a.items.indexOf(e)){if(a.options.hasOwnProperty(e)){"single"===l&&a.clear(i);if("multi"!==l||!a.isFull()){r=t(a.render("item",a.options[e]));p=a.isFull();a.items.splice(a.caretPos,0,e);a.insertAtCaret(r);(!a.isPending||!p&&a.isFull())&&a.refreshState();if(a.isSetup){s=a.$dropdown_content.find("[data-selectable]");if(!a.isPending){o=a.getOption(e);u=a.getAdjacentOption(o,1).attr("data-value");a.refreshOptions(a.isFocused&&"single"!==l);u&&a.setActiveOption(a.getOption(u))}!s.length||a.isFull()?a.close():a.isPending||a.positionDropdown();a.updatePlaceholder();a.trigger("item_add",e,r);a.isPending||a.updateOriginalInput({silent:i})}}}}else"single"===l&&a.close()}))},
/**
     * Removes the selected item matching
     * the provided value.
     *
     * @param {string} value
     */
removeItem:function(e,i){var r=this||n;var o,s,a;o=e instanceof t?e:r.getItem(e);e=hash_key(o.attr("data-value"));s=r.items.indexOf(e);if(-1!==s){r.trigger("item_before_remove",e,o);o.remove();if(o.hasClass("active")){o.removeClass("active");a=r.$activeItems.indexOf(o[0]);r.$activeItems.splice(a,1);o.removeClass("active")}r.items.splice(s,1);r.lastQuery=null;!r.settings.persist&&r.userOptions.hasOwnProperty(e)&&r.removeOption(e,i);s<r.caretPos&&r.setCaret(r.caretPos-1);r.refreshState();r.updatePlaceholder();r.updateOriginalInput({silent:i});r.positionDropdown();r.trigger("item_remove",e,o)}},
/**
     * Invokes the `create` method provided in the
     * selectize options that should provide the data
     * for the new item, given the user input.
     *
     * Once this completes, it will be added
     * to the item list.
     *
     * @param {string} value
     * @param {boolean} [triggerDropdown]
     * @param {function} [callback]
     * @return {boolean}
     */
createItem:function(t,e){var i=this||n;var r=i.caretPos;t=t||(i.$control_input.val()||"").trim();var o=arguments[arguments.length-1];"function"!==typeof o&&(o=function(){});"boolean"!==typeof e&&(e=true);if(!i.canCreate(t)){o();return false}i.lock();var s="function"===typeof i.settings.create?(this||n).settings.create:function(t){var e={};e[i.settings.labelField]=t;var r=t;if(i.settings.formatValueToKey&&"function"===typeof i.settings.formatValueToKey){r=i.settings.formatValueToKey.apply(this||n,[r]);if(null===r||"undefined"===typeof r||"object"===typeof r||"function"===typeof r)throw new Error('Selectize "formatValueToKey" setting must be a function that returns a value other than object or function.')}e[i.settings.valueField]=r;return e};var a=once((function(t){i.unlock();if(!t||"object"!==typeof t)return o();var n=hash_key(t[i.settings.valueField]);if("string"!==typeof n)return o();i.setTextboxValue("");i.addOption(t);i.setCaret(r);i.addItem(n);i.refreshOptions(e&&"single"!==i.settings.mode);o(t)}));var l=s.apply(this||n,[t,a]);"undefined"!==typeof l&&a(l);return true},refreshItems:function(t){(this||n).lastQuery=null;(this||n).isSetup&&this.addItem((this||n).items,t);this.refreshState();this.updateOriginalInput({silent:t})},refreshState:function(){this.refreshValidityState();this.refreshClasses()},refreshValidityState:function(){if(!(this||n).isRequired)return false;var t=!(this||n).items.length;(this||n).isInvalid=t;(this||n).$control_input.prop("required",t);(this||n).$input.prop("required",!t)},refreshClasses:function(){var e=this||n;var i=e.isFull();var r=e.isLocked;e.$wrapper.toggleClass("rtl",e.rtl);e.$control.toggleClass("focus",e.isFocused).toggleClass("disabled",e.isDisabled).toggleClass("required",e.isRequired).toggleClass("invalid",e.isInvalid).toggleClass("locked",r).toggleClass("full",i).toggleClass("not-full",!i).toggleClass("input-active",e.isFocused&&!e.isInputHidden).toggleClass("dropdown-active",e.isOpen).toggleClass("has-options",!t.isEmptyObject(e.options)).toggleClass("has-items",e.items.length>0);e.$control_input.data("grow",!i&&!r)},
/**
     * Determines whether or not more items can be added
     * to the control without exceeding the user-defined maximum.
     *
     * @returns {boolean}
     */
isFull:function(){return null!==(this||n).settings.maxItems&&(this||n).items.length>=(this||n).settings.maxItems},updateOriginalInput:function(t){var e,i,r,o,s,a,l=this||n;t=t||{};if(l.tagType===C){o=l.$input.find("option");e=[];i=[];r=[];a=[];o.get().forEach((function(t){e.push(t.value)}));l.items.forEach((function(t){s=l.options[t][l.settings.labelField]||"";a.push(t);-1==e.indexOf(t)&&i.push('<option value="'+escape_html(t)+'" selected="selected">'+escape_html(s)+"</option>")}));r=e.filter((function(t){return a.indexOf(t)<0})).map((function(t){return'option[value="'+t+'"]'}));e.length-r.length+i.length!==0||l.$input.attr("multiple")||i.push('<option value="" selected="selected"></option>');l.$input.find(r.join(", ")).remove();l.$input.append(i.join(""))}else{l.$input.val(l.getValue());l.$input.attr("value",l.$input.val())}l.isSetup&&(t.silent||l.trigger("change",l.$input.val()))},updatePlaceholder:function(){if((this||n).settings.placeholder){var t=(this||n).$control_input;(this||n).items.length?t.removeAttr("placeholder"):t.attr("placeholder",(this||n).settings.placeholder);t.triggerHandler("update",{force:true})}},open:function(){var t=this||n;if(!(t.isLocked||t.isOpen||"multi"===t.settings.mode&&t.isFull())){t.focus();t.isOpen=true;t.refreshState();t.$dropdown.css({visibility:"hidden",display:"block"});t.setupDropdownHeight();t.positionDropdown();t.$dropdown.css({visibility:"visible"});t.trigger("dropdown_open",t.$dropdown)}},close:function(){var t=this||n;var e=t.isOpen;if("single"===t.settings.mode&&t.items.length){t.hideInput();t.isBlurring&&t.$control_input[0].blur()}t.isOpen=false;t.$dropdown.hide();t.setActiveOption(null);t.refreshState();e&&t.trigger("dropdown_close",t.$dropdown)},positionDropdown:function(){var t=(this||n).$control;var e="body"===(this||n).settings.dropdownParent?t.offset():t.position();e.top+=t.outerHeight(true);var i=t[0].getBoundingClientRect().width;(this||n).settings.minWidth&&(this||n).settings.minWidth>i&&(i=(this||n).settings.minWidth);(this||n).$dropdown.css({width:i,top:e.top,left:e.left})},setupDropdownHeight:function(){if("object"===typeof(this||n).settings.dropdownSize&&"auto"!==(this||n).settings.dropdownSize.sizeType){var e=(this||n).settings.dropdownSize.sizeValue;if("numberItems"===(this||n).settings.dropdownSize.sizeType){var i=(this||n).$dropdown_content.find("*").not(".optgroup, .highlight").not((this||n).settings.ignoreOnDropwdownHeight);var r=0;var o=0;var s=0;var a=0;for(var l=0;l<e;l++){var u=t(i[l]);if(0===u.length)break;r+=u.outerHeight(true);if("undefined"==typeof u.data("selectable")){if(u.hasClass("optgroup-header")){var p=window.getComputedStyle(u.parent()[0],":before");if(p){o=p.marginTop?Number(p.marginTop.replace(/\W*(\w)\w*/g,"$1")):0;s=p.marginBottom?Number(p.marginBottom.replace(/\W*(\w)\w*/g,"$1")):0;a=p.borderTopWidth?Number(p.borderTopWidth.replace(/\W*(\w)\w*/g,"$1")):0}}e++}}var d=(this||n).$dropdown_content.css("padding-top")?Number((this||n).$dropdown_content.css("padding-top").replace(/\W*(\w)\w*/g,"$1")):0;var c=(this||n).$dropdown_content.css("padding-bottom")?Number((this||n).$dropdown_content.css("padding-bottom").replace(/\W*(\w)\w*/g,"$1")):0;e=r+d+c+o+s+a+"px"}else if("fixedHeight"!==(this||n).settings.dropdownSize.sizeType){console.warn('Selectize.js - Value of "sizeType" must be "fixedHeight" or "numberItems');return}(this||n).$dropdown_content.css({height:e,maxHeight:"none"})}},
/**
     * Resets / clears all selected items
     * from the control.
     *
     * @param {boolean} silent
     */
clear:function(t){var e=this||n;if(e.items.length){e.$control.children(":not(input)").remove();e.items=[];e.lastQuery=null;e.setCaret(0);e.setActiveItem(null);e.updatePlaceholder();e.updateOriginalInput({silent:t});e.refreshState();e.showInput();e.trigger("clear")}},
/**
     * A helper method for inserting an element
     * at the current caret position.
     *
     * @param {object} $el
     */
insertAtCaret:function(t){var e=Math.min((this||n).caretPos,(this||n).items.length);var i=t[0];
/**
       * @type {HTMLElement}
       **/var r=(this||n).buffer||(this||n).$control[0];0===e?r.insertBefore(i,r.firstChild):r.insertBefore(i,r.childNodes[e]);this.setCaret(e+1)},
/**
     * Removes the current selected item(s).
     *
     * @param {object} e (optional)
     * @returns {boolean}
     */
deleteSelection:function(e){var i,r,o,s,a,l,u,p,d;var c=this||n;o=e&&e.keyCode===m?-1:1;s=getInputSelection(c.$control_input[0]);c.$activeOption&&!c.settings.hideSelected&&(u="string"===typeof c.settings.deselectBehavior&&"top"===c.settings.deselectBehavior?c.getFirstOption().attr("data-value"):c.getAdjacentOption(c.$activeOption,-1).attr("data-value"));a=[];if(c.$activeItems.length){d=c.$control.children(".active:"+(o>0?"last":"first"));l=c.$control.children(":not(input)").index(d);o>0&&l++;for(i=0,r=c.$activeItems.length;i<r;i++)a.push(t(c.$activeItems[i]).attr("data-value"));if(e){e.preventDefault();e.stopPropagation()}}else(c.isFocused||"single"===c.settings.mode)&&c.items.length&&(o<0&&0===s.start&&0===s.length?a.push(c.items[c.caretPos-1]):o>0&&s.start===c.$control_input.val().length&&a.push(c.items[c.caretPos]));if(!a.length||"function"===typeof c.settings.onDelete&&false===c.settings.onDelete.apply(c,[a]))return false;"undefined"!==typeof l&&c.setCaret(l);while(a.length)c.removeItem(a.pop());c.showInput();c.positionDropdown();c.refreshOptions(true);if(u){p=c.getOption(u);p.length&&c.setActiveOption(p)}return true},
/**
     * Selects the previous / next item (depending
     * on the `direction` argument).
     *
     * > 0 - right
     * < 0 - left
     *
     * @param {int} direction
     * @param {object} e (optional)
     */
advanceSelection:function(t,e){var i,r,o,s,a,l;var u=this||n;if(0!==t){u.rtl&&(t*=-1);i=t>0?"last":"first";r=getInputSelection(u.$control_input[0]);if(u.isFocused&&!u.isInputHidden){s=u.$control_input.val().length;a=t<0?0===r.start&&0===r.length:r.start===s;a&&!s&&u.advanceCaret(t,e)}else{l=u.$control.children(".active:"+i);if(l.length){o=u.$control.children(":not(input)").index(l);u.setActiveItem(null);u.setCaret(t>0?o+1:o)}}}},
/**
     * Moves the caret left / right.
     *
     * @param {int} direction
     * @param {object} e (optional)
     */
advanceCaret:function(t,e){var i,r,o=this||n;if(0!==t){i=t>0?"next":"prev";if(o.isShiftDown){r=o.$control_input[i]();if(r.length){o.hideInput();o.setActiveItem(r);e&&e.preventDefault()}}else o.setCaret(o.caretPos+t)}},
/**
     * Moves the caret to the specified index.
     *
     * @param {int} i
     */
setCaret:function(e){var i=this||n;e="single"===i.settings.mode?i.items.length:Math.max(0,Math.min(i.items.length,e));if(!i.isPending){var r,o,s,a;s=i.$control.children(":not(input)");for(r=0,o=s.length;r<o;r++){a=t(s[r]).detach();r<e?i.$control_input.before(a):i.$control.append(a)}}i.caretPos=e},lock:function(){this.close();(this||n).isLocked=true;this.refreshState()},unlock:function(){(this||n).isLocked=false;this.refreshState()},disable:function(){var t=this||n;t.$input.prop("disabled",true);t.$control_input.prop("disabled",true).prop("tabindex",-1);t.isDisabled=true;t.lock()},enable:function(){var t=this||n;t.$input.prop("disabled",false);t.$control_input.prop("disabled",false).prop("tabindex",t.tabIndex);t.isDisabled=false;t.unlock()},destroy:function(){var e=this||n;var i=e.eventNS;var r=e.revertSettings;e.trigger("destroy");e.off();e.$wrapper.remove();e.$dropdown.remove();e.$input.html("").append(r.$children).removeAttr("tabindex").removeClass("selectized").attr({tabindex:r.tabindex}).show();e.$control_input.removeData("grow");e.$input.removeData("selectize");if(0==--Selectize.count&&Selectize.$testInput){Selectize.$testInput.remove();Selectize.$testInput=void 0}t(window).off(i);t(document).off(i);t(document.body).off(i);delete e.$input[0].selectize},
/**
     * A helper method for rendering "item" and
     * "option" templates, given the data.
     *
     * @param {string} templateName
     * @param {object} data
     * @returns {string}
     */
render:function(e,i){var r,o;var s="";var a=false;var l=this||n;if("option"===e||"item"===e){r=hash_key(i[l.settings.valueField]);a=!!r}if(a){isset(l.renderCache[e])||(l.renderCache[e]={});if(l.renderCache[e].hasOwnProperty(r))return l.renderCache[e][r]}s=t(l.settings.render[e].apply(this||n,[i,escape_html]));if("option"===e||"option_create"===e)i[l.settings.disabledField]||s.attr("data-selectable","");else if("optgroup"===e){o=i[l.settings.optgroupValueField]||"";s.attr("data-group",o);i[l.settings.disabledField]&&s.attr("data-disabled","")}"option"!==e&&"item"!==e||s.attr("data-value",r||"");a&&(l.renderCache[e][r]=s[0]);return s[0]},
/**
     * Clears the render cache for a template. If
     * no template is given, clears all render
     * caches.
     *
     * @param {string} templateName
     */
clearCache:function(t){var e=this||n;"undefined"===typeof t?e.renderCache={}:delete e.renderCache[t]},
/**
     * Determines whether or not to display the
     * create item prompt, given a user input.
     *
     * @param {string} input
     * @return {boolean}
     */
canCreate:function(t){var e=this||n;if(!e.settings.create)return false;var i=e.settings.createFilter;return t.length&&("function"!==typeof i||i.apply(e,[t]))&&("string"!==typeof i||new RegExp(i).test(t))&&(!(i instanceof RegExp)||i.test(t))}});Selectize.count=0;Selectize.defaults={options:[],optgroups:[],plugins:[],delimiter:",",splitOn:null,persist:true,diacritics:true,create:false,showAddOptionOnCreate:true,createOnBlur:false,createFilter:null,highlight:true,openOnFocus:true,maxOptions:1e3,maxItems:null,hideSelected:null,addPrecedence:false,selectOnTab:true,preload:false,allowEmptyOption:false,showEmptyOptionInDropdown:false,emptyOptionLabel:"--",setFirstOptionActive:false,closeAfterSelect:false,closeDropdownThreshold:250,scrollDuration:60,deselectBehavior:"previous",loadThrottle:300,loadingClass:"loading",dataAttr:"data-data",optgroupField:"optgroup",valueField:"value",labelField:"text",disabledField:"disabled",optgroupLabelField:"label",optgroupValueField:"value",lockOptgroupOrder:false,sortField:"$order",searchField:["text"],searchConjunction:"and",respect_word_boundaries:true,mode:null,wrapperClass:"",inputClass:"",dropdownClass:"",dropdownContentClass:"",dropdownParent:null,copyClassesToDropdown:true,dropdownSize:{sizeType:"auto",sizeValue:"auto"},normalize:false,ignoreOnDropwdownHeight:"img, i",search:true,render:{}};t.fn.selectize=function(e){var i=t.fn.selectize.defaults;var r=t.extend({},i,e);var o=r.dataAttr;var s=r.labelField;var a=r.valueField;var l=r.disabledField;var u=r.optgroupField;var p=r.optgroupLabelField;var d=r.optgroupValueField;
/**
     * Initializes selectize from a <input type="text"> element.
     *
     * @param {JQuery} $input
     * @param {Object} settings_element
     */var init_textbox=function(t,e){var n,i,l,u;var p=t.attr(o);if(p){e.options=JSON.parse(p);for(n=0,i=e.options.length;n<i;n++)e.items.push(e.options[n][a])}else{var d=(t.val()||"").trim();if(!r.allowEmptyOption&&!d.length)return;l=d.split(r.delimiter);for(n=0,i=l.length;n<i;n++){u={};u[s]=l[n];u[a]=l[n];e.options.push(u)}e.items=l}};
/**
     * Initializes selectize from a <select> element.
     *
     * @param {object} $input
     * @param {object} settings_element
     */var init_select=function(e,n){var i,c,f,h;var g=n.options;var v={};var readData=function(t){var e=o&&t.attr(o);var n=t.data();var i={};"string"===typeof e&&e.length&&(isJSON(e)?Object.assign(i,JSON.parse(e)):i[e]=e);Object.assign(i,n);return i||null};var addOption=function(e,i){e=t(e);var o=hash_key(e.val());if(o||r.allowEmptyOption)if(v.hasOwnProperty(o)){if(i){var p=v[o][u];p?Array.isArray(p)?p.push(i):v[o][u]=[p,i]:v[o][u]=i}}else{var d=readData(e)||{};d[s]=d[s]||e.text();d[a]=d[a]||o;d[l]=d[l]||e.prop("disabled");d[u]=d[u]||i;d.styles=e.attr("style")||"";d.classes=e.attr("class")||"";v[o]=d;g.push(d);e.is(":selected")&&n.items.push(o)}};var addGroup=function(e){var i,r,o,s,a;e=t(e);o=e.attr("label");if(o){s=readData(e)||{};s[p]=o;s[d]=o;s[l]=e.prop("disabled");n.optgroups.push(s)}a=t("option",e);for(i=0,r=a.length;i<r;i++)addOption(a[i],o)};n.maxItems=e.attr("multiple")?null:1;h=e.children();for(i=0,c=h.length;i<c;i++){f=h[i].tagName.toLowerCase();"optgroup"===f?addGroup(h[i]):"option"===f&&addOption(h[i])}};return this.each((function(){if(!(this||n).selectize){var o;var s=t(this||n);var a=(this||n).tagName.toLowerCase();var l=s.attr("placeholder")||s.attr("data-placeholder");l||r.allowEmptyOption||(l=s.children('option[value=""]').text());if(r.allowEmptyOption&&r.showEmptyOptionInDropdown&&!s.children('option[value=""]').length){var u=s.html();var p=escape_html(r.emptyOptionLabel||"--");s.html('<option value="">'+p+"</option>"+u)}var d={placeholder:l,options:[],optgroups:[],items:[]};"select"===a?init_select(s,d):init_textbox(s,d);o=new Selectize(s,t.extend(true,{},i,d,e));o.settings_user=e}}))};t.fn.selectize.defaults=Selectize.defaults;t.fn.selectize.support={validity:_};Selectize.define("auto_position",(function(){var t=this||n;const e={top:"top",bottom:"bottom"};t.positionDropdown=function(){return function(){const t=(this||n).$control;const i="body"===(this||n).settings.dropdownParent?t.offset():t.position();i.top+=t.outerHeight(true);const r=(this||n).$dropdown.prop("scrollHeight")+5;const o=(this||n).$control.get(0).getBoundingClientRect().top;const s=(this||n).$wrapper.height();const a=o+r+s>window.innerHeight?e.top:e.bottom;const l={width:t.outerWidth(),left:i.left};if(a===e.top){const e={bottom:i.top,top:"unset"};if("body"===(this||n).settings.dropdownParent){e.top=i.top-(this||n).$dropdown.outerHeight(true)-t.outerHeight(true);e.bottom="unset"}Object.assign(l,e);(this||n).$dropdown.addClass("selectize-position-top");(this||n).$control.addClass("selectize-position-top")}else{Object.assign(l,{top:i.top,bottom:"unset"});(this||n).$dropdown.removeClass("selectize-position-top");(this||n).$control.removeClass("selectize-position-top")}(this||n).$dropdown.css(l)}}()}));Selectize.define("auto_select_on_type",(function(t){var e=this||n;e.onBlur=function(){var t=e.onBlur;return function(i){var r=e.getFirstItemMatchedByTextContent(e.lastValue,true);"undefined"!==typeof r.attr("data-value")&&e.getValue()!==r.attr("data-value")&&e.setValue(r.attr("data-value"));return t.apply(this||n,arguments)}}()}));Selectize.define("autofill_disable",(function(t){var e=this||n;e.setup=function(){var t=e.setup;return function(){t.apply(e,arguments);e.$control_input.attr({autocomplete:"new-password",autofill:"no"})}}()}));Selectize.define("clear_button",(function(e){var i=this||n;e=t.extend({title:"Clear",className:"clear",label:"×",html:function(t){return'<a class="'+t.className+'" title="'+t.title+'"> '+t.label+"</a>"}},e);i.setup=function(){var n=i.setup;return function(){n.apply(i,arguments);i.$button_clear=t(e.html(e));"single"===i.settings.mode&&i.$wrapper.addClass("single");i.$wrapper.append(i.$button_clear);""!==i.getValue()&&0!==i.getValue().length||i.$wrapper.find("."+e.className).css("display","none");i.on("change",(function(){""===i.getValue()||0===i.getValue().length?i.$wrapper.find("."+e.className).css("display","none"):i.$wrapper.find("."+e.className).css("display","")}));i.$wrapper.on("click","."+e.className,(function(t){t.preventDefault();t.stopImmediatePropagation();t.stopPropagation();if(!i.isLocked){i.clear();i.$wrapper.find("."+e.className).css("display","none")}}))}}()}));Selectize.define("drag_drop",(function(e){if(!t.fn.sortable)throw new Error('The "drag_drop" plugin requires jQuery UI "sortable".');if("multi"===(this||n).settings.mode){var i=this||n;i.lock=function(){var t=i.lock;return function(){var e=i.$control.data("sortable");e&&e.disable();return t.apply(i,arguments)}}();i.unlock=function(){var t=i.unlock;return function(){var e=i.$control.data("sortable");e&&e.enable();return t.apply(i,arguments)}}();i.setup=function(){var e=i.setup;return function(){e.apply(this||n,arguments);var r=i.$control.sortable({items:"[data-value]",forcePlaceholderSize:true,disabled:i.isLocked,start:function(t,e){e.placeholder.css("width",e.helper.css("width"));r.addClass("dragging")},stop:function(){r.removeClass("dragging");var e=i.$activeItems?i.$activeItems.slice():null;var o=[];r.children("[data-value]").each((function(){o.push(t(this||n).attr("data-value"))}));i.isFocused=false;i.setValue(o);i.isFocused=true;i.setActiveItem(e);i.positionDropdown()}})}}()}}));Selectize.define("dropdown_header",(function(e){var i=this||n;e=t.extend({title:"Untitled",headerClass:"selectize-dropdown-header",titleRowClass:"selectize-dropdown-header-title",labelClass:"selectize-dropdown-header-label",closeClass:"selectize-dropdown-header-close",html:function(t){return'<div class="'+t.headerClass+'"><div class="'+t.titleRowClass+'"><span class="'+t.labelClass+'">'+t.title+'</span><a href="javascript:void(0)" class="'+t.closeClass+'">&#xd7;</a></div></div>'}},e);i.setup=function(){var n=i.setup;return function(){n.apply(i,arguments);i.$dropdown_header=t(e.html(e));i.$dropdown.prepend(i.$dropdown_header);i.$dropdown_header.find("."+e.closeClass).on("click",(function(){i.close()}))}}()}));Selectize.define("optgroup_columns",(function(e){var i=this||n;e=t.extend({equalizeWidth:true,equalizeHeight:true},e);(this||n).getAdjacentOption=function(e,n){var i=e.closest("[data-group]").find("[data-selectable]");var r=i.index(e)+n;return r>=0&&r<i.length?i.eq(r):t()};(this||n).onKeyDown=function(){var t=i.onKeyDown;return function(e){var r,o,s,a;if(!(this||n).isOpen||e.keyCode!==d&&e.keyCode!==h)return t.apply(this||n,arguments);i.ignoreHover=true;a=(this||n).$activeOption.closest("[data-group]");r=a.find("[data-selectable]").index((this||n).$activeOption);a=e.keyCode===d?a.prev("[data-group]"):a.next("[data-group]");s=a.find("[data-selectable]");o=s.eq(Math.min(s.length-1,r));o.length&&this.setActiveOption(o)}}();var getScrollbarWidth=function(){var t;var e=getScrollbarWidth.width;var n=document;if("undefined"===typeof e){t=n.createElement("div");t.innerHTML='<div style="width:50px;height:50px;position:absolute;left:-50px;top:-50px;overflow:auto;"><div style="width:1px;height:100px;"></div></div>';t=t.firstChild;n.body.appendChild(t);e=getScrollbarWidth.width=t.offsetWidth-t.clientWidth;n.body.removeChild(t)}return e};var equalizeSizes=function(){var n,r,o,s,a,l,u;u=t("[data-group]",i.$dropdown_content);r=u.length;if(r&&i.$dropdown_content.width()){if(e.equalizeHeight){o=0;for(n=0;n<r;n++)o=Math.max(o,u.eq(n).height());u.css({height:o})}if(e.equalizeWidth){l=i.$dropdown_content.innerWidth()-getScrollbarWidth();s=Math.round(l/r);u.css({width:s});if(r>1){a=l-s*(r-1);u.eq(r-1).css({width:a})}}}};if(e.equalizeHeight||e.equalizeWidth){I.after(this||n,"positionDropdown",equalizeSizes);I.after(this||n,"refreshOptions",equalizeSizes)}}));Selectize.define("remove_button",(function(e){if("single"!==(this||n).settings.mode){e=t.extend({label:"&#xd7;",title:"Remove",className:"remove",append:true},e);var multiClose=function(e,n){var i=e;var r='<a href="javascript:void(0)" class="'+n.className+'" tabindex="-1" title="'+escape_html(n.title)+'">'+n.label+"</a>";
/**
       * Appends an element as a child (with raw HTML).
       *
       * @param {string} html_container
       * @param {string} html_element
       * @return {string}
       */var append=function(t,e){var n=t.search(/(<\/[^>]+>\s*)$/);return t.substring(0,n)+e+t.substring(n)};e.setup=function(){var o=i.setup;return function(){if(n.append){var s=i.settings.render.item;i.settings.render.item=function(t){return append(s.apply(e,arguments),r)}}o.apply(e,arguments);e.$control.on("click","."+n.className,(function(e){e.preventDefault();if(!i.isLocked){var n=t(e.currentTarget).parent();i.setActiveItem(n);i.deleteSelection()&&i.setCaret(i.items.length);return false}}))}}()};multiClose(this||n,e)}}));Selectize.define("restore_on_backspace",(function(t){var e=this||n;t.text=t.text||function(t){return t[(this||n).settings.labelField]};(this||n).onKeyDown=function(){var i=e.onKeyDown;return function(e){var r,o;if(e.keyCode===m&&""===(this||n).$control_input.val()&&!(this||n).$activeItems.length){r=(this||n).caretPos-1;if(r>=0&&r<(this||n).items.length){o=(this||n).options[(this||n).items[r]];if(this.deleteSelection(e)){this.setTextboxValue(t.text.apply(this||n,[o]));this.refreshOptions(true)}e.preventDefault();return}}return i.apply(this||n,arguments)}}()}));Selectize.define("select_on_focus",(function(t){var e=this||n;e.on("focus",function(){var t=e.onFocus;return function(i){var r=e.getItem(e.getValue()).text();e.clear();e.setTextboxValue(r);e.$control_input.select();setTimeout((function(){e.settings.selectOnTab&&e.setActiveOption(e.getFirstItemMatchedByTextContent(r));e.settings.score=null}),0);return t.apply(this||n,arguments)}}());e.onBlur=function(){var t=e.onBlur;return function(i){""===e.getValue()&&e.lastValidValue!==e.getValue()&&e.setValue(e.lastValidValue);setTimeout((function(){e.settings.score=function(){return function(){return 1}}}),0);return t.apply(this||n,arguments)}}();e.settings.score=function(){return function(){return 1}}}));Selectize.define("tag_limit",(function(e){const i=this||n;e.tagLimit=e.tagLimit;(this||n).onBlur=function(r){const o=i.onBlur;return function(i){o.apply(this||n,i);if(!i)return;const r=(this||n).$control;const s=r.find(".item");const a=e.tagLimit;if(!(void 0===a||s.length<=a)){s.toArray().forEach((function(e,n){n<a||t(e).hide()}));r.append("<span><b>"+(s.length-a)+"</b></span>")}}}();(this||n).onFocus=function(t){const e=i.onFocus;return function(t){e.apply(this||n,t);if(!t)return;const i=(this||n).$control;const r=i.find(".item");r.show();i.find("span").remove()}}()}));return Selectize}));var r=i;export{r as default};


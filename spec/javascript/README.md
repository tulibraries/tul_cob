Testing with Jest
===

Jest is a testing framework developed by Facebook to test React applications in
a headless environment.  However, the framework is project agnostic. Jest does
not currently run in a browser.  Instead Jest runs in a dom emulator inside of
a NodeJs server.  The DOM environment is provided by [jsdom][1].

Unfortunately jsdom does not have support for [Mutation Observers][2] out of
the box, which is a requirement for running and testing [Stimulus][3]
applications. Fortunately there are [polyfills][4] that can serve as a stop-gap
until jsdom adds them.

## Initialization
Download new framework and dependencies:
```
yarn
```

## Use and Configuration
Run the test with the following command:
```
yarn test
```

To view environment settings and configurations run:
```
yarn test --debug
```

One of Jests most exalted features is that it requires no setup or
configuration.  However, this is only true if we were to create a new React
application as the setup is done by the React project generator.

There isn't too much to set up beyond listing the locations for where Jest can
find the modules to test or import, and setting the root path to test
locations.

Well, that and we'll want to add the polyfill for the MutationObserver we
mentioned earlier, as well as load JQuery into the dom and have a way to mock
the fetch method as well as ajax calls. Then we'll be all set to test all of our
JS code using Jest. For this step, Jest has a configuration called `setupFiles`
which is a list of all the files that we want to run before the tests are run:
```json
  "jest": {
    "roots": [
      "spec/javascript"
    ],
    "moduleDirectories": [
      "node_modules",
      "app/javascript",
      "app/javascript/packs"
    ],
    "setupFiles": [
      "<rootDir>/spec/javascript/setup/mutation-observer.js",
      "<rootDir>/spec/javascript/setup/jquery.js",
      "<rootDir>/spec/javascript/setup/fetch-mock.js"
    ]
  }
```

## Writing Tests

Jest's API is similar to rspecs so it should be relatively straight forward for most tests.  However there are some considerations.


### Modules
Jest seems to be designed primarily for testing of modern JS that is
encapsulated within modules.  Thus for are non module code the easiest way to
test it will be to refactor it into modules.  Then testing is done the usual
way.
```javascript
import exported from 'mymodule'

// test exported
```

However there are ways to get around this if we want to, but it's hacky.


### Testing side effecting code.
A lot of the JavaScript code that we write is side effecty (i.e. click this and something changes in the dom).  There are a couple of ways to test this but they essentially boild down to:

* Set up the dom with something to interact with:
```javascript
document.body.innerHTML = `<div id="foo">hello world</div><button id="a"></button>`
```

* Trigger the function or an event that makes your code run
```javascript
$('button#a').click()
```

* Then test for an expected outcome.

### Testing code that requires a bit of time between trigger and expectations:
Sometimes you may need to add a delay between a trigger and the expectation to give domjs time to resolve. So to do that you can wrap your expectation inside of a promise that execute a timeout.
```javascript
await  new Promise(resolve => {
  setTimeout(() => {
    const els = document.getElementsByClassName('spinner')
    expect(els.length).toEqual(0)
    resolve(true);
  }, 10);
});
```
(This procedure can be avoided if you setup and trigger before running the test)

### Testing regular pure functions
If you can avoid side effecty stuff, then you are golden.  Write your tests and expectations in the usual manner:

```javascript
describe('Math.pow(n, m)', () => {
  it('returns base m raised to power of m ', () => {
    expect(Math.pow(2, 0)).toEqual(1)
  })
});
```

[1]: https://github.com/jsdom/jsdom
[2]: https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver
[3]: https://github.com/stimulusjs/stimulus/issues/130#issuecomment-375298389
[4]: https://github.com/megawac/MutationObserver.js

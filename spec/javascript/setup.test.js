describe('jQuery setup', () => {
  test('$ is available as a global', () => {
    expect(global.$).toBeTruthy()
    expect(global.jQuery).toBeTruthy()
  });

  test('jQuery behaves the way we expect', () => {
    document.body.innerHTML = "<body><div id=foo></div></body>"

    expect($('#foo').length).toEqual(1)
  });
});

describe('MutationObserver setup', () => {
  test('MutationObserver is set', () => {
    expect(global.MutationObserver).toBeTruthy()
  })
});

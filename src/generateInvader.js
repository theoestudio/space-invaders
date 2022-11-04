// Creates the entire matrix for the arcade character
export function generateInvader () {
  const r = (min, max) => Math.floor(min + Math.random() * (1 + max - min));

  let a, b, c;

  /* eslint-disable no-return-assign */
  return [
    [a = r(0, 1), b = r(0, 1), c = r(0, 1), r(0, 1), c, b, a],
    [a = r(0, 1), b = r(0, 1), c = r(0, 1), r(0, 1), c, b, a],
    [a = r(0, 1), b = r(0, 1), c = r(0, 1), r(0, 1), c, b, a],
    [a = r(0, 1), b = r(0, 1), c = r(0, 1), r(0, 1), c, b, a],
    [a = r(0, 1), b = r(0, 1), c = r(0, 1), r(0, 1), c, b, a],
    [a = r(0, 1), b = r(0, 1), c = r(0, 1), r(0, 1), c, b, a],
    [a = r(0, 1), b = r(0, 1), c = r(0, 1), r(0, 1), c, b, a]
  ];
  /* eslint-enable no-return-assign */
} // end generateInvader()

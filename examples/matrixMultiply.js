function makeMatrix(n, seed) {
  var matrix = [];
  var i = 0;
  var j = 0;

  for (i = 0; i < n; i = i + 1) {
    for (j = 0; j < n; j = j + 1) {
      matrix.push(((i * 17 + j * 31 + seed) % 100) / 10);
    }
  }

  return matrix;
}

function makeZeroMatrix(n) {
  var matrix = [];
  var i = 0;

  for (i = 0; i < n * n; i = i + 1) {
    matrix.push(0);
  }

  return matrix;
}

function multiplyIJK(a, b, n) {
  var c = makeZeroMatrix(n);
  var i = 0;
  var j = 0;
  var k = 0;
  var iBase = 0;
  var sum = 0;

  for (i = 0; i < n; i = i + 1) {
    iBase = i * n;
    for (j = 0; j < n; j = j + 1) {
      sum = 0;
      for (k = 0; k < n; k = k + 1) {
        sum = sum + a[iBase + k] * b[k * n + j];
      }
      c[iBase + j] = sum;
    }
  }

  return c;
}

function multiplyIKJ(a, b, n) {
  var c = makeZeroMatrix(n);
  var i = 0;
  var j = 0;
  var k = 0;
  var iBase = 0;
  var kBase = 0;
  var aik = 0;

  for (i = 0; i < n; i = i + 1) {
    iBase = i * n;
    for (k = 0; k < n; k = k + 1) {
      aik = a[iBase + k];
      kBase = k * n;
      for (j = 0; j < n; j = j + 1) {
        c[iBase + j] = c[iBase + j] + aik * b[kBase + j];
      }
    }
  }

  return c;
}

function checksum(matrix, n) {
  var sum = 0;
  var i = 0;

  for (i = 0; i < n * n; i = i + 1) {
    sum = sum + matrix[i];
  }

  return sum;
}

var n = 60;
var a = makeMatrix(n, 1);
var b = makeMatrix(n, 7);

var cIJK = multiplyIJK(a, b, n);
var cIKJ = multiplyIKJ(a, b, n);

var sumIJK = checksum(cIJK, n);
var sumIKJ = checksum(cIKJ, n);

console.log("size", n);
console.log("checksum ijk", sumIJK);
console.log("checksum ikj", sumIKJ);
console.log("checksums match", sumIJK == sumIKJ);

function makeMatrix(n, seed) {
  var matrix = [];
  var i = 0;
  var j = 0;

  for (i = 0; i < n; i++) {
    for (j = 0; j < n; j++) {
      matrix.push(((i * 17 + j * 31 + seed) % 100) / 10);
    }
  }

  return matrix;
}

function makeZeroMatrix(n) {
  var matrix = [];
  var i = 0;

  for (i = 0; i < n * n; i++) {
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

  for (i = 0; i < n; i++) {
    iBase = i * n;
    for (j = 0; j < n; j++) {
      sum = 0;
      for (k = 0; k < n; k++) {
        sum += a[iBase + k] * b[k * n + j];
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

  for (i = 0; i < n; i++) {
    iBase = i * n;
    for (k = 0; k < n; k++) {
      aik = a[iBase + k];
      kBase = k * n;
      for (j = 0; j < n; j++) {
        c[iBase + j] += aik * b[kBase + j];
      }
    }
  }

  return c;
}

function checksum(matrix, n) {
  var sum = 0;
  var i = 0;

  for (i = 0; i < n * n; i++) {
    sum += matrix[i];
  }

  return sum;
}

var n = 64;
var runs = 4;
var a = makeMatrix(n, 1);
var b = makeMatrix(n, 7);
var run = 0;
var cIJK = [];
var cIKJ = [];
var sumIJK = 0;
var sumIKJ = 0;

for (run = 0; run < runs; run++) {
  cIJK = multiplyIJK(a, b, n);
  cIKJ = multiplyIKJ(a, b, n);
  sumIJK += checksum(cIJK, n);
  sumIKJ += checksum(cIKJ, n);
}

console.log("size", n);
console.log("runs", runs);
console.log("checksum ijk", sumIJK);
console.log("checksum ikj", sumIKJ);
console.log("checksums match", sumIJK === sumIKJ);

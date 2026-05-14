function countPrimes(limit) {
  var isPrime = [];
  var i = 0;
  var j = 0;
  var count = 0;

  for (i = 0; i <= limit; i++) {
    isPrime.push(true);
  }

  isPrime[0] = false;
  isPrime[1] = false;

  for (i = 2; i * i <= limit; i++) {
    if (isPrime[i]) {
      for (j = i * i; j <= limit; j += i) {
        isPrime[j] = false;
      }
    }
  }

  for (i = 2; i <= limit; i++) {
    if (isPrime[i]) {
      count += 1;
    }
  }

  return count;
}

function runWorkload(limit) {
  var exact = countPrimes(limit);
  var half = countPrimes(limit / 2);
  var quarter = countPrimes(limit / 4);

  return exact + half + quarter;
}

var n = 220000;
var runs = 4;
var i = 0;
var score = 0;

for (i = 0; i < runs; i++) {
  score += runWorkload(n);
}

console.log("n", n);
console.log("runs", runs);
console.log("score", score);

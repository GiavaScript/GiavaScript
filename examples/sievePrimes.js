function countPrimes(limit) {
  var isPrime = [];
  var i = 0;
  var j = 0;
  var count = 0;

  for (i = 0; i <= limit; i = i + 1) {
    isPrime.push(true);
  }

  isPrime[0] = false;
  isPrime[1] = false;

  for (i = 2; i * i <= limit; i = i + 1) {
    if (isPrime[i]) {
      for (j = i * i; j <= limit; j = j + i) {
        isPrime[j] = false;
      }
    }
  }

  for (i = 2; i <= limit; i = i + 1) {
    if (isPrime[i]) {
      count = count + 1;
    }
  }

  return count;
}

var n = 200000;
var result = countPrimes(n);

console.log("n", n);
console.log("primeCount", result);

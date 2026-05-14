function makeNode(value) {
  return {"value": value, "left": null, "right": null};
}

function insert(root, value) {
  var current = null;

  if (root) {
    current = root;
  } else {
    return makeNode(value);
  }

  for (; current;) {
    if (value < current.value) {
      if (current.left) {
        current = current.left;
      } else {
        current.left = makeNode(value);
        return root;
      }
    } else {
      if (current.right) {
        current = current.right;
      } else {
        current.right = makeNode(value);
        return root;
      }
    }
  }
}

function inorder(node, out) {
  if (node) {
    inorder(node.left, out);
    out.push(node.value);
    inorder(node.right, out);
  } else {
    return;
  }
}

function height(node) {
  var leftHeight = 0;
  var rightHeight = 0;

  if (node) {
    leftHeight = height(node.left);
    rightHeight = height(node.right);

    if (leftHeight > rightHeight) {
      return leftHeight + 1;
    }

    return rightHeight + 1;
  } else {
    return 0;
  }
}

function contains(node, value) {
  var current = node;

  for (; current;) {
    if (value === current.value) {
      return true;
    }

    if (value < current.value) {
      current = current.left;
    } else {
      current = current.right;
    }
  }

  return false;
}

function makeValues(count, seed) {
  var values = [];
  var state = seed;
  var i = 0;

  for (i = 0; i < count; i++) {
    state = (state * 17 + 23) % 10007;
    values.push(state);
  }

  return values;
}

function makeQueries(values, count) {
  var queries = [];
  var i = 0;
  var index = 0;

  for (i = 0; i < count; i++) {
    index = (i * 37 + 11) % values.length;
    if (i % 2 === 0) {
      queries.push(values[index]);
    } else {
      queries.push(values[index] + 10009);
    }
  }

  return queries;
}

function runWorkload(values, queries) {
  var root = null;
  var ordered = [];
  var i = 0;
  var hits = 0;
  var orderedSum = 0;

  for (i = 0; i < values.length; i++) {
    root = insert(root, values[i]);
  }

  inorder(root, ordered);

  for (i = 0; i < queries.length; i++) {
    if (contains(root, queries[i])) {
      hits += 1;
    }
  }

  for (i = 0; i < ordered.length; i++) {
    orderedSum += ordered[i];
  }

  return orderedSum + height(root) + hits;
}

var valueCount = 2000;
var queryCount = 4000;
var runs = 4;
var values = makeValues(valueCount, 7);
var queries = makeQueries(values, queryCount);
var i = 0;
var score = 0;

for (i = 0; i < runs; i++) {
  score += runWorkload(values, queries);
}

console.log("values", valueCount);
console.log("queries", queryCount);
console.log("runs", runs);
console.log("score", score);

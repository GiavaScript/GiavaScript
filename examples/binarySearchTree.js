function makeNode(value) {
  return {"value": value, "left": null, "right": null};
}

function insert(root, value) {
  var current = null;

  if (root == null) {
    return makeNode(value);
  }

  current = root;
  for (; true;) {
    if (value < current.value) {
      if (current.left == null) {
        current.left = makeNode(value);
        return root;
      }
      current = current.left;
    } else {
      if (current.right == null) {
        current.right = makeNode(value);
        return root;
      }
      current = current.right;
    }
  }
}

function inorder(node, out) {
  if (node == null) {
    return;
  }

  inorder(node.left, out);
  out.push(node.value);
  inorder(node.right, out);
}

function height(node) {
  var leftHeight = 0;
  var rightHeight = 0;

  if (node == null) {
    return 0;
  }

  leftHeight = height(node.left);
  rightHeight = height(node.right);

  if (leftHeight > rightHeight) {
    return leftHeight + 1;
  }

  return rightHeight + 1;
}

function contains(node, value) {
  var current = node;

  for (; current != null;) {
    if (value == current.value) {
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

var values = [7, 3, 9, 1, 5, 8, 10, 4, 6];
var root = null;
var i = 0;
var ordered = [];

for (i = 0; i < values.length; i = i + 1) {
  root = insert(root, values[i]);
}

inorder(root, ordered);

console.log("in-order", ordered);
console.log("height", height(root));
console.log("contains 5", contains(root, 5));
console.log("contains 12", contains(root, 12));

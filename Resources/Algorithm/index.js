const Clock = require("./clock.js")
const clock = new Clock();
clock.push(0);
clock.turn(0, 1);
console.log(clock.show());

clock.push(1);
clock.turn(1, 1);
console.log(clock.show());

clock.push(2);
clock.turn(2, 1);
console.log(clock.show());

clock.push(3);
clock.turn(3, -1);
console.log(clock.show());
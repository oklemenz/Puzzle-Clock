# Puzzle Clock

Puzzle Clock is a two-sided puzzle, each side presenting nine clocks. The aim of the puzzle is to set all nine clocks to 12 o'clock on both sides of the puzzle simultaneously.

The clocks can be rotated with four wheels, one at each corner of the puzzle. Four buttons in the middle of the puzzle have two states (in or out) that determine which set of clocks
on the front and on the back are turned simultaneously by rotating a wheel of a corner.

Try to solve the puzzle as fast as you can to achieve the best time in the Game Center.

# Algorithm 


Reference: [Rubik's Clock](./Resources/Algorithm/Rubik's Clock.pdf)

```js
module.exports = class Clock {
    
    constructor() {
        this.clocks = Array(18).fill(0);
        this.buttons = Array(4).fill(false);
    }
  
    push(button) {
        if (button < 0 && button >= 4) {
            return;
        }
        this.buttons[button] = !this.buttons[button];
        return this;
    }
  
    turn(wheel, num) {
        if (wheel < 0 || wheel >= 4) {
            return;
        }
        let b0 = this.buttons[0];
        let b1 = this.buttons[1];
        let b2 = this.buttons[2];
        let b3 = this.buttons[3];
        let t0, t1;
        switch (wheel) {
            case 0: t0 = false; t1 = false; break;
            case 1: t0 = false; t1 = true; break;
            case 2: t0 = true; t1 = false; break;
            case 3: t0 = true; t1 = true; break;
        }
        for (let i = 0; i < 2; i++) {
            const d = Array(9).fill(false);
            d[0] = (!t0 && !t1) || ((b0==b1) && !t0) || ((b0==b2) && t0 && !t1) || ((b0==b3) && t0 && t1);
            d[1] = (((!t0 && !t1) || (b3 && t0 && t1)) && b0) || ((b3 || !t0) && b1 && t1) || (((!b0 && b1) || b0) && b2 && t0 && !t1);
            d[2] = (!t0 && t1) || ((b1==b0) && !t0) || ((b1==b2) && t0 && !t1) || ((b1==b3) && t1);
            d[3] = ((!t1 || b1) && b0 && !t0) || ((!t1 || b3) && b2 && t0) || (((b1 && b2 && !t0) || (b0 && b3 && t0)) && t1);
            d[4] = (((b3 && t1) || (b2 && !t1)) && t0) || (((b1 && t1) ||(b0 && !t1)) && !t0);
            d[5] = (((b3 && t0) || (b1 && !t0)) && t1) || (((b3 && !t1) || b1) && b0 && !t0) || (((b1 && !t1) || b3) && b2 && t0);
            d[6] = (t0 && !t1) || ((b2==b0) && !t0 && !t1) || ((b2==b1) && !t0 && t1) || ((b2==b3) && t0);
            d[7] = ((b1 || t0) && b3 && t1) || (((b1 && !t0 && t1) || (t0 && !t1)) && b2) || ((b2 || b3) && b0 && !t0 && !t1);
            d[8] = (t0 && t1) || ((b3==b0) && !t0 && !t1) || ((b3==b1) && t1) || ((b3==b2) && t0);
            for (let j = 0; j < 9; j++) {
				if (d[j]) {
                    this.clocks[j + 9 * i] = (this.clocks[j + 9 * i] += num) % 12 < 0 ? this.clocks[j + 9 * i] % 12 + 12 : this.clocks[j + 9 * i] % 12;
                }
            }
            num = -num; 
            b0 = !b0;
            b1 = !b1;
            b2 = !b2;
            b3 = !b3;
        }
        return this;
    }
}
```

Usage:

```
const Clock = require("./Clock.js")
const clock = new Clock();
clock.push(0);
clock.turn(0, 1);
```

# Download

- App Store: https://apps.apple.com/us/app/puzzle-clock/id594207501?mt=8

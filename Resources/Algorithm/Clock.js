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
        let [b0, b1, b2, b3] = this.buttons;
        const t0 = wheel === 2 || wheel == 3;
        const t1 = wheel === 1 || wheel == 3;
        const d = [];
        for (let i = 0; i < 2; i++) {
            d[0] = (!t0 && !t1) || ((b0 == b1) && !t0) || ((b0 == b2) && t0 && !t1) || ((b0 == b3) && t0 && t1);
            d[1] = (((!t0 && !t1) || (b3 && t0 && t1)) && b0) || ((b3 || !t0) && b1 && t1) || (((!b0 && b1) || b0) && b2 && t0 && !t1);
            d[2] = (!t0 && t1) || ((b1 == b0) && !t0) || ((b1 == b2) && t0 && !t1) || ((b1 == b3) && t1);
            d[3] = ((!t1 || b1) && b0 && !t0) || ((!t1 || b3) && b2 && t0) || (((b1 && b2 && !t0) || (b0 && b3 && t0)) && t1);
            d[4] = (((b3 && t1) || (b2 && !t1)) && t0) || (((b1 && t1) || (b0 && !t1)) && !t0);
            d[5] = (((b3 && t0) || (b1 && !t0)) && t1) || (((b3 && !t1) || b1) && b0 && !t0) || (((b1 && !t1) || b3) && b2 && t0);
            d[6] = (t0 && !t1) || ((b2 == b0) && !t0 && !t1) || ((b2 == b1) && !t0 && t1) || ((b2 == b3) && t0);
            d[7] = ((b1 || t0) && b3 && t1) || (((b1 && !t0 && t1) || (t0 && !t1)) && b2) || ((b2 || b3) && b0 && !t0 && !t1);
            d[8] = (t0 && t1) || ((b3 == b0) && !t0 && !t1) || ((b3 == b1) && t1) || ((b3 == b2) && t0);
            for (let j = 0; j < 9; j++) {
                if (d[j]) {
                    this.clocks[j + 9 * i] = (this.clocks[j + 9 * i] + num + 12) % 12;
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

    show() {
        let result = "";
        for (let i = 0; i < 3; i++) {
            for (let j = 0; j < 3; j++) {
                result += (this.clocks[i * 3 + j] < 11 ? this.clocks[i * 3 + j] : "\u2016") + " ";
            }
            result += "  ";
            for (let j = 2; j >= 0; j--) {
                result += (this.clocks[i * 3 + j] < 11 ? this.clocks[i * 3 + j] : "\u2016") + " ";
            }
            result += "\n";
            if (i == 0) {
                result += ` ${this.buttons[0] ? "*" : "o"} ${this.buttons[1] ? "*" : "o"}`;
                result += `     ${this.buttons[1] ? "*" : "o"} ${this.buttons[0] ? "*" : "o"}`;
            } else if (i == 1) {
                result += ` ${this.buttons[2] ? "*" : "o"} ${this.buttons[3] ? "*" : "o"}`;
                result += `     ${this.buttons[3] ? "*" : "o"} ${this.buttons[2] ? "*" : "o"}`;
            }
            result += "\n";
        }
        return result;
    }
}
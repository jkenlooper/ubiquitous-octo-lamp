import mocha from "mocha";
import chai from "chai";
import xstate from "@xstate/fsm";

import { puzzlePieceMachineDefinition } from "./puzzle-piece-machine-definition.js";

const defaultPieceContext = {
  id: 1,
  s: 1,
  x: 1,
  y: 1,
  r: 1,
  w: 20,
  h: 20,
  b: 1,
};

mocha.suite("Initial puzzle piece state when first loading", () => {
  let machine;
  mocha.setup(() => {
    machine = xstate.createMachine(puzzlePieceMachineDefinition);
  });
  mocha.test("immovable if piece status (s) is 1", () => {
    const initialPieceState = {
      value: "unknown",
      context: Object.assign(defaultPieceContext, { s: 1 }),
    };
    const event = {
      type: "",
    };
    let nextState = machine.transition(initialPieceState, event);
    chai.assert("immovable" === nextState.value, "state is immovable");
    chai.assert(1 === nextState.context.s);
    nextState = machine.transition(nextState, {
      type: "MOUSEDOWN",
      payload: { x: 3, y: 3 },
    });
    chai.assert("immovable" === nextState.value);
    chai.assert(1 === nextState.context.s);
    // Position remains the same as the initial piece state.
    chai.assert(initialPieceState.context.x === nextState.context.x);
    chai.assert(initialPieceState.context.y === nextState.context.y);
  });

  mocha.test("movable if piece status (s) is not 1", () => {
    const initialPieceState = {
      value: "unknown",
      context: Object.assign(defaultPieceContext, { s: 0 }),
    };
    const event = {
      type: "",
    };
    let nextState = machine.transition(initialPieceState, event);
    chai.assert("movable" === nextState.value);
    chai.assert(0 === nextState.context.s);
    nextState = machine.transition(nextState, {
      type: "MOUSEDOWN",
      payload: {
        x: initialPieceState.context.x,
        y: initialPieceState.context.y,
      },
    });

    nextState = machine.transition(nextState, {
      type: "MOUSEUP",
      payload: { x: 3, y: 3 },
    });

    nextState = machine.transition(nextState, {
      type: "UPDATE",
      payload: { x: 30, y: 30 },
    });

    // TODO: send events MOUSEUP, UPDATE
    chai.assert("movable" === nextState.value);
    chai.assert(0 === nextState.context.s);
    // Position is updated
    chai.assert(30 === nextState.context.x, "position is updated");
    chai.assert(30 === nextState.context.y, "position is updated");
  });
});

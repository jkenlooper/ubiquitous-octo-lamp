import mocha from "mocha";
import chai from "chai";

import puzzlePieceMachine from "./puzzle-piece-machine.mjs";
import {
  state,
  action,
  event,
  MOVABLE,
  IMMOVABLE,
} from "./puzzle-piece-machine-definition.mjs";
const machine = puzzlePieceMachine;

/**
 * @type {Object} defaultPieceContext
 * @type {number} defaultPieceContext.id
 * ...
 */
const defaultPieceContext = {
  id: 1,
  s: 1,
  x: 1,
  y: 1,
  r: 1,
  g: 1,
  w: 20,
  h: 20,
  b: 1,
  token: undefined,
  groupActive: undefined,
};

mocha.suite("Initial puzzle piece state when first loading", () => {
  mocha.test("immovable if piece status (s) is 1", () => {
    const initialPieceState = {
      value: state.unknown,
      context: Object.assign({}, defaultPieceContext, { s: IMMOVABLE }),
    };
    let nextState = machine.transition(initialPieceState, "");
    chai.assert.equal(nextState.value, state.immovable);
    chai.assert.equal(nextState.context.s, IMMOVABLE);
    nextState = machine.transition(nextState, {
      type: event.MOUSEDOWN,
      payload: { x: 3, y: 3 },
    });
    chai.assert.equal(nextState.value, state.immovable);
    chai.assert.equal(nextState.context.s, IMMOVABLE);
    // Position remains the same as the initial piece state.
    chai.assert.equal(nextState.context.x, initialPieceState.context.x);
    chai.assert.equal(nextState.context.y, initialPieceState.context.y);
  });

  mocha.test("movable if piece status (s) is not 1", () => {
    const initialPieceState = {
      value: state.unknown,
      context: Object.assign({}, defaultPieceContext, { s: MOVABLE }),
    };
    let nextState = machine.transition(initialPieceState, "");
    chai.assert.equal(nextState.value, state.movable);
    chai.assert.strictEqual(nextState.context.s, MOVABLE);

    // Player clicks on piece
    nextState = machine.transition(nextState, {
      type: event.MOUSEDOWN,
      payload: {
        x: initialPieceState.context.x + 10,
        y: initialPieceState.context.y + 7,
      },
    });
    chai.assert.equal(nextState.value, state.pendingClaim);
    chai.assert.deepEqual(nextState.actions, [
      {
        type: action.postPlayerAction,
      },
      {
        type: action.getToken,
      },
    ]);
    nextState = machine.transition(nextState, {
      type: event.MOUSEUP,
      payload: { x: 5, y: 2 },
    });
    chai.assert.equal(nextState.value, state.pendingClaim);
    /*
    chai.assert.deepEqual(nextState.actions, [
      {
        type: action.postPlayerAction,
      },
      {
        type: action.getToken,
      },
    ]);
    */

    // Player gets token
    nextState = machine.transition(nextState, {
      type: event.TOKEN_SUCCESS,
      payload: { token: "asdf" },
    });
    chai.assert.equal(nextState.value, state.claimed);
    chai.assert.deepEqual(nextState.actions, [
      {
        type: action.startClaimTimeout,
      },
    ]);
    nextState = machine.transition(nextState, event.NULL);
    chai.assert.equal(nextState.value, state.active);

    nextState = machine.transition(nextState, {
      type: event.MOUSEDOWN,
      payload: { x: 35, y: 32 },
    });
    chai.assert.equal(nextState.value, state.pending);

    nextState = machine.transition(nextState, {
      type: event.MOUSEUP,
      payload: { x: 35, y: 32 },
    });
    chai.assert.equal(nextState.value, state.pending);

    nextState = machine.transition(nextState, {
      type: event.UPDATE,
      payload: { x: 30, y: 30, s: 0, g: 3 },
    });

    chai.assert.equal(nextState.value, state.movable);
    chai.assert.equal(nextState.context.s, MOVABLE);
    chai.assert.deepEqual(nextState.actions, [
      {
        type: action.updatePieceGroupMove,
      },
      {
        type: action.updatePiece,
      },
    ]);

    // Position is updated
    chai.assert.equal(nextState.context.x, 30, "position is updated");
    chai.assert.equal(nextState.context.y, 30, "position is updated");
  });
});

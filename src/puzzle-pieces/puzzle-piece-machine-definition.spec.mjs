import mocha from "mocha";
import chai from "chai";

import puzzlePieceMachine from "./puzzle-piece-machine.mjs";
import {
  state,
  defaultPieceContext,
  action,
  event,
  MOVABLE,
  IMMOVABLE,
} from "./puzzle-piece-machine-definition.mjs";

const machine = puzzlePieceMachine;

mocha.suite("Initial puzzle piece state when first loading", () => {
  mocha.test("unknown until UPDATE event", () => {
    chai.assert.equal(machine.initialState.value, state.unknown);
    let nextState = machine.transition(machine.initialState.value, {
      type: event.UPDATE,
      payload: {
        id: 1,
        s: IMMOVABLE,
        x: 1,
        y: 1,
        r: 1,
        //g: 1,
        w: 20,
        h: 20,
        b: 1,
      },
    });
    chai.assert.notEqual(nextState.value, state.unknown);
    chai.assert.equal(nextState.context.id, 1);
    chai.assert.equal(nextState.context.g, undefined);
  });

  mocha.test("immovable cond", () => {
    chai.assert.equal(machine.initialState.value, state.unknown);
    let nextState = machine.transition(machine.initialState.value, {
      type: event.UPDATE,
      payload: {
        id: 1,
        s: IMMOVABLE,
        x: 1,
        y: 1,
        r: 1,
        //g: 1,
        w: 20,
        h: 20,
        b: 1,
      },
    });

    chai.assert.equal(nextState.value, state.immovable);
    chai.assert.equal(nextState.context.s, IMMOVABLE);
  });

  mocha.test("movable if piece status (s) is not 1", () => {
    let nextState = machine.transition(machine.initialState.value, {
      type: event.UPDATE,
      payload: {
        id: 1,
        s: MOVABLE,
        x: 1,
        y: 1,
        r: 1,
        //g: 1,
        w: 20,
        h: 20,
        b: 1,
      },
    });
    chai.assert.equal(nextState.value, state.movable);
    chai.assert.strictEqual(nextState.context.s, MOVABLE);
  });
});

mocha.suite("Observe piece updates when piece is movable", () => {
  mocha.test("New x,y for non-grouped piece", () => {
    const pieceState = {
      value: state.movable,
      context: Object.assign({}, defaultPieceContext, {
        id: 1,
        s: MOVABLE,
        x: 23,
        y: 56,
        r: 1,
        //g: 1,
        w: 20,
        h: 20,
        b: 1,
      }),
    };
    let nextState = machine.transition(pieceState, {
      type: event.UPDATE,
      payload: {
        id: 1,
        s: MOVABLE,
        x: 111,
        y: 222,
      },
    });
    chai.assert.equal(nextState.value, state.movable);
    chai.assert.strictEqual(nextState.context.s, MOVABLE);
    chai.assert.strictEqual(nextState.context.x, 111);
    chai.assert.strictEqual(nextState.context.y, 222);
    chai.assert.deepEqual(nextState.actions, [
      {
        type: action.updatePiece,
      },
    ]);
  });
  mocha.test("Set immovable for non-grouped piece", () => {
    const pieceState = {
      value: state.movable,
      context: Object.assign({}, defaultPieceContext, {
        id: 1,
        s: MOVABLE,
        x: 23,
        y: 56,
        r: 1,
        //g: 1,
        w: 20,
        h: 20,
        b: 1,
      }),
    };
    let nextState = machine.transition(pieceState, {
      type: event.UPDATE,
      payload: {
        id: 1,
        s: IMMOVABLE,
        x: 111,
        y: 222,
      },
    });
    chai.assert.equal(nextState.value, state.immovable);
    chai.assert.strictEqual(nextState.context.s, IMMOVABLE);
    chai.assert.strictEqual(nextState.context.x, 111);
    chai.assert.strictEqual(nextState.context.y, 222);
    chai.assert.deepEqual(nextState.actions, [
      {
        type: action.updatePiece,
      },
    ]);
  });
});

mocha.suite("WIP player events", () => {
  mocha.test("WIP ..movable if piece status (s) is not 1", () => {
    let nextState = machine.transition(machine.initialState.value, {
      type: event.UPDATE,
      payload: {
        id: 1,
        s: MOVABLE,
        x: 1,
        y: 1,
        r: 1,
        //g: 1,
        w: 20,
        h: 20,
        b: 1,
      },
    });
    // Player clicks on piece
    nextState = machine.transition(nextState, {
      type: event.MOUSEDOWN,
      payload: {
        x: nextState.context.x + 10,
        y: nextState.context.y + 7,
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
      /*
      {
        type: action.updatePieceGroupMove,
      },
      */
      {
        type: action.updatePiece,
      },
    ]);

    // Position is updated
    chai.assert.equal(nextState.context.x, 30, "position is updated");
    chai.assert.equal(nextState.context.y, 30, "position is updated");
  });
});

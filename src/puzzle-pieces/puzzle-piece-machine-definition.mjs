import xstate from "@xstate/fsm";
const assign = xstate.assign;

// TODO: WIP
const IMMOVABLE = 1;
const MOVABLE = 0;

function isImmovable(context, event) {
  return event.payload.s === IMMOVABLE;
}
function isMovable(context, event) {
  return event.payload.s !== IMMOVABLE;
}
const state = Object.freeze({
  unknown: "unknown",
  immovable: "immovable",
  movable: "movable",
  pendingClaim: "pendingClaim",
  claimed: "claimed",
  queued: "queued",
  selected: "selected",
  active: "active",
  pending: "pending",
});

const action = Object.freeze({
  postPlayerAction: "postPlayerAction",
  updatePiece: "updatePiece",
  abortPieceGroupMove: "abortPieceGroupMove",
  updatePieceGroupMove: "updatePieceGroupMove",
  getToken: "getToken",
  startClaimTimeout: "startClaimTimeout",
  //startAnimation: "startAnimation",
});

const event = Object.freeze({
  NULL: "",
  MOUSEDOWN: "MOUSEDOWN",
  UPDATE: "UPDATE",
  TOKEN_SUCCESS: "TOKEN_SUCCESS",
  CLAIM_TIMEOUT: "CLAIM_TIMEOUT",
  MOUSEUP: "MOUSEUP",
});

/**
 * @type {Object} defaultPieceContext
 * @type {number} defaultPieceContext.id
 * ...
 */
const defaultPieceContext = Object.freeze({
  // mutable piece properties
  x: undefined,
  y: undefined,
  r: undefined,
  s: undefined,
  g: undefined,
  // immutable piece properties
  id: undefined,
  w: undefined,
  h: undefined,
  b: undefined,
  // context
  token: undefined,
  groupActive: undefined,
});

const stateDefinitions = {};

stateDefinitions[state.unknown] = {
  entry: [assign(Object.assign({}, defaultPieceContext))],
  on: {},
};

//stateDefinitions[state.unknown].on[event.NULL] = [];

// Immediately transition to the next state
// depending on the status ('s') value.
stateDefinitions[state.unknown].on[event.UPDATE] = [
  {
    target: state.immovable,
    cond: isImmovable,
    actions: [
      assign((context, event) => {
        return event.payload;
      }),
      action.updatePiece,
    ],
  },
  {
    target: state.movable,
    cond: isMovable,
    actions: [
      assign((context, event) => {
        return event.payload;
      }),
      action.updatePiece,
    ],
  },
];

// locked in it's current position
stateDefinitions[state.immovable] = {
  type: "final",
  entry: [
    /*
    assign((context, event) => {
      return event.payload;
    }),
    */
  ],
};

// can be moved
stateDefinitions[state.movable] = {
  entry: [
    assign({
      groupActive: (context, event) => {
        // Set the groupActive context if this piece is part of
        // a group.
        return context.g;
      },
    }),
  ],
  exit: [],
  on: {},
};

// mousedown or touchstart
stateDefinitions[state.movable].on[event.MOUSEDOWN] = [
  {
    target: state.pendingClaim,
    actions: [action.postPlayerAction],
  },
];

// server has new properties
stateDefinitions[state.movable].on[event.UPDATE] = [
  {
    target: state.immovable,
    cond: (context, event) => {
      // Check that the piece that is transitioning to immovable is not
      // currently part of a group that is being moved by the player.
      return (
        event.payload &&
        event.payload.s === IMMOVABLE &&
        context.groupActive === undefined
      );
    },
    actions: [
      assign((context, event) => {
        return event.payload;
      }),
      action.updatePiece,
    ],
  },
  {
    target: state.immovable,
    cond: (context, event) => {
      // If the piece is currently part of group that is being moved by
      // the player.
      return (
        event.payload &&
        event.payload.s === IMMOVABLE &&
        context.groupActive !== undefined
      );
    },
    actions: [
      assign((context, event) => {
        return event.payload;
      }),
      action.abortPieceGroupMove,
      action.updatePiece,
    ],
  },
  {
    target: state.movable,
    cond: (context, event) => {
      return (
        event.payload &&
        event.payload.s !== IMMOVABLE &&
        context.groupActive !== undefined
      );
    },
    actions: [
      assign((context, event) => {
        return event.payload;
      }),
      action.updatePieceGroupMove,
      action.updatePiece,
    ],
  },
  {
    target: state.movable,
    cond: (context, event) => {
      return (
        event.payload &&
        event.payload.s !== IMMOVABLE &&
        context.groupActive === undefined
      );
    },
    actions: [
      assign((context, event) => {
        return event.payload;
      }),
      action.updatePiece,
    ],
  },
];

// player is getting token
stateDefinitions[state.pendingClaim] = {
  entry: [action.getToken],
  exit: [],
  on: {},
};
stateDefinitions[state.pendingClaim].on[event.TOKEN_SUCCESS] = [
  {
    target: state.claimed,
    actions: [
      assign({
        token: (context, event) => {
          return event.payload.token;
        },
      }),
    ],
  },
];

// currently being moved by a player (5 second timeout)
stateDefinitions[state.claimed] = {
  entry: [action.startClaimTimeout],
  on: {},
};
stateDefinitions[state.claimed].on[event.NULL] = [
  {
    target: state.active,
    cond: (context, event) => {
      // Assume that if a token exists that the player has claimed it
      return !!context.token;
    },
  },
];

stateDefinitions[state.claimed].on[event.CLAIM_TIMEOUT] = [
  {
    target: state.claimed,
    cond: (context, event) => {
      // No token would imply that another player has claimed it
      return !context.token;
    },
  },
];

// player is waiting to claim the piece
stateDefinitions[state.queued] = {};

// player has selected the piece
stateDefinitions[state.selected] = {};

// player is moving the piece (5 second timeout)
stateDefinitions[state.active] = { on: {} };
stateDefinitions[state.active].on[event.CLAIM_TIMEOUT] = [
  {
    target: state.pendingClaim,
  },
];
stateDefinitions[state.active].on[event.MOUSEDOWN] = [
  {
    target: state.pending,
  },
];
stateDefinitions[state.active].on[event.MOUSEUP] = [
  {
    target: state.pending,
  },
];

// player has dropped the piece and is waiting for server response
stateDefinitions[state.pending] = { on: {} };
// server has new properties
stateDefinitions[state.pending].on[event.UPDATE] = [
  {
    target: state.immovable,
    cond: (context, event) => {
      // Check that the piece that is transitioning to immovable is not
      // currently part of a group that is being moved by the player.
      return (
        event.payload &&
        event.payload.s === IMMOVABLE &&
        context.groupActive === undefined
      );
    },
    actions: [
      assign((context, event) => {
        return event.payload;
      }),
      action.updatePiece,
    ],
  },
  {
    target: state.immovable,
    cond: (context, event) => {
      // If the piece is currently part of group that is being moved by
      // the player.
      return (
        event.payload &&
        event.payload.s === IMMOVABLE &&
        context.groupActive !== undefined
      );
    },
    actions: [
      assign((context, event) => {
        return event.payload;
      }),
      action.abortPieceGroupMove,
      action.updatePiece,
    ],
  },
  {
    target: state.movable,
    cond: (context, event) => {
      return (
        event.payload &&
        event.payload.s !== IMMOVABLE &&
        context.groupActive !== undefined
      );
    },
    actions: [
      assign((context, event) => {
        return event.payload;
      }),
      action.updatePieceGroupMove,
      action.updatePiece,
    ],
  },
  {
    target: state.movable,
    cond: (context, event) => {
      return (
        event.payload &&
        event.payload.s !== IMMOVABLE &&
        context.groupActive === undefined
      );
    },
    actions: [
      assign((context, event) => {
        return event.payload;
      }),
      action.updatePiece,
    ],
  },
];

//// is transitioning to new position
//stateDefinitions[state.animating] = {
//  entry: [
//    action.startAnimation,
//    assign({
//    }),
//  ]
//};

const puzzlePieceMachineDefinition = {
  id: "puzzle-piece",
  initial: state.unknown,
  context: Object.assign({}, defaultPieceContext),
  states: stateDefinitions,
};

//const machine = Machine(puzzlePieceMachineDefinition);

export {
  puzzlePieceMachineDefinition,
  defaultPieceContext,
  state,
  action,
  event,
  IMMOVABLE,
  MOVABLE,
};

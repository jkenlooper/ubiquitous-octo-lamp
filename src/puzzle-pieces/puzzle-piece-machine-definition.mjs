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
function isInterrupt( context, event) {
  return event.payload.interrupt;
}
function claimQueueNotEmpty(context, event) {
  return false;
}
function claimQueueEmpty(context, event) {
  return true;
}
const state = Object.freeze({
  unknown: "unknown",
  immovable: "immovable",
  movable: "movable",
  pendingClaim: "pendingClaim",
  claimed: "claimed",
  queued: "queued",
  selected: "selected",
  rotate: "rotate",
  translate: "translate",
  pendingTransform: "pendingTransform",
  transitionStart: "transitionStart",
  transitionInProgress: "transitionInProgress",
  transitionEnd: "transitionEnd",
  interrupt: "interrupt",
});

const action = Object.freeze({
  addToActionQueue: "addToActionQueue",
  popActionQueue: "popActionQueue",
  clearActionQueue: "clearActionQueue",

  // old
  postPlayerAction: "postPlayerAction",
  updatePiece: "updatePiece",
  abortPieceGroupMove: "abortPieceGroupMove",
  updatePieceGroupMove: "updatePieceGroupMove",
  getToken: "getToken",
  startClaimTimeout: "startClaimTimeout",
  //startAnimation: "startAnimation",
});

const event = Object.freeze({
  //NULL: "",
  ACTION_START: "ACTION_START",
  UPDATE: "UPDATE",
  TOKEN_SUCCESS: "TOKEN_SUCCESS",
  CLAIM_TIMEOUT: "CLAIM_TIMEOUT",
  ACTION_END: "ACTION_END",
  ACTION_MOVE: "ACTION_MOVE",
  ACTION_ROTATE: "ACTION_ROTATE",
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
  claimQueue: undefined,
  actionQueue: undefined,
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
  //type: "final",
  entry: [
    /*
    assign((context, event) => {
      return event.payload;
    }),
    */
    action.clearActionQueue,
  ],
};
stateDefinitions[state.immovable].on[event.UPDATE] = [
  {
    target: state.movable,
    cond: isMovable,
  },
];

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
    action.popActionQueue,
  ],
  exit: [],
  on: {},
};

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
  //{
  //  target: state.immovable,
  //  cond: (context, event) => {
  //    // If the piece is currently part of group that is being moved by
  //    // the player.
  //    return (
  //      event.payload &&
  //      event.payload.s === IMMOVABLE &&
  //      context.groupActive !== undefined
  //    );
  //  },
  //  actions: [
  //    assign((context, event) => {
  //      return event.payload;
  //    }),
  //    action.abortPieceGroupMove,
  //    action.updatePiece,
  //  ],
  //},
  {
    target: state.claimed,
  },
];
// mousedown or touchstart
stateDefinitions[state.movable].on[event.ACTION_START] = [
  {
    target: state.pendingClaim,
  },
];

// player is getting token
stateDefinitions[state.pendingClaim] = {
  entry: [action.addToActionQueue],
  exit: [],
  on: {},
};
stateDefinitions[state.pendingClaim].on[event.TOKEN_SUCCESS] = [
  {
    target: state.queued,
    cond: (context, event) => {
      return (
        //claimQueueNotEmpty
      );
    },
    actions: [
      assign({
        token: (context, event) => {
          return event.payload.token;
        },
      }),
    ],
  },
  {
    target: state.selected,
    cond: claimQueueEmpty,
    actions: [
      assign({
        token: (context, event) => {
          return event.payload.token;
        },
      }),
    ],
  },
];
stateDefinitions[state.pendingClaim].on[event.UPDATE] = [
  {
    target: state.interrupt,
    cond: isInterrupt
  }
];
stateDefinitions[state.pendingClaim].on[event.TOKEN_SUCCESS] = [
  {
    target: state.queued,
    cond: claimQueueNotEmpty
  },
  {
    target: state.selected,
    cond: claimQueueEmpty
  }
];

stateDefinitions[state.pendingClaim].on[event.ACTION_ROTATE] = [
  {
    target: state.pendingClaim
  }
];
stateDefinitions[state.pendingClaim].on[event.ACTION_MOVE] = [
  {
    target: state.pendingClaim
  }
];
stateDefinitions[state.pendingClaim].on[event.ACTION_END] = [
  {
    target: state.pendingClaim
  }
];

stateDefinitions[state.claimed] = {
  on: {},
};
stateDefinitions[state.claimed].on[event.UPDATE] = [
  {
    target: state.transitionStart,
  },
];

stateDefinitions[state.claimed].on[event.ACTION_START] = [
  {
    target: state.pendingClaim,
  },
];

// player is waiting to claim the piece
stateDefinitions[state.queued] = {
  on: {},
};
stateDefinitions[state.queued].on[event.UPDATE] = [
  {
    target: state.interrupt,
    cond: isInterrupt,
  },
  {
    target: state.selected,
    cond: (context, event) => {
      return (
        isMovable && playerIsNextInQueue
    },
  },
];

// player has selected the piece
stateDefinitions[state.selected] = {
  on: {},
  entry: [action.popActionQueue],
};
stateDefinitions[state.selected].on[event.UPDATE] = [
  {
    target: state.interrupt,
    cond: isInterrupt,
  }
];
stateDefinitions[state.selected].on[event.ACTION_ROTATE] = [
  {
    target: state.rotate
  }
];
stateDefinitions[state.selected].on[event.ACTION_MOVE] = [
  {
    target: state.translate
  }
];
stateDefinitions[state.selected].on[event.CLAIM_TIMEOUT] = [
  {
    target: state.pendingClaim
  }
];

stateDefinitions[state.rotate] = { on: {} };
stateDefinitions[state.rotate].on[event.UPDATE] = [
  {
    target: state.interrupt,
    cond: isInterrupt
  }
];
stateDefinitions[state.rotate].on[event.ACTION_END] = [
  {
    target: state.pendingTransform,
  }
];
stateDefinitions[state.translate] = { on: {} };
stateDefinitions[state.translate].on[event.UPDATE] = [
  {
    target: state.interrupt,
    cond: isInterrupt
  }
];
stateDefinitions[state.translate].on[event.ACTION_END] = [
  {
    target: state.pendingTransform,
  }
];

// player has dropped the piece and is waiting for server response
stateDefinitions[state.pendingTransform] = { on: {} };
// server has new properties
stateDefinitions[state.pendingTransform].on[event.UPDATE] = [
  {
    target: state.interrupt,
    cond: isInterrupt
  },
  {
    target: state.transitionStart
  }
];

stateDefinitions[state.transitionStart] = { on: {} };
stateDefinitions[state.transitionStart].on[event.UPDATE] = [
  {
    target: state.interrupt,
    cond: isInterrupt
  },
];
stateDefinitions[state.transitionStart].on[event.NULL] = [
  {
    target: state.transitionInProgress,
  },
];
stateDefinitions[state.transitionInProgress] = { on: {} };
stateDefinitions[state.transitionInProgress].on[event.UPDATE] = [
  {
    target: state.interrupt,
    cond: isInterrupt
  },
];
stateDefinitions[state.transitionInProgress].on[event.NULL] = [
  {
    target: state.transitionEnd,
  },
];


stateDefinitions[state.transitionEnd] = { on: {} };
stateDefinitions[state.transitionEnd].on[event.UPDATE] = [
  {
    target: state.interrupt,
    cond: isInterrupt
  },
];

stateDefinitions[state.transitionEnd].on[event.NULL] = [
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
    target: state.claimed,
    cond: (context, event) => {
      return isMovable && claimQueueNotEmpty;
    },
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
  {
    target: state.selected,
    cond: (context, event) => {
      return isMovable && isSelected;
    },
  }
];

stateDefinitions[state.interrupt] = {
  on: {},
  entry: [action.clearActionQueue]
};
stateDefinitions[state.interrupt].on[event.NULL] = [
  {
    target: state.immovable,
    cond: isImmovable
  },
  {
    target: state.claimed,
    cond: isMovable && claimQueueNotEmpty
  },
  {
    target: state.movable,
    cond: isMovable
  },
];


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

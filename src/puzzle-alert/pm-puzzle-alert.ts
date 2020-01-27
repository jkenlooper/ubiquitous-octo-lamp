import { html, render } from "lit-html";
import { interpret } from "@xstate/fsm";

import { streamService } from "../puzzle-pieces/stream.service";
import { puzzleService } from "../puzzle-pieces/puzzle.service";
import { Status } from "../site/puzzle-images.service";
import { puzzleAlertMachine } from "./puzzle-alert-machine";

import "./puzzle-alert.css";

enum AlertStatus {
  connecting = "connecting",
  connected = "connected",
  reconnecting = "reconnecting",
  disconnected = "disconnected",
  blocked = "blocked",
  completed = "completed",
  frozen = "frozen",
  in_queue = "in_queue",
  invalid = "invalid",
}

interface TemplateData {
  status: AlertStatus;
  latency: number | undefined;
  message: string | undefined;
  reason: string | undefined;
}

// TODO: Rewrite this blocked message.
const BLOCKED_MSG_NOT_SPECIFIED =
  "It would seem that recent piece moves from you were flagged as unhelpful on this puzzle.";

const tag = "pm-puzzle-alert";
let lastInstanceId = 0;

customElements.define(
  tag,
  class PmPuzzleAlerts extends HTMLElement {
    static get _instanceId(): string {
      return `${tag} ${lastInstanceId++}`;
    }
    private instanceId: string;
    private puzzleId: string;
    private puzzleStatus: Status | undefined;
    private status: AlertStatus = AlertStatus.connecting;
    private message: string | undefined;
    private reason: string | undefined;
    private latency: number | undefined;
    private puzzleAlertService: any;
    private blockedTimer: number = 0;
    private blockedTimeout: number | undefined;

    constructor() {
      super();
      this.instanceId = PmPuzzleAlerts._instanceId;

      const puzzleId = this.attributes.getNamedItem("puzzle-id");
      this.puzzleId = puzzleId ? puzzleId.value : "";

      const puzzleStatus = this.attributes.getNamedItem("status");
      this.puzzleStatus = puzzleStatus
        ? <Status>(<unknown>parseInt(puzzleStatus.value))
        : undefined;
      if (!this.puzzleStatus || this.puzzleStatus !== Status.ACTIVE) {
        return;
      }

      puzzleService.subscribe(
        "piece/move/blocked",
        this.onMoveBlocked.bind(this),
        this.instanceId
      );
      streamService.subscribe(
        "socket/disconnected",
        this.onDisconnected.bind(this),
        this.instanceId
      );
      streamService.subscribe(
        "socket/reconnecting",
        this.onReconnecting.bind(this),
        this.instanceId
      );
      streamService.subscribe(
        "socket/connected",
        this.onConnected.bind(this),
        this.instanceId
      );
      streamService.subscribe(
        "puzzle/status",
        this.onPuzzleStatus.bind(this),
        this.instanceId
      );
      streamService.subscribe(
        "puzzle/ping",
        this.onPuzzlePing.bind(this),
        this.instanceId
      );

      streamService.connect(this.puzzleId);

      this.puzzleAlertService = interpret(puzzleAlertMachine).start();
      this.puzzleAlertService.subscribe(this.handleStateChange.bind(this));

      this.render();
    }

    private handleStateChange(state) {
      console.log(`puzzle-alert: ${state.value}`);
      switch (state.value) {
        case "connecting":
          state.actions.forEach((action) => {
            switch (action.type) {
              case "setStatusReconnecting":
                this.status = AlertStatus.reconnecting;
                break;
              default:
                break;
            }
          });
          break;
        case "active":
          state.actions.forEach((action) => {
            switch (action.type) {
              case "setStatusConnected":
                this.status = AlertStatus.connected;
                break;
              case "updateLatency":
                // Only need to render.
                break;
              case "showDisconnectedAlert":
                this.status = AlertStatus.disconnected;
                break;
              case "showReconnectingAlert":
                this.status = AlertStatus.reconnecting;
                break;
              default:
                break;
            }
          });
          break;
        case "inactive":
          state.actions.forEach((action) => {
            switch (action.type) {
              case "setStatusCompleted":
                this.status = AlertStatus.completed;
                break;
              case "setStatusInQueue":
                this.status = AlertStatus.in_queue;
                break;
              case "setStatusFrozen":
                this.status = AlertStatus.frozen;
                break;
              case "setInvalid":
                this.status = AlertStatus.invalid;
                break;
            }
          });
          break;
        case "disconnected":
          state.actions.forEach((action) => {
            switch (action.type) {
              case "setStatusDisconnected":
                this.status = AlertStatus.disconnected;
                break;
            }
          });
          break;
      }
      this.render();
    }

    template(data: TemplateData) {
      return html`
        ${data.status}
        <div>
          latency: ${data.latency}
        </div>
        ${data.status && data.status !== AlertStatus.connected
          ? showAlert(data.status)
          : ""}
      `;
      function showAlert(status: AlertStatus) {
        return html`
          <section class="pm-PuzzleAlert-section is-active">
            <h1><small>Alerts</small></h1>
            ${getAlert(status)}
          </section>
        `;
        function getAlert(status: AlertStatus) {
          switch (status) {
            case AlertStatus.connecting:
              return html`
                <div
                  class="pm-PuzzleAlert-message pm-PuzzleAlert-message--connecting is-active"
                >
                  <h2>Connecting&hellip;</h2>
                  <p>
                    Puzzle piece movement updates are disabled while connecting.
                  </p>
                  ${getDetails()}
                </div>
              `;
              break;
            case AlertStatus.reconnecting:
              return html`
                <div
                  class="pm-PuzzleAlert-message pm-PuzzleAlert-message--reconnecting is-active"
                >
                  <h2>Reconnecting&hellip;</h2>
                  <p>
                    Puzzle piece movement updates are disabled while
                    reconnecting.
                  </p>
                  ${getDetails()}
                </div>
              `;
              break;
            case AlertStatus.disconnected:
              return html`
                <div
                  class="pm-PuzzleAlert-message pm-PuzzleAlert-message--disconnected is-active"
                >
                  <h2>Disconnected</h2>
                  <p>
                    Puzzle piece movement updates are disabled. Try reloading
                    the page.
                  </p>
                  ${getDetails()}
                </div>
              `;
              break;
            case AlertStatus.blocked:
              return html`
                <div
                  class="pm-PuzzleAlert-message pm-PuzzleAlert-message--blocked is-active"
                >
                  <h2>Piece movement blocked</h2>
                  ${getDetails()}
                </div>
              `;
              break;
            case AlertStatus.completed:
              return html`
                <div
                  class="pm-PuzzleAlert-message pm-PuzzleAlert-message--statusCompleted is-active"
                >
                  <h2>Puzzle Completed</h2>
                  ${getDetails()}
                </div>
              `;
              break;
            case AlertStatus.frozen:
              return html`
                <div
                  class="pm-PuzzleAlert-message pm-PuzzleAlert-message--statusFrozen is-active"
                >
                  <h2>Puzzle Frozen</h2>
                  ${getDetails()}
                </div>
              `;
              break;
            case AlertStatus.in_queue:
              return html`
                <div
                  class="pm-PuzzleAlert-message pm-PuzzleAlert-message--statusInQueue is-active"
                >
                  <h2>Puzzle In Queue</h2>
                  ${getDetails()}
                </div>
              `;
              break;
            case AlertStatus.invalid:
              return html`
                <div
                  class="pm-PuzzleAlert-message pm-PuzzleAlert-message--invalid is-active"
                >
                  <h2>Invalid</h2>
                  <p>
                    Connection to puzzle piece updates is invalid.
                  </p>
                  ${getDetails()}
                </div>
              `;
              break;
            default:
              return "";
          }
          function getDetails() {
            return html`
              ${data.message
                ? html`
                    <p>
                      ${data.message}
                    </p>
                  `
                : ""}
              ${data.reason
                ? html`
                    <p>
                      ${data.reason}
                    </p>
                  `
                : ""}
            `;
          }
        }
      }
    }
    get data(): TemplateData {
      return {
        status: this.status,
        latency: this.latency,
        message: this.message,
        reason: this.reason,
      };
    }

    render() {
      render(this.template(this.data), this);
    }

    onMoveBlocked(data) {
      this.status = AlertStatus.blocked;
      if (data.msg) {
        this.message = data.msg;
      } else {
        this.message = BLOCKED_MSG_NOT_SPECIFIED;
      }

      this.reason = data.reason;
      if (data.expires && typeof data.expires === "number") {
        const expireDate = new Date(data.expires * 1000);
        this.reason =
          this.reason + ` Expires: ${expireDate.toLocaleTimeString()}`;
      }

      if (data.timeout && typeof data.timeout === "number") {
        const now = new Date().getTime();
        const remainingTime = Math.max(0, this.blockedTimer - now);
        const timeout = data.timeout * 1000 + remainingTime;
        window.clearTimeout(this.blockedTimeout);
        this.blockedTimer = now + timeout;
        this.blockedTimeout = window.setTimeout(() => {
          //this.alerts.container.classList.remove("is-active");
          //this.alerts.blocked.classList.remove("is-active");
        }, timeout);
      }

      //this.puzzleAlertService.send("PIECE_MOVE_BLOCKED");
      console.log(data);
      // TODO: Wire up blocked message.
      /*
      const msgEl = this.alerts.blocked.querySelector(
        "#puzzle-pieces-alert-blocked-msg"
      );
      const reasonEl = this.alerts.blocked.querySelector(
        "#puzzle-pieces-alert-blocked-reason"
      );
      if (!msgEl) {
        throw new Error(
          `Missing child element '#puzzle-pieces-alert-blocked-msg' needed for ${tag}`
        );
      }
      if (!reasonEl) {
        throw new Error(
          `Missing child element '#puzzle-pieces-alert-blocked-reason' needed for ${tag}`
        );
      }

      if (data.msg) {
        msgEl.innerHTML = data.msg;
      } else {
        msgEl.innerHTML = BLOCKED_MSG_NOT_SPECIFIED;
      }
      if (data.reason) {
        reasonEl.innerHTML = data.reason;
      } else {
        reasonEl.innerHTML = "";
      }
      if (data.expires && typeof data.expires === "number") {
        const expireDate = new Date(data.expires * 1000);
        reasonEl.innerHTML =
          reasonEl.innerHTML + ` Expires: ${expireDate.toLocaleTimeString()}`;
      }

      if (data.timeout && typeof data.timeout === "number") {
        const now = new Date().getTime();
        const remainingTime = Math.max(0, this.blockedTimer - now);
        const timeout = data.timeout * 1000 + remainingTime;
        window.clearTimeout(this.blockedTimeout);
        this.blockedTimer = now + timeout;
        this.blockedTimeout = window.setTimeout(() => {
          this.alerts.container.classList.remove("is-active");
          this.alerts.blocked.classList.remove("is-active");
        }, timeout);
      }
       */
      this.render();
    }

    onDisconnected() {
      this.message = "";
      this.puzzleAlertService.send("DISCONNECTED");
    }

    onReconnecting(data) {
      this.message = `Reconnect attempt: ${data}`;
      this.puzzleAlertService.send("RECONNECTING");
    }

    onConnected() {
      this.message = "";
      this.puzzleAlertService.send("SUCCESS");
    }

    onPuzzleStatus(status: Status) {
      console.log("onPuzzleStatus");
      switch (status) {
        case Status.COMPLETED:
          this.puzzleAlertService.send("PUZZLE_COMPLETED");
          break;
        case Status.IN_QUEUE:
          this.puzzleAlertService.send("PUZZLE_IN_QUEUE");
          break;
        case Status.FROZEN:
          this.puzzleAlertService.send("PUZZLE_FROZEN");
          break;
        default:
          this.puzzleAlertService.send("PUZZLE_INVALID");
          break;
      }
    }
    onPuzzlePing(latency: number) {
      this.latency = latency;
      this.puzzleAlertService.send("LATENCY_UPDATED");
    }

    disconnectedCallback() {
      const topics = [
        //"socket/max",
        "socket/disconnected",
        "socket/connected",
        "socket/reconnecting",
        "puzzle/status",
        "puzzle/ping",
      ];
      topics.forEach((topic) => {
        streamService.unsubscribe(topic, this.instanceId);
      });
      puzzleService.unsubscribe("piece/move/blocked", this.instanceId);
    }
  }
);

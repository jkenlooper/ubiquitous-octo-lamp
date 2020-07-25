#!/usr/bin/env node

/* srctdd.js
 * Watches the src directory for any changes and then runs the test.
 */

import child_process from "child_process";

// watchpack is used in webpack as well.
import Watchpack from "watchpack";

const wp = new Watchpack({
  aggregateTimeout: 300,

  poll: undefined,
  // poll: true - use polling with the default interval
  // poll: 10000 - use polling with an interval of 10s
  // poll defaults to undefined, which prefer native watching methods
  // Note: enable polling when watching on a network path
});

wp.watch([], ["src"], Date.now() - 10000);

wp.on("aggregated", () => {
  try {
    child_process.execSync(
      "npm run mocha -- --recursive 'src/**/*.spec.{js,mjs}'",
      {
        cwd: "./",
        stdio: [0, 1, 2],
      }
    );
  } catch (error) {
    // Continue watching if the unit test failed.
    if (error instanceof Error) {
      if (error.status !== 1) {
        throw error;
      }
    } else {
      throw error;
    }
  }
});

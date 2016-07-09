/* eslint-disable no-console, global-require */

import path from 'path';
import hypernova from 'hypernova/server';

const nodeEnv = process.env.NODE_ENV;
console.log(`-- Start hypernova-server (${nodeEnv})`);

const basePath = '../app/frontend/javascripts/';
const componentPaths = [
  'SeriesDetail',
].reduce(
  (ret, name) => Object.assign(ret, { [name]: path.resolve(basePath, name) }),
  {}
);

hypernova({
  devMode: true, // node_env !== 'production', // production mode fail?

  getComponent(name) {
    if (componentPaths[name] !== undefined) {
      return require(componentPaths[name]);
    }
    return null;
  },

  port: 3030,
});

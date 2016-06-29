import hypernova from 'hypernova/server';
import counterApp from '../app/frontend/javascripts/CounterApp';

const node_env = process.env.NODE_ENV;
console.log(`-- Start hypernova-server (${node_env})`);

hypernova({
  devMode: true,// node_env !== 'production', // production mode fail?

  getComponent(name) {
    if(name === 'CounterApp') {
      return counterApp;
    } else {
      return null;
    }
  },

  port: 3030
});

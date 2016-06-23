const hypernova = require('hypernova/server');

const node_env = process.env.NODE_ENV;
console.log(`-- Start hypernova-server (${node_env})`);

hypernova({
    devMode: true,// node_env !== 'production', // production mode fail?

    getComponent(name) {
        if(name === 'MyComponent.js') {
            return require('../app/assets/javascripts/MyComponent.js');
        }
        return null;
    },

    port: 3030
});

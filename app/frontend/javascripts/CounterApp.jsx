import React from 'react';
import { renderReactRedux } from 'hypernova-react-redux';

import CounterApp from './Containers/CounterApp';
import DevTools from './Components/DevTools';
import configureStore from './Store/Counter/ConfigureStore';

export default renderReactRedux(
  'CounterApp',
  <div>
    <CounterApp />
    <DevTools />
  </div>,
  configureStore
);

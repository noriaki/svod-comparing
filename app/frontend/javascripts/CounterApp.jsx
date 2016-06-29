import { renderReactRedux } from './hypernova-redux';

import CounterApp from './Containers/CounterApp';
import configureStore from './Store/Counter/ConfigureStore';

export default renderReactRedux('CounterApp', CounterApp, configureStore);

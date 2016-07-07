import counterReducer from '../../Reducers/Counter';
import DevTools from '../../Components/DevTools';
import { createStore } from 'redux';

export default function configureStore(preloadedState) {
  return createStore(
    counterReducer,
    Object.assign({}, counterReducer(undefined, {}), preloadedState),
    DevTools.instrument()
  );
}

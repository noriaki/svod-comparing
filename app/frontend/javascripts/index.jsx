import React from 'react';
import { createStore } from 'redux';
import { connect } from 'react-redux';
import { renderReactRedux } from 'hypernova-react-redux';

// Redux DevTools
import { createDevTools } from 'redux-devtools';
import LogMonitor from 'redux-devtools-log-monitor';
import DockMonitor from 'redux-devtools-dock-monitor';

const DevTools = createDevTools(
  <DockMonitor toggleVisibilityKey='ctrl-i'
               changePositionKey='ctrl-q'
               defaultIsVisible={true}>
    <LogMonitor theme='tomorrow' />
  </DockMonitor>
);

// Material-UI
import RaisedButton from 'material-ui/RaisedButton';
const raised_button_style = {
  'marginLeft': 10
};

// Component
class Counter extends React.Component {
  propTypes = {
    count:       React.PropTypes.number.isRequired,
    onIncrement: React.PropTypes.string.isRequired,
    onDecrement: React.PropTypes.string.isRequired
  }
  parseSize(text) {
    const label = text.trim();
    return parseInt(label.slice(1));
  }
  render() {
    const { count, onIncrement, onDecrement } = this.props;
    return(
      <div>
        カウント: {count}回
        <RaisedButton label="+10" primary={true} onClick={(e) => { onIncrement(this.parseSize(e.target.textContent)); }} style={raised_button_style} />
        <RaisedButton label="+1" primary={true} onClick={(e) => { onIncrement(this.parseSize(e.target.textContent)); }} style={raised_button_style} />
        <RaisedButton label="-1" onClick={(e) => { onDecrement(this.parseSize(e.target.textContent)); }} style={raised_button_style} />
        <RaisedButton label="-10" onClick={(e) => { onDecrement(this.parseSize(e.target.textContent)); }} style={raised_button_style} />
      </div>
    );
  }
}

// Actions
const action_increment_counter = function(size = 1) {
  return {
    type: 'INCREMENT_COUNTER',
    size
  };
};
const action_decrement_counter = function(size = 1) {
  return {
    type: 'DECREMENT_COUNTER',
    size
  };
};

// Reducer
function counterReducer(state = { count: 0 }, action) {
  switch(action.type) {
  case 'INCREMENT_COUNTER':
    return { count: state.count + action.size };
  case 'DECREMENT_COUNTER':
    return { count: state.count - action.size };
  default:
    return state;
  }
}

// Store
function configureStore(preloadState) {
  const initialState = counterReducer(undefined, {});
  return createStore(
    counterReducer,
    Object.assign({}, initialState, preloadState),
    DevTools.instrument()
  );
}
//const store = createStore(counterReducer, DevTools.instrument());

function mapStateToProps(state) {
  return { count: state.count };
}

function mapDispatchToProps(dispatch) {
  return {
    onIncrement(size) { return dispatch(action_increment_counter(size)); },
    onDecrement(size) { return dispatch(action_decrement_counter(size)); }
  };
}

const App = connect(
  mapStateToProps,
  mapDispatchToProps
)(Counter);

module.exports = renderReactRedux(
  'MyComponent',
  App,
  configureStore
);

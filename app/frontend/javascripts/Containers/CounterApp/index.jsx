import CounterComponent from '../../Components/Counter';
import { incrementCounter, decrementCounter } from '../../Actions/Counter';
import { connect } from 'react-redux';

function mapStateToProps(state) {
  return { count: state.count };
}

function mapDispatchToProps(dispatch) {
  return {
    onIncrement() { return dispatch(incrementCounter()); },
    onDecrement() { return dispatch(decrementCounter()); }
  };
}

export default connect(mapStateToProps, mapDispatchToProps)(CounterComponent);

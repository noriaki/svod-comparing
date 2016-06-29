import React, { PropTypes } from 'react';

function CounterComponent(props) {
  const { count, onIncrement, onDecrement } = props;
  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={onIncrement}>+1</button>
      <button onClick={onDecrement}>-1</button>
    </div>
  );
}

CounterComponent.propTypes = {
  count: PropTypes.number.isRequired,
  onIncrement: PropTypes.func.isRequired,
  onDecrement: PropTypes.func.isRequired
};

export default CounterComponent;

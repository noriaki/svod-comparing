import {
  INCREMENT_COUNTER, DECREMENT_COUNTER
} from '../../Constants/ActionTypes/Counter';

const initialState = {
  count: 0
};

export default function counterReducer(state = initialState, action) {
  switch (action.type) {
  case INCREMENT_COUNTER:
    return { count: state.count + 1 };
  case DECREMENT_COUNTER:
    return { count: state.count - 1 };
  default:
    return state;
  }
}

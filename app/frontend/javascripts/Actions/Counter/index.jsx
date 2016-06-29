import * as types from '../../Constants/ActionTypes/Counter';

export function incrementCounter() {
  return { type: types.INCREMENT_COUNTER };
}
export function decrementCounter() {
  return { type: types.DECREMENT_COUNTER };
}
